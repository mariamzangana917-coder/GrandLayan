<?php

namespace App\Services\Notifications;

use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class CreateAppNotificationService
{
    /**
     * @param  array<string, mixed>  $data
     */
    public function create(
        User $user,
        string $type,
        string $title,
        string $body,
        array $data = [],
        ?string $deduplicationKey = null,
    ): AppNotification {
        return DB::transaction(function () use (
            $user,
            $type,
            $title,
            $body,
            $data,
            $deduplicationKey,
        ): AppNotification {
            $attributes = [
                'user_id' => $user->id,
                'type' => trim($type),
                'title' => trim($title),
                'body' => trim($body),
                'data' => $data,
                'deduplication_key' => $deduplicationKey,
            ];

            if ($deduplicationKey === null || trim($deduplicationKey) === '') {
                return AppNotification::query()->create($attributes);
            }

            return AppNotification::query()->firstOrCreate(
                [
                    'user_id' => $user->id,
                    'deduplication_key' => trim($deduplicationKey),
                ],
                $attributes,
            );
        });
    }
}
