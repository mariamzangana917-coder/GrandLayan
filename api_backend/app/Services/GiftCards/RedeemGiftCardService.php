<?php

namespace App\Services\GiftCards;

use App\Models\Appointment;
use App\Models\GiftCard;
use App\Models\GiftCardTransaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Throwable;

class RedeemGiftCardService
{
    /**
     * Redeem an exact amount from one Gift Card for one appointment.
     *
     * Partial redemption is not allowed when the card balance is less
     * than the requested amount.
     *
     * @throws Throwable
     */
    public function execute(
        string $identifier,
        Appointment|int $appointment,
        int|float|string $amount,
        User|int|null $performedBy = null,
        ?string $notes = null
    ): GiftCardTransaction {
        $appointmentId = $appointment instanceof Appointment
            ? $appointment->getKey()
            : $appointment;

        $performedByUserId = $performedBy instanceof User
            ? $performedBy->getKey()
            : $performedBy;

        $normalizedIdentifier = trim($identifier);
        $normalizedAmount = $this->normalizeAmount($amount);

        return DB::transaction(
            function () use (
                $normalizedIdentifier,
                $appointmentId,
                $normalizedAmount,
                $performedByUserId,
                $notes
            ): GiftCardTransaction {
                $giftCard = GiftCard::query()
                    ->where(function ($query) use ($normalizedIdentifier): void {
                        $query
                            ->where('code', strtoupper($normalizedIdentifier))
                            ->orWhere('qr_token', $normalizedIdentifier);
                    })
                    ->lockForUpdate()
                    ->first();

                if ($giftCard === null) {
                    throw ValidationException::withMessages([
                        'gift_card' => [
                            'بطاقة الهدية غير موجودة أو أن الكود غير صحيح.',
                        ],
                    ]);
                }

                $appointmentExists = Appointment::query()
                    ->whereKey($appointmentId)
                    ->exists();

                if (! $appointmentExists) {
                    throw ValidationException::withMessages([
                        'appointment_id' => [
                            'الحجز المحدد غير موجود.',
                        ],
                    ]);
                }

                $this->ensureCardCanBeRedeemed(
                    $giftCard,
                    $normalizedAmount
                );

                $balanceBefore = $this->normalizeAmount(
                    $giftCard->remaining_balance
                );

                $balanceAfter = $this->subtractAmounts(
                    $balanceBefore,
                    $normalizedAmount
                );

                $isFullyRedeemed = $this->amountEquals(
                    $balanceAfter,
                    '0.00'
                );

                $giftCard->forceFill([
                    'remaining_balance' => $balanceAfter,
                    'status' => $isFullyRedeemed
                        ? GiftCard::STATUS_FULLY_REDEEMED
                        : GiftCard::STATUS_ACTIVE,
                    'fully_redeemed_at' => $isFullyRedeemed
                        ? now()
                        : null,
                ])->save();

                $transaction = GiftCardTransaction::query()->create([
                    'gift_card_id' => $giftCard->id,
                    'appointment_id' => $appointmentId,
                    'performed_by_user_id' => $performedByUserId,

                    'type' => GiftCardTransaction::TYPE_REDEMPTION,

                    'amount' => $normalizedAmount,
                    'balance_before' => $balanceBefore,
                    'balance_after' => $balanceAfter,

                    'notes' => $notes,
                ]);

                return $transaction->load([
                    'giftCard.order.design',
                    'appointment',
                    'performedBy',
                ]);

            },
            3
        );
    }

    /**
     * Ensure the Gift Card is valid and has enough balance.
     */
    private function ensureCardCanBeRedeemed(
        GiftCard $giftCard,
        string $amount
    ): void {
        if ($giftCard->status !== GiftCard::STATUS_ACTIVE) {
            throw ValidationException::withMessages([
                'gift_card' => [
                    'بطاقة الهدية غير نشطة ولا يمكن استخدامها.',
                ],
            ]);
        }

        if ($giftCard->cancelled_at !== null) {
            throw ValidationException::withMessages([
                'gift_card' => [
                    'بطاقة الهدية ملغاة ولا يمكن استخدامها.',
                ],
            ]);
        }

        if ($giftCard->expires_at->isPast()) {
            throw ValidationException::withMessages([
                'gift_card' => [
                    'انتهت صلاحية بطاقة الهدية.',
                ],
            ]);
        }

        if ($this->amountLessThan($giftCard->remaining_balance, $amount)) {
            throw ValidationException::withMessages([
                'amount' => [
                    'رصيد بطاقة الهدية لا يغطي المبلغ المطلوب بالكامل.',
                ],
            ]);
        }
    }

    /**
     * Normalize and validate a monetary amount.
     */
    private function normalizeAmount(int|float|string $amount): string
    {
        if (! is_numeric($amount)) {
            throw ValidationException::withMessages([
                'amount' => [
                    'قيمة الخصم يجب أن تكون رقمًا صحيحًا.',
                ],
            ]);
        }

        $normalizedAmount = number_format(
            (float) $amount,
            2,
            '.',
            ''
        );

        if ($this->amountLessThanOrEqual($normalizedAmount, '0.00')) {
            throw ValidationException::withMessages([
                'amount' => [
                    'قيمة الخصم يجب أن تكون أكبر من صفر.',
                ],
            ]);
        }

        return $normalizedAmount;
    }

    /**
     * Subtract monetary amounts with two-decimal precision.
     */
    private function subtractAmounts(
        string $firstAmount,
        string $secondAmount
    ): string {
        if (function_exists('bcsub')) {
            return bcsub($firstAmount, $secondAmount, 2);
        }

        return number_format(
            round(
                (float) $firstAmount - (float) $secondAmount,
                2
            ),
            2,
            '.',
            ''
        );
    }

    /**
     * Determine whether the first amount is less than the second.
     */
    private function amountLessThan(
        int|float|string $firstAmount,
        int|float|string $secondAmount
    ): bool {
        $first = number_format((float) $firstAmount, 2, '.', '');
        $second = number_format((float) $secondAmount, 2, '.', '');

        if (function_exists('bccomp')) {
            return bccomp($first, $second, 2) === -1;
        }

        return (float) $first < (float) $second;
    }

    /**
     * Determine whether the first amount is less than or equal to the second.
     */
    private function amountLessThanOrEqual(
        int|float|string $firstAmount,
        int|float|string $secondAmount
    ): bool {
        $first = number_format((float) $firstAmount, 2, '.', '');
        $second = number_format((float) $secondAmount, 2, '.', '');

        if (function_exists('bccomp')) {
            return bccomp($first, $second, 2) <= 0;
        }

        return (float) $first <= (float) $second;
    }

    /**
     * Determine whether two monetary amounts are equal.
     */
    private function amountEquals(
        int|float|string $firstAmount,
        int|float|string $secondAmount
    ): bool {
        $first = number_format((float) $firstAmount, 2, '.', '');
        $second = number_format((float) $secondAmount, 2, '.', '');

        if (function_exists('bccomp')) {
            return bccomp($first, $second, 2) === 0;
        }

        return (float) $first === (float) $second;
    }
}
