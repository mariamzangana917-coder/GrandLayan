<?php

namespace App\Http\Controllers\Api\Customer\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Customer\Auth\ChangeCustomerPasswordRequest;
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
                        'ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â§ÃƒËœÃ‚ÂªÃƒâ„¢Ã‚Â ÃƒËœÃ‚Â£Ãƒâ„¢Ã‹â€  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¥Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã†â€™ÃƒËœÃ‚ÂªÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Â Ãƒâ„¢Ã…Â  Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒËœÃ‚Â®ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Â¦ Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã¢â‚¬Â¹ÃƒËœÃ‚Â§.',
                    ],
                ]);
            }

            throw $exception;
        }

        /** @var User $customer */
        $customer = $result['customer'];

        return response()->json([
            'message' => 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚Â¥Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â´ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¡ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â­ÃƒËœÃ‚Â³ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­.',
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
                    'ÃƒËœÃ‚Â¨Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â§ÃƒËœÃ‚Âª ÃƒËœÃ‚ÂªÃƒËœÃ‚Â³ÃƒËœÃ‚Â¬Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â®Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚ÂºÃƒâ„¢Ã…Â ÃƒËœÃ‚Â± ÃƒËœÃ‚ÂµÃƒËœÃ‚Â­Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â­ÃƒËœÃ‚Â©.',
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
            'message' => 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚ÂªÃƒËœÃ‚Â³ÃƒËœÃ‚Â¬Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â®Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­.',
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
                'message' => 'Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â°ÃƒËœÃ‚Â§ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â­ÃƒËœÃ‚Â³ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ ÃƒËœÃ‚ÂºÃƒâ„¢Ã…Â ÃƒËœÃ‚Â± Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂµÃƒËœÃ‚Â±ÃƒËœÃ‚Â­ Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¡ ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â®Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾.',
            ], 403);
        }

        return response()->json([
            'data' => [
                'user' => $this->customerPayload($customer),
            ],
        ]);
    }

    /**
     * Change authenticated customer's password.
     */
    public function changePassword(
        ChangeCustomerPasswordRequest $request
    ): JsonResponse {
        /** @var User $customer */
        $customer = $request->user();

        if (! Hash::check(
            $request->input('current_password'),
            $customer->password
        )) {
            throw ValidationException::withMessages([
                'current_password' => [
                    'كلمة المرور الحالية غير صحيحة.',
                ],
            ]);
        }

        $customer->password = $request->input('password');
        $customer->save();

        return response()->json([
            'message' => 'تم تغيير كلمة المرور بنجاح.',
        ]);
    }

/**
     * Logout current device only.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚ÂªÃƒËœÃ‚Â³ÃƒËœÃ‚Â¬Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â®ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¬ ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­.',
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

