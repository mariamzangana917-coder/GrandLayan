<?php

namespace App\Http\Resources\Notifications;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationPreferenceResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'push_enabled' => $this->push_enabled,
            'appointment_updates' => $this->appointment_updates,
            'appointment_reminders' => $this->appointment_reminders,
            'chat_messages' => $this->chat_messages,
            'offers' => $this->offers,
            'gift_cards' => $this->gift_cards,
            'payments' => $this->payments,
            'reviews' => $this->reviews,
            'security_notifications_always_enabled' => true,
        ];
    }
}
