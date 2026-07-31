<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationPreference extends Model
{
    protected $fillable = [
        'user_id',
        'push_enabled',
        'appointment_updates',
        'appointment_reminders',
        'chat_messages',
        'offers',
        'gift_cards',
        'payments',
        'reviews',
    ];

    protected function casts(): array
    {
        return [
            'push_enabled' => 'boolean',
            'appointment_updates' => 'boolean',
            'appointment_reminders' => 'boolean',
            'chat_messages' => 'boolean',
            'offers' => 'boolean',
            'gift_cards' => 'boolean',
            'payments' => 'boolean',
            'reviews' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
