<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Admin\UpdateManagerProfileRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Throwable;

class ManagerProfileController extends Controller
{
    public function update(
        UpdateManagerProfileRequest $request
    ): JsonResponse {
        /** @var User $manager */
        $manager = $request->user();

        // Only these three fields may be changed from this endpoint.
        // Role, activation state, and password are intentionally excluded.
        $manager->update($request->validated());
        $manager->refresh();

        return $this->profileResponse(
            manager: $manager,
            message: 'تم تحديث بيانات حساب المديرة بنجاح.'
        );
    }

    public function updateAvatar(Request $request): JsonResponse
    {
        $manager = $this->authorizedManager($request);

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

        $oldAvatar = $manager->avatar;

        $newAvatar = $validated['avatar']->store(
            'managers/avatars',
            'public'
        );

        try {
            $manager->update([
                'avatar' => $newAvatar,
            ]);
        } catch (Throwable $exception) {
            // Prevent an orphaned uploaded file when the database update fails.
            Storage::disk('public')->delete($newAvatar);

            throw $exception;
        }

        if (
            $oldAvatar !== null
            && $oldAvatar !== $newAvatar
            && Storage::disk('public')->exists($oldAvatar)
        ) {
            Storage::disk('public')->delete($oldAvatar);
        }

        $manager->refresh();

        return $this->profileResponse(
            manager: $manager,
            message: 'تم تحديث صورة حساب المديرة بنجاح.'
        );
    }

    public function destroyAvatar(Request $request): JsonResponse
    {
        $manager = $this->authorizedManager($request);
        $oldAvatar = $manager->avatar;

        if ($oldAvatar !== null) {
            $manager->update([
                'avatar' => null,
            ]);

            if (Storage::disk('public')->exists($oldAvatar)) {
                Storage::disk('public')->delete($oldAvatar);
            }
        }

        $manager->refresh();

        return $this->profileResponse(
            manager: $manager,
            message: 'تم حذف صورة حساب المديرة بنجاح.'
        );
    }

    private function authorizedManager(Request $request): User
    {
        $manager = $request->user();

        abort_unless(
            $manager instanceof User
                && (bool) $manager->is_active
                && $manager->hasRole('manager'),
            403,
            'هذا الحساب غير مخول بإدارة بيانات المديرة.'
        );

        return $manager;
    }

    private function profileResponse(
        User $manager,
        string $message
    ): JsonResponse {
        return response()->json([
            'message' => $message,
            'data' => [
                'user' => $this->managerData($manager),
            ],
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function managerData(User $manager): array
    {
        return [
            'id' => $manager->id,
            'name' => $manager->name,
            'email' => $manager->email,
            'phone' => $manager->phone,
            'avatar' => $manager->avatar
                ? asset('storage/'.$manager->avatar)
                : null,
            'role' => 'manager',
        ];
    }
}
