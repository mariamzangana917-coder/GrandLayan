<?php

namespace App\Http\Controllers\Api\Customer\Profile;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Customer\Profile\UpdateCustomerProfileRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CustomerProfileController extends Controller
{
    public function update(
        UpdateCustomerProfileRequest $request
    ): JsonResponse {
        /** @var User $customer */
        $customer = $request->user();

        if (
            ! $customer->is_active
            || ! $customer->hasRole('customer')
        ) {
            return response()->json([
                'message' => 'هذا الحساب غير مخول بالدخول.',
            ], 403);
        }

        $customer->update(
            $request->validated()
        );

        $customer->refresh();

        return response()->json([
            'message' => 'تم تحديث بيانات الحساب بنجاح.',
            'data' => [
                'user' => $this->customerData($customer),
            ],
        ]);
    }

    public function updateAvatar(
        Request $request
    ): JsonResponse {
        /** @var User $customer */
        $customer = $request->user();

        if (
            ! $customer->is_active
            || ! $customer->hasRole('customer')
        ) {
            return response()->json([
                'message' => 'هذا الحساب غير مخول بالدخول.',
            ], 403);
        }

        $validated = $request->validate([
            'avatar' => [
                'required',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:5120',
            ],
        ], [
            'avatar.required' => 'يرجى اختيار صورة.',
            'avatar.image' => 'الملف المختار يجب أن يكون صورة.',
            'avatar.mimes' => 'صيغة الصورة يجب أن تكون JPG أو PNG أو WEBP.',
            'avatar.max' => 'حجم الصورة يجب ألا يتجاوز 5 ميغابايت.',
        ]);

        $oldAvatar = $customer->avatar;

        $path = $validated['avatar']->store(
            'customers/avatars',
            'public'
        );

        $customer->update([
            'avatar' => $path,
        ]);

        if (
            $oldAvatar
            && Storage::disk('public')->exists($oldAvatar)
        ) {
            Storage::disk('public')->delete($oldAvatar);
        }

        $customer->refresh();

        return response()->json([
            'message' => 'تم تحديث صورة الحساب بنجاح.',
            'data' => [
                'user' => $this->customerData($customer),
            ],
        ]);
    }

    public function destroyAvatar(
        Request $request
    ): JsonResponse {
        /** @var User $customer */
        $customer = $request->user();

        if (
            ! $customer->is_active
            || ! $customer->hasRole('customer')
        ) {
            return response()->json([
                'message' => 'هذا الحساب غير مخول بالدخول.',
            ], 403);
        }

        $oldAvatar = $customer->avatar;

        $customer->update([
            'avatar' => null,
        ]);

        if (
            $oldAvatar
            && Storage::disk('public')->exists($oldAvatar)
        ) {
            Storage::disk('public')->delete($oldAvatar);
        }

        $customer->refresh();

        return response()->json([
            'message' => 'تم حذف صورة الحساب بنجاح.',
            'data' => [
                'user' => $this->customerData($customer),
            ],
        ]);
    }

    private function customerData(User $customer): array
    {
        return [
            'id' => $customer->id,
            'name' => $customer->name,
            'email' => $customer->email,
            'phone' => $customer->phone,
            'avatar' => $customer->avatar
                ? asset('storage/'.$customer->avatar)
                : null,
            'role' => 'customer',
        ];
    }
}
