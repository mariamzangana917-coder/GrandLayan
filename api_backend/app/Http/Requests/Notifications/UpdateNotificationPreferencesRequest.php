<?php

namespace App\Http\Requests\Notifications;

use Illuminate\Foundation\Http\FormRequest;

class UpdateNotificationPreferencesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'push_enabled' => ['sometimes', 'boolean'],
            'appointment_updates' => ['sometimes', 'boolean'],
            'appointment_reminders' => ['sometimes', 'boolean'],
            'chat_messages' => ['sometimes', 'boolean'],
            'offers' => ['sometimes', 'boolean'],
            'gift_cards' => ['sometimes', 'boolean'],
            'payments' => ['sometimes', 'boolean'],
            'reviews' => ['sometimes', 'boolean'],
        ];
    }
}
