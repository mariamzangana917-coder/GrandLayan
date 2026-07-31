<?php

namespace App\Http\Controllers\Api\Notifications;

use App\Http\Controllers\Controller;
use App\Http\Requests\Notifications\StoreDeviceTokenRequest;
use App\Http\Resources\Notifications\DeviceTokenResource;
use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Date;

class DeviceTokenController extends Controller
{
    public function store(StoreDeviceTokenRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();
        $app = $user->hasRole('manager') ? 'admin' : 'customer';

        $deviceToken = DeviceToken::query()->updateOrCreate(
            [
                'token' => $validated['token'],
            ],
            [
                'user_id' => $user->id,
                'app' => $app,
                'platform' => $validated['platform'],
                'device_id' => $validated['device_id'] ?? null,
                'device_name' => $validated['device_name'] ?? null,
                'locale' => $validated['locale'] ?? 'ar',
                'timezone' => $validated['timezone'] ?? null,
                'notifications_enabled' => (bool) (
                    $validated['notifications_enabled'] ?? true
                ),
                'is_active' => true,
                'last_seen_at' => Date::now(),
            ],
        );

        return (new DeviceTokenResource($deviceToken))
            ->response()
            ->setStatusCode($deviceToken->wasRecentlyCreated ? 201 : 200);
    }

    public function destroy(
        Request $request,
        DeviceToken $deviceToken,
    ): Response {
        abort_unless(
            (int) $deviceToken->user_id === (int) $request->user()->id,
            404,
        );

        $deviceToken->forceFill([
            'is_active' => false,
            'notifications_enabled' => false,
            'last_seen_at' => Date::now(),
        ])->save();

        return response()->noContent();
    }
}
