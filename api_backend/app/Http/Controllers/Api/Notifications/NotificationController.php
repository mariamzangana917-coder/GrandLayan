<?php

namespace App\Http\Controllers\Api\Notifications;

use App\Http\Controllers\Controller;
use App\Http\Resources\Notifications\AppNotificationResource;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Date;

class NotificationController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'unread_only' => ['sometimes', 'boolean'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:50'],
        ]);

        $notifications = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->when(
                (bool) ($validated['unread_only'] ?? false),
                fn ($query) => $query->whereNull('read_at'),
            )
            ->latest('created_at')
            ->paginate((int) ($validated['per_page'] ?? 20));

        return AppNotificationResource::collection($notifications);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $count = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'data' => [
                'unread_count' => $count,
            ],
        ]);
    }

    public function markRead(
        Request $request,
        AppNotification $notification,
    ): JsonResponse {
        abort_unless(
            (int) $notification->user_id === (int) $request->user()->id,
            404,
        );

        if ($notification->read_at === null) {
            $notification->forceFill([
                'read_at' => Date::now(),
            ])->save();
        }

        return response()->json([
            'data' => (new AppNotificationResource(
                $notification->refresh()
            ))->resolve($request),
        ]);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        $updated = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update([
                'read_at' => Date::now(),
                'updated_at' => Date::now(),
            ]);

        return response()->json([
            'data' => [
                'updated_count' => $updated,
            ],
        ]);
    }
}