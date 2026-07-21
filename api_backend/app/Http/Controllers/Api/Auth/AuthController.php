<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\LoginRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Log the manager in and create a separate token for this device.
     *
     * @throws ValidationException
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $credentials = $request->validated();
        $login = trim($credentials['login']);

        $user = User::query()
            ->where(function ($query) use ($login): void {
                $query
                    ->where('email', $login)
                    ->orWhere('phone', $login);
            })
            ->first();

        /*
         * Use one generic error message to avoid revealing:
         * - whether the account exists;
         * - whether it is inactive;
         * - whether it belongs to a manager.
         */
        if (
            ! $user
            || ! Hash::check($credentials['password'], $user->password)
            || ! $user->is_active
            || ! $user->hasRole('manager')
        ) {
            throw ValidationException::withMessages([
                'login' => ['بيانات تسجيل الدخول غير صحيحة.'],
            ]);
        }

        $token = $user
            ->createToken(
                $credentials['device_name'],
                ['admin']
            )
            ->plainTextToken;

        return response()->json([
            'message' => 'تم تسجيل الدخول بنجاح.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'avatar' => $user->avatar,
                    'role' => 'manager',
                ],
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    /**
     * Return the currently authenticated manager.
     */
    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return response()->json([
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'avatar' => $user->avatar,
                    'role' => 'manager',
                ],
            ],
        ]);
    }

    /**
     * Delete only the token used by the current device.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'تم تسجيل الخروج بنجاح.',
        ]);
    }
}
