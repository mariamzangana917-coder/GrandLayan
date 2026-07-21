<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GiftCardOrderResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'customer_id' => $this->customer_id,
            'gift_card_design_id' => $this->gift_card_design_id,

            'recipient_name' => $this->recipient_name,
            'recipient_phone' => $this->recipient_phone,
            'gift_message' => $this->gift_message,

            'amount' => $this->amount,

            'payment_method' => $this->payment_method,
            'payment_status' => $this->payment_status,
            'payment_reference' => $this->payment_reference,

            'status' => $this->status,

            'is_paid' => $this->isPaid(),

            'paid_at' => $this->paid_at?->toISOString(),
            'completed_at' => $this->completed_at?->toISOString(),
            'cancelled_at' => $this->cancelled_at?->toISOString(),
            'refunded_at' => $this->refunded_at?->toISOString(),

            'customer' => $this->whenLoaded('customer', function (): array {
                return [
                    'id' => $this->customer->id,
                    'name' => $this->customer->name,
                    'phone' => $this->customer->phone,
                    'email' => $this->customer->email,
                    'avatar' => $this->customer->avatar,
                ];
            }),

            'design' => new GiftCardDesignResource(
                $this->whenLoaded('design')
            ),

            'gift_card' => new GiftCardResource(
                $this->whenLoaded('giftCard')
            ),

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
