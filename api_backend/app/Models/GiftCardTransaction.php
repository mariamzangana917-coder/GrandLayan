<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GiftCardTransaction extends Model
{
    use HasFactory;

    public const TYPE_ISSUANCE = 'issuance';

    public const TYPE_REDEMPTION = 'redemption';

    public const TYPE_REFUND = 'refund';

    public const TYPE_ADJUSTMENT_CREDIT = 'adjustment_credit';

    public const TYPE_ADJUSTMENT_DEBIT = 'adjustment_debit';

    public const TYPE_CANCELLATION = 'cancellation';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'gift_card_id',
        'appointment_id',
        'performed_by_user_id',
        'type',
        'amount',
        'balance_before',
        'balance_after',
        'notes',
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
            'balance_before' => 'decimal:2',
            'balance_after' => 'decimal:2',
        ];
    }

    /**
     * Gift Card affected by this transaction.
     */
    public function giftCard(): BelongsTo
    {
        return $this->belongsTo(GiftCard::class);
    }

    /**
     * Appointment associated with redemption or refund.
     */
    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }

    /**
     * User who manually performed the transaction.
     *
     * This may be null for automatic system transactions.
     */
    public function performedBy(): BelongsTo
    {
        return $this->belongsTo(
            User::class,
            'performed_by_user_id'
        );
    }

    /**
     * Transactions that increase the Gift Card balance.
     */
    public function scopeCredits(Builder $query): Builder
    {
        return $query->whereIn('type', [
            self::TYPE_ISSUANCE,
            self::TYPE_REFUND,
            self::TYPE_ADJUSTMENT_CREDIT,
        ]);
    }

    /**
     * Transactions that decrease the Gift Card balance.
     */
    public function scopeDebits(Builder $query): Builder
    {
        return $query->whereIn('type', [
            self::TYPE_REDEMPTION,
            self::TYPE_ADJUSTMENT_DEBIT,
            self::TYPE_CANCELLATION,
        ]);
    }
}
