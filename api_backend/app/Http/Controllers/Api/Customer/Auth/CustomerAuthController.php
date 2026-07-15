<?php

namespace App\Http\Controllers\Api\Customer\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Customer\Auth\CustomerLoginRequest;
use App\Http\Requests\Api\Customer\Auth\CustomerRegisterRequest;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class CustomerAuthController extends Controller
{
    /**
     * Register a new customer.
     *
     * @throws ValidationException
     */
    public function register(
        CustomerRegisterRequest $request
    ): JsonResponse {
        $validated = $request->validated();

        try {
            $result = DB::transaction(function () use ($validated): array {
                $customer = User::query()->create([
                    'name' => $validated['name'],
                    'phone' => $validated['phone'],
                    'email' => $validated['email'],
                    'password' => $validated['password'],
                    'is_active' => true,
                ]);

                $customer->assignRole('customer');

                $token = $customer
                    ->createToken(
                        $validated['device_name'],
                        ['customer']
                    )
                    ->plainTextToken;

                return [
                    'customer' => $customer,
                    'token' => $token,
                ];
            });
        } catch (QueryException $exception) {
            if (
                in_array(
                    (string) $exception->getCode(),
                    ['23000', '23505'],
                    true
                )
            ) {
                throw ValidationException::withMessages([
                    'phone' => [
                        'رقم الهاتف أو البريد الإلكتروني مستخدم مسبقًا.',
                    ],
                ]);
            }

            throw $exception;
        }

        /** @var User $customer */
        $customer = $result['customer'];

        return response()->json([
            'message' => 'تم إنشاء الحساب بنجاح.',
            'data' => [
                'user' => $this->customerPayload($customer),
                'token' => $result['token'],
                'token_type' => 'Bearer',
            ],
        ], 201);
    }

    /**
     * Customer login.
     *
     * @throws ValidationException
     */
    public function login(
        CustomerLoginRequest $request
    ): JsonResponse {
        $credentials = $request->validated();

        $login = trim($credentials['login']);

        $customer = User::query()
            ->where(function ($query) use ($login): void {
                $query
                    ->where('email', $login)
                    ->orWhere('phone', $login);
            })
            ->first();

        if (
            ! $customer
            || ! Hash::check(
                $credentials['password'],
                $customer->password
            )
            || ! $customer->is_active
            || ! $customer->hasRole('customer')
        ) {
            throw ValidationException::withMessages([
                'login' => [
                    'بيانات تسجيل الدخول غير صحيحة.',
                ],
            ]);
        }

        $token = $customer
            ->createToken(
                $credentials['device_name'],
                ['customer']
            )
            ->plainTextToken;

        return response()->json([
            'message' => 'تم تسجيل الدخول بنجاح.',
            'data' => [
                'user' => $this->customerPayload($customer),
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    /**
     * Return authenticated customer.
     */
    public function me(Request $request): JsonResponse
    {
        /** @var User|null $customer */
        $customer = $request->user();

        if (
            ! $customer
            || ! $customer->is_active
            || ! $customer->hasRole('customer')
        ) {
            $customer?->currentAccessToken()?->delete();

            return response()->json([
                'message' => 'هذا الحساب غير مصرح له بالدخول.',
            ], 403);
        }

        return response()->json([
            'data' => [
                'user' => $this->customerPayload($customer),
            ],
        ]);
    }

    /**
     * Logout current device only.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'تم تسجيل الخروج بنجاح.',
        ]);
    }

    /**
     * Build customer response payload.
     *
     * @return array{
     *     id:int,
     *     name:string,
     *     email:string,
     *     phone:string,
     *     avatar:?string,
     *     role:string
     * }
     */
    private function customerPayload(User $customer): array
    {
        return [
            'id' => $customer->id,
            'name' => $customer->name,
            'email' => $customer->email,
            'phone' => $customer->phone,
            'avatar' => $customer->avatar,
            'role' => 'customer',
        ];
    }
}