<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GiftCardTransactionResource extends JsonResource
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

            'gift_card_id' => $this->gift_card_id,
            'appointment_id' => $this->appointment_id,
            'performed_by_user_id' => $this->performed_by_user_id,

            'type' => $this->type,

            'amount' => $this->amount,
            'balance_before' => $this->balance_before,
            'balance_after' => $this->balance_after,

            'notes' => $this->notes,

            'gift_card' => new GiftCardResource(
                $this->whenLoaded('giftCard')
            ),

            'appointment' => $this->whenLoaded(
                'appointment',
                function (): array {
                    return [
                        'id' => $this->appointment->id,
                    ];
                }
            ),

            'performed_by' => $this->whenLoaded(
                'performedBy',
                function (): array {
                    return [
                        'id' => $this->performedBy->id,
                        'name' => $this->performedBy->name,
                        'phone' => $this->performedBy->phone,
                        'email' => $this->performedBy->email,
                    ];
                }
            ),

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
