<?php

namespace App\Services\GiftCards;

use App\Models\GiftCard;
use App\Models\GiftCardOrder;
use App\Models\GiftCardTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Throwable;

class IssueGiftCardService
{
    private const CODE_PREFIX = 'GL';

    private const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    private const GENERATION_ATTEMPTS = 20;

    /**
     * Confirm payment and issue exactly one Gift Card for the order.
     *
     * Repeated calls for an already completed order are idempotent:
     * the previously issued Gift Card is returned.
     *
     * @throws Throwable
     */
    public function execute(
        GiftCardOrder|int $order,
        ?string $paymentReference = null
    ): GiftCard {
        $orderId = $order instanceof GiftCardOrder
            ? $order->getKey()
            : $order;

        return DB::transaction(
            function () use ($orderId, $paymentReference): GiftCard {
                $lockedOrder = GiftCardOrder::query()
                    ->with('design')
                    ->lockForUpdate()
                    ->findOrFail($orderId);

                /*
                 * Idempotency:
                 * If the order was already completed and its card exists,
                 * return the same card instead of creating another one.
                 */
                if ($lockedOrder->status === GiftCardOrder::STATUS_COMPLETED) {
                    $existingGiftCard = GiftCard::query()
                        ->where('gift_card_order_id', $lockedOrder->id)
                        ->first();

                    if ($existingGiftCard !== null) {
                        return $this->loadResultRelations($existingGiftCard);
                    }

                    throw ValidationException::withMessages([
                        'gift_card_order_id' => [
                            'الطلب مكتمل، لكن بطاقة الهدية المرتبطة به غير موجودة.',
                        ],
                    ]);
                }

                $this->ensureOrderCanBeIssued(
                    $lockedOrder,
                    $paymentReference
                );

                $issuedAt = now();

                $giftCard = GiftCard::query()->create([
                    'gift_card_order_id' => $lockedOrder->id,
                    'code' => $this->generateUniqueCode(),
                    'qr_token' => $this->generateUniqueQrToken(),

                    'initial_balance' => $lockedOrder->amount,
                    'remaining_balance' => $lockedOrder->amount,

                    'status' => GiftCard::STATUS_ACTIVE,

                    'issued_at' => $issuedAt,
                    'expires_at' => $issuedAt
                        ->copy()
                        ->addDays($lockedOrder->design->validity_days),

                    'fully_redeemed_at' => null,
                    'cancelled_at' => null,
                ]);

                GiftCardTransaction::query()->create([
                    'gift_card_id' => $giftCard->id,
                    'appointment_id' => null,
                    'performed_by_user_id' => null,

                    'type' => GiftCardTransaction::TYPE_ISSUANCE,

                    'amount' => $lockedOrder->amount,
                    'balance_before' => 0,
                    'balance_after' => $lockedOrder->amount,

                    'notes' => 'إصدار تلقائي لبطاقة الهدية بعد تأكيد الدفع.',
                ]);

                $lockedOrder->forceFill([
                    'payment_status' => GiftCardOrder::PAYMENT_STATUS_PAID,
                    'payment_reference' => $this->resolvePaymentReference(
                        $lockedOrder,
                        $paymentReference
                    ),

                    'status' => GiftCardOrder::STATUS_COMPLETED,

                    'paid_at' => $lockedOrder->paid_at ?? $issuedAt,
                    'completed_at' => $issuedAt,

                    'cancelled_at' => null,
                    'refunded_at' => null,
                ])->save();

                /*
                 * Notifications will later be dispatched after commit:
                 *
                 * Customer:
                 * "تم تفعيل بطاقة الهدية الخاصة بك ويمكن استخدامها الآن."
                 *
                 * Manager:
                 * "تم تأكيد الدفع وإصدار بطاقة الهدية بنجاح."
                 */

                return $this->loadResultRelations($giftCard);
            },
            3
        );
    }

    /**
     * Ensure the order is in a state that allows payment confirmation
     * and Gift Card issuance.
     */
    private function ensureOrderCanBeIssued(
        GiftCardOrder $order,
        ?string $paymentReference
    ): void {
        if ($order->status !== GiftCardOrder::STATUS_PENDING) {
            throw ValidationException::withMessages([
                'gift_card_order_id' => [
                    'لا يمكن إصدار بطاقة هدية لهذا الطلب بحالته الحالية.',
                ],
            ]);
        }

        if (
            $order->payment_status === GiftCardOrder::PAYMENT_STATUS_FAILED
            || $order->payment_status === GiftCardOrder::PAYMENT_STATUS_REFUNDED
        ) {
            throw ValidationException::withMessages([
                'payment_status' => [
                    'حالة دفع الطلب لا تسمح بإصدار بطاقة الهدية.',
                ],
            ]);
        }

        if ($order->design === null) {
            throw ValidationException::withMessages([
                'gift_card_design_id' => [
                    'تصميم بطاقة الهدية المرتبط بالطلب غير موجود.',
                ],
            ]);
        }

        if (
            $order->payment_method
                === GiftCardOrder::PAYMENT_METHOD_ELECTRONIC
            && blank($paymentReference)
            && blank($order->payment_reference)
        ) {
            throw ValidationException::withMessages([
                'payment_reference' => [
                    'مرجع الدفع مطلوب عند تأكيد الدفع الإلكتروني.',
                ],
            ]);
        }
    }

    /**
     * Preserve an existing payment reference or use the newly supplied one.
     */
    private function resolvePaymentReference(
        GiftCardOrder $order,
        ?string $paymentReference
    ): ?string {
        if (
            $order->payment_method
                === GiftCardOrder::PAYMENT_METHOD_CASH
        ) {
            return null;
        }

        return $paymentReference ?? $order->payment_reference;
    }

    /**
     * Generate a readable code such as GL-7Q8M-P4XT.
     */
    private function generateUniqueCode(): string
    {
        for ($attempt = 1; $attempt <= self::GENERATION_ATTEMPTS; $attempt++) {
            $code = sprintf(
                '%s-%s-%s',
                self::CODE_PREFIX,
                $this->randomCharacters(4),
                $this->randomCharacters(4)
            );

            $exists = GiftCard::query()
                ->where('code', $code)
                ->exists();

            if (! $exists) {
                return $code;
            }
        }

        throw ValidationException::withMessages([
            'code' => [
                'تعذر إنشاء كود فريد لبطاقة الهدية. يرجى إعادة المحاولة.',
            ],
        ]);
    }

    /**
     * Generate a cryptographically secure 64-character QR token.
     */
    private function generateUniqueQrToken(): string
    {
        for ($attempt = 1; $attempt <= self::GENERATION_ATTEMPTS; $attempt++) {
            $token = bin2hex(random_bytes(32));

            $exists = GiftCard::query()
                ->where('qr_token', $token)
                ->exists();

            if (! $exists) {
                return $token;
            }
        }

        throw ValidationException::withMessages([
            'qr_token' => [
                'تعذر إنشاء رمز QR فريد. يرجى إعادة المحاولة.',
            ],
        ]);
    }

    /**
     * Generate random characters from an unambiguous alphabet.
     */
    private function randomCharacters(int $length): string
    {
        $result = '';
        $maximumIndex = strlen(self::CODE_ALPHABET) - 1;

        for ($index = 0; $index < $length; $index++) {
            $result .= self::CODE_ALPHABET[
                random_int(0, $maximumIndex)
            ];
        }

        return $result;
    }

    /**
     * Load the relationships required by the API Resource.
     */
    private function loadResultRelations(GiftCard $giftCard): GiftCard
    {
        return $giftCard->load([
            'order.design',
            'transactions',
        ]);
    }
}
