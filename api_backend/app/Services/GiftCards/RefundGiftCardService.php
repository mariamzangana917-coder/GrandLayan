<?php

namespace App\Services\GiftCards;

use App\Models\Appointment;
use App\Models\GiftCard;
use App\Models\GiftCardTransaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Throwable;

class RefundGiftCardService
{
    /**
     * Refund an amount to the same Gift Card used for an appointment.
     *
     * The total refunds for a card and appointment cannot exceed
     * the total amount previously redeemed from that card
     * for the same appointment.
     *
     * @throws Throwable
     */
    public function execute(
        GiftCard|int $giftCard,
        Appointment|int $appointment,
        int|float|string $amount,
        User|int|null $performedBy = null,
        ?string $notes = null
    ): GiftCardTransaction {
        $giftCardId = $giftCard instanceof GiftCard
            ? $giftCard->getKey()
            : $giftCard;

        $appointmentId = $appointment instanceof Appointment
            ? $appointment->getKey()
            : $appointment;

        $performedByUserId = $performedBy instanceof User
            ? $performedBy->getKey()
            : $performedBy;

        $normalizedAmount = $this->normalizeAmount($amount);

        return DB::transaction(
            function () use (
                $giftCardId,
                $appointmentId,
                $normalizedAmount,
                $performedByUserId,
                $notes
            ): GiftCardTransaction {
                $lockedGiftCard = GiftCard::query()
                    ->lockForUpdate()
                    ->find($giftCardId);

                if ($lockedGiftCard === null) {
                    throw ValidationException::withMessages([
                        'gift_card_id' => [
                            'بطاقة الهدية المحددة غير موجودة.',
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

                $this->ensureGiftCardAllowsRefund($lockedGiftCard);

                /*
                 * Lock all financial transactions for this Gift Card
                 * while calculating the refundable amount.
                 */
                $transactions = GiftCardTransaction::query()
                    ->where('gift_card_id', $lockedGiftCard->id)
                    ->where('appointment_id', $appointmentId)
                    ->lockForUpdate()
                    ->get([
                        'id',
                        'type',
                        'amount',
                    ]);

                $totalRedeemed = $this->sumTransactionAmounts(
                    $transactions
                        ->where(
                            'type',
                            GiftCardTransaction::TYPE_REDEMPTION
                        )
                        ->pluck('amount')
                        ->all()
                );

                $totalRefunded = $this->sumTransactionAmounts(
                    $transactions
                        ->where(
                            'type',
                            GiftCardTransaction::TYPE_REFUND
                        )
                        ->pluck('amount')
                        ->all()
                );

                if ($this->amountEquals($totalRedeemed, '0.00')) {
                    throw ValidationException::withMessages([
                        'appointment_id' => [
                            'لم يتم استخدام هذه البطاقة في الحجز المحدد.',
                        ],
                    ]);
                }

                $remainingRefundableAmount = $this->subtractAmounts(
                    $totalRedeemed,
                    $totalRefunded
                );

                if (
                    $this->amountGreaterThan(
                        $normalizedAmount,
                        $remainingRefundableAmount
                    )
                ) {
                    throw ValidationException::withMessages([
                        'amount' => [
                            'مبلغ الاسترجاع يتجاوز المبلغ المتبقي القابل للاسترجاع لهذا الحجز.',
                        ],
                    ]);
                }

                $balanceBefore = $this->normalizeStoredAmount(
                    $lockedGiftCard->remaining_balance
                );

                $balanceAfter = $this->addAmounts(
                    $balanceBefore,
                    $normalizedAmount
                );

                $initialBalance = $this->normalizeStoredAmount(
                    $lockedGiftCard->initial_balance
                );

                if (
                    $this->amountGreaterThan(
                        $balanceAfter,
                        $initialBalance
                    )
                ) {
                    throw ValidationException::withMessages([
                        'amount' => [
                            'لا يمكن أن يتجاوز رصيد البطاقة قيمتها الأصلية.',
                        ],
                    ]);
                }

                $newStatus = $this->resolveStatusAfterRefund(
                    $lockedGiftCard
                );

                $lockedGiftCard->forceFill([
                    'remaining_balance' => $balanceAfter,
                    'status' => $newStatus,
                    'fully_redeemed_at' => null,
                ])->save();

                $transaction = GiftCardTransaction::query()->create([
                    'gift_card_id' => $lockedGiftCard->id,
                    'appointment_id' => $appointmentId,
                    'performed_by_user_id' => $performedByUserId,

                    'type' => GiftCardTransaction::TYPE_REFUND,

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
     * Ensure this Gift Card can receive a refund.
     */
    private function ensureGiftCardAllowsRefund(
        GiftCard $giftCard
    ): void {
        if (
            $giftCard->status === GiftCard::STATUS_CANCELLED
            || $giftCard->cancelled_at !== null
        ) {
            throw ValidationException::withMessages([
                'gift_card_id' => [
                    'بطاقة الهدية ملغاة ولا يمكن إعادة المبلغ إليها.',
                ],
            ]);
        }
    }

    /**
     * Determine the Gift Card status after restoring balance.
     */
    private function resolveStatusAfterRefund(
        GiftCard $giftCard
    ): string {
        if ($giftCard->hasExpired()) {
            return GiftCard::STATUS_EXPIRED;
        }

        return GiftCard::STATUS_ACTIVE;
    }

    /**
     * Normalize and validate a requested monetary amount.
     */
    private function normalizeAmount(
        int|float|string $amount
    ): string {
        if (! is_numeric($amount)) {
            throw ValidationException::withMessages([
                'amount' => [
                    'مبلغ الاسترجاع يجب أن يكون رقمًا صحيحًا.',
                ],
            ]);
        }

        $normalizedAmount = number_format(
            (float) $amount,
            2,
            '.',
            ''
        );

        if (
            $this->amountLessThanOrEqual(
                $normalizedAmount,
                '0.00'
            )
        ) {
            throw ValidationException::withMessages([
                'amount' => [
                    'مبلغ الاسترجاع يجب أن يكون أكبر من صفر.',
                ],
            ]);
        }

        return $normalizedAmount;
    }

    /**
     * Normalize an amount already stored in the database.
     */
    private function normalizeStoredAmount(
        int|float|string $amount
    ): string {
        return number_format(
            (float) $amount,
            2,
            '.',
            ''
        );
    }

    /**
     * Sum a collection of monetary values.
     *
     * @param  array<int, int|float|string>  $amounts
     */
    private function sumTransactionAmounts(
        array $amounts
    ): string {
        $total = '0.00';

        foreach ($amounts as $amount) {
            $total = $this->addAmounts(
                $total,
                $this->normalizeStoredAmount($amount)
            );
        }

        return $total;
    }

    /**
     * Add two monetary values with two-decimal precision.
     */
    private function addAmounts(
        string $firstAmount,
        string $secondAmount
    ): string {
        if (function_exists('bcadd')) {
            return bcadd(
                $firstAmount,
                $secondAmount,
                2
            );
        }

        return number_format(
            round(
                (float) $firstAmount + (float) $secondAmount,
                2
            ),
            2,
            '.',
            ''
        );
    }

    /**
     * Subtract two monetary values with two-decimal precision.
     */
    private function subtractAmounts(
        string $firstAmount,
        string $secondAmount
    ): string {
        if (function_exists('bcsub')) {
            return bcsub(
                $firstAmount,
                $secondAmount,
                2
            );
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
     * Determine whether the first amount is greater than the second.
     */
    private function amountGreaterThan(
        int|float|string $firstAmount,
        int|float|string $secondAmount
    ): bool {
        $first = $this->normalizeStoredAmount($firstAmount);
        $second = $this->normalizeStoredAmount($secondAmount);

        if (function_exists('bccomp')) {
            return bccomp($first, $second, 2) === 1;
        }

        return (float) $first > (float) $second;
    }

    /**
     * Determine whether the first amount is less than or equal to the second.
     */
    private function amountLessThanOrEqual(
        int|float|string $firstAmount,
        int|float|string $secondAmount
    ): bool {
        $first = $this->normalizeStoredAmount($firstAmount);
        $second = $this->normalizeStoredAmount($secondAmount);

        if (function_exists('bccomp')) {
            return bccomp($first, $second, 2) <= 0;
        }

        return (float) $first <= (float) $second;
    }

    /**
     * Determine whether two monetary values are equal.
     */
    private function amountEquals(
        int|float|string $firstAmount,
        int|float|string $secondAmount
    ): bool {
        $first = $this->normalizeStoredAmount($firstAmount);
        $second = $this->normalizeStoredAmount($secondAmount);

        if (function_exists('bccomp')) {
            return bccomp($first, $second, 2) === 0;
        }

        return (float) $first === (float) $second;
    }
}
