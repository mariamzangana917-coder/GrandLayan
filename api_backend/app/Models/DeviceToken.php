<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeviceToken extends Model
{
    protected $fillable = [
        'user_id',
        'app',
        'platform',
        'token',
        'device_id',
        'device_name',
        'locale',
        'timezone',
        'notifications_enabled',
        'is_active',
        'last_seen_at',
    ];

    protected function casts(): array
    {
        return [
            'notifications_enabled' => 'boolean',
            'is_active' => 'boolean',
            'last_seen_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
