<?php

namespace App\Services\GiftCards;

use App\Models\GiftCardDesign;
use App\Models\GiftCardOrder;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class StoreGiftCardOrderService
{
    /**
     * Create a pending Gift Card purchase order.
     *
     * The Gift Card itself is not issued here.
     * Issuance happens only after payment is confirmed.
     *
     * @param  array<string, mixed>  $data
     */
    public function execute(User $customer, array $data): GiftCardOrder
    {
        return DB::transaction(function () use ($customer, $data): GiftCardOrder {
            $design = GiftCardDesign::query()
                ->lockForUpdate()
                ->find($data['gift_card_design_id']);

            if (! $design || ! $design->is_active) {
                throw ValidationException::withMessages([
                    'gift_card_design_id' => [
                        'تصميم بطاقة الهدية غير متاح حاليًا.',
                    ],
                ]);
            }

            $order = GiftCardOrder::query()->create([
                'customer_id' => $customer->id,
                'gift_card_design_id' => $design->id,

                'recipient_name' => $data['recipient_name'],
                'recipient_phone' => $data['recipient_phone'] ?? null,
                'gift_message' => $data['gift_message'] ?? null,

                /*
                 * Snapshot the design value at purchase time.
                 */
                'amount' => $design->amount,

                'payment_method' => $data['payment_method'],
                'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
                'payment_reference' => null,

                'status' => GiftCardOrder::STATUS_PENDING,

                'paid_at' => null,
                'completed_at' => null,
                'cancelled_at' => null,
                'refunded_at' => null,
            ]);

            /*
             * Notifications will be dispatched after the order is created.
             *
             * Customer:
             * "تم استلام طلبك، وسيتم تفعيل بطاقة الهدية بعد تأكيد الدفع."
             *
             * Manager:
             * "يوجد طلب بطاقة هدية جديد بانتظار تأكيد الدفع."
             */

            return $order->load('design');
        }, 3);
    }
}
