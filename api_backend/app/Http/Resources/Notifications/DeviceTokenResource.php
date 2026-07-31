<?php

namespace App\Http\Resources\Notifications;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeviceTokenResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'app' => $this->app,
            'platform' => $this->platform,
            'device_id' => $this->device_id,
            'device_name' => $this->device_name,
            'locale' => $this->locale,
            'timezone' => $this->timezone,
            'notifications_enabled' => $this->notifications_enabled,
            'is_active' => $this->is_active,
            'last_seen_at' => $this->last_seen_at?->toISOString(),
        ];
    }
}
