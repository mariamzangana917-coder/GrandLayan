<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GiftCardResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $qrTokenIsVisible = ! in_array(
            'qr_token',
            $this->resource->getHidden(),
            true
        );

        return [
            'id' => $this->id,

            'gift_card_order_id' => $this->gift_card_order_id,

            'code' => $this->code,

            /*
             * qr_token is hidden by default in the model.
             *
             * It is returned only when an authorized endpoint deliberately
             * calls:
             *
             * $giftCard->makeVisible('qr_token');
             */
            'qr_token' => $this->when(
                $qrTokenIsVisible,
                $this->qr_token
            ),

            'initial_balance' => $this->initial_balance,
            'remaining_balance' => $this->remaining_balance,

            'status' => $this->status,

            'is_usable' => $this->isUsable(),
            'has_expired' => $this->hasExpired(),

            'issued_at' => $this->issued_at?->toISOString(),
            'expires_at' => $this->expires_at?->toISOString(),
            'fully_redeemed_at' => $this->fully_redeemed_at?->toISOString(),
            'cancelled_at' => $this->cancelled_at?->toISOString(),

            'order' => new GiftCardOrderResource(
                $this->whenLoaded('order')
            ),

            'transactions' => GiftCardTransactionResource::collection(
                $this->whenLoaded('transactions')
            ),

            'transactions_count' => $this->whenCounted('transactions'),

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
