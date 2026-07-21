<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class GiftCardOrder extends Model
{
    use HasFactory;

    public const PAYMENT_METHOD_CASH = 'cash';

    public const PAYMENT_METHOD_ELECTRONIC = 'electronic';

    public const PAYMENT_STATUS_PENDING = 'pending';

    public const PAYMENT_STATUS_PAID = 'paid';

    public const PAYMENT_STATUS_FAILED = 'failed';

    public const PAYMENT_STATUS_REFUNDED = 'refunded';

    public const STATUS_PENDING = 'pending';

    public const STATUS_COMPLETED = 'completed';

    public const STATUS_CANCELLED = 'cancelled';

    public const STATUS_REFUNDED = 'refunded';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'customer_id',
        'gift_card_design_id',
        'recipient_name',
        'recipient_phone',
        'gift_message',
        'amount',
        'payment_method',
        'payment_status',
        'payment_reference',
        'status',
        'paid_at',
        'completed_at',
        'cancelled_at',
        'refunded_at',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'paid_at' => 'immutable_datetime',
            'completed_at' => 'immutable_datetime',
            'cancelled_at' => 'immutable_datetime',
            'refunded_at' => 'immutable_datetime',
        ];
    }

    /**
     * Customer who purchased the Gift Card.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Design selected when the order was created.
     */
    public function design(): BelongsTo
    {
        return $this->belongsTo(
            GiftCardDesign::class,
            'gift_card_design_id'
        );
    }

    /**
     * Gift Card issued from this order.
     */
    public function giftCard(): HasOne
    {
        return $this->hasOne(GiftCard::class);
    }

    /**
     * Orders waiting for payment or completion.
     */
    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Successfully completed orders.
     */
    public function scopeCompleted(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_COMPLETED);
    }

    /**
     * Paid orders.
     */
    public function scopePaid(Builder $query): Builder
    {
        return $query->where(
            'payment_status',
            self::PAYMENT_STATUS_PAID
        );
    }

    /**
     * Determine whether the order has been paid.
     */
    public function isPaid(): bool
    {
        return $this->payment_status === self::PAYMENT_STATUS_PAID;
    }

    /**
     * Determine whether a Gift Card has been issued.
     */
    public function hasIssuedGiftCard(): bool
    {
        return $this->giftCard()->exists();
    }
}
