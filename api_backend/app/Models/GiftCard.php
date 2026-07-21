<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GiftCard extends Model
{
    use HasFactory;

    public const STATUS_ACTIVE = 'active';

    public const STATUS_FULLY_REDEEMED = 'fully_redeemed';

    public const STATUS_EXPIRED = 'expired';

    public const STATUS_CANCELLED = 'cancelled';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'gift_card_order_id',
        'code',
        'qr_token',
        'initial_balance',
        'remaining_balance',
        'status',
        'issued_at',
        'expires_at',
        'fully_redeemed_at',
        'cancelled_at',
    ];

    /**
     * Hide sensitive verification data from accidental serialization.
     *
     * QR token should only be returned deliberately through an API Resource.
     *
     * @var list<string>
     */
    protected $hidden = [
        'qr_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'initial_balance' => 'decimal:2',
            'remaining_balance' => 'decimal:2',
            'issued_at' => 'immutable_datetime',
            'expires_at' => 'immutable_datetime',
            'fully_redeemed_at' => 'immutable_datetime',
            'cancelled_at' => 'immutable_datetime',
        ];
    }

    /**
     * Order that issued this Gift Card.
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(
            GiftCardOrder::class,
            'gift_card_order_id'
        );
    }

    /**
     * Complete immutable financial history of the Gift Card.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(GiftCardTransaction::class)
            ->orderBy('id');
    }

    /**
     * Gift Cards currently marked as active.
     */
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_ACTIVE);
    }

    /**
     * Gift Cards that still have balance.
     */
    public function scopeWithRemainingBalance(Builder $query): Builder
    {
        return $query->where('remaining_balance', '>', 0);
    }

    /**
     * Gift Cards that have not reached their expiry time.
     */
    public function scopeNotExpired(Builder $query): Builder
    {
        return $query->where('expires_at', '>', now());
    }

    /**
     * Gift Cards currently usable for payment.
     */
    public function scopeUsable(Builder $query): Builder
    {
        return $query
            ->active()
            ->withRemainingBalance()
            ->notExpired();
    }

    /**
     * Determine whether this Gift Card has expired by date.
     */
    public function hasExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * Determine whether this Gift Card can currently be redeemed.
     */
    public function isUsable(): bool
    {
        return $this->status === self::STATUS_ACTIVE
            && ! $this->hasExpired()
            && (float) $this->remaining_balance > 0;
    }

    /**
     * Determine whether the Gift Card can cover a specified amount.
     */
    public function hasSufficientBalance(float|string $amount): bool
    {
        return (float) $this->remaining_balance >= (float) $amount;
    }
}
