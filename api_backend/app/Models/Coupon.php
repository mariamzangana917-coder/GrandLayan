<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Coupon extends Model
{
    use HasFactory;

    public const TYPE_PERCENTAGE = 'percentage';

    public const TYPE_FIXED = 'fixed';

    protected $fillable = [
        'name',
        'code',
        'discount_type',
        'discount_value',
        'minimum_order_amount',
        'maximum_discount_amount',
        'department_id',
        'maximum_total_uses',
        'maximum_uses_per_customer',
        'used_count',
        'starts_at',
        'expires_at',
        'is_active',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'discount_value' => 'decimal:2',
            'minimum_order_amount' => 'decimal:2',
            'maximum_discount_amount' => 'decimal:2',
            'maximum_total_uses' => 'integer',
            'maximum_uses_per_customer' => 'integer',
            'used_count' => 'integer',
            'starts_at' => 'datetime',
            'expires_at' => 'datetime',
            'is_active' => 'boolean',
        ];
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function catalogItems(): BelongsToMany
    {
        return $this->belongsToMany(
            CatalogItem::class,
            'coupon_catalog_item'
        )->withTimestamps();
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(
            CouponRedemption::class
        );
    }

    public function isPercentage(): bool
    {
        return $this->discount_type
            === self::TYPE_PERCENTAGE;
    }

    public function isFixed(): bool
    {
        return $this->discount_type
            === self::TYPE_FIXED;
    }

    public function isCurrentlyAvailable(): bool
    {
        if (! $this->is_active) {
            return false;
        }

        if (
            $this->starts_at !== null
            && now()->lt($this->starts_at)
        ) {
            return false;
        }

        if (
            $this->expires_at !== null
            && now()->gt($this->expires_at)
        ) {
            return false;
        }

        if (
            $this->maximum_total_uses !== null
            && $this->used_count
                >= $this->maximum_total_uses
        ) {
            return false;
        }

        return true;
    }
}
