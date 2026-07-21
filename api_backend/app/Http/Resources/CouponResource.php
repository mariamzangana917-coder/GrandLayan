<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CouponResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'name' => $this->name,

            'code' => $this->code,

            'discount_type' => $this->discount_type,

            'discount_value' => (float) $this->discount_value,

            'minimum_order_amount' => $this->minimum_order_amount !== null
                ? (float) $this->minimum_order_amount
                : null,

            'maximum_discount_amount' => $this->maximum_discount_amount !== null
                ? (float) $this->maximum_discount_amount
                : null,

            'department_id' => $this->department_id,

            'department' => $this->whenLoaded(
                'department',
                fn () => [
                    'id' => $this->department->id,
                    'name' => $this->department->name,
                ]
            ),

            'maximum_total_uses' => $this->maximum_total_uses,

            'maximum_uses_per_customer' => $this->maximum_uses_per_customer,

            'used_count' => $this->used_count,

            'remaining_uses' => $this->maximum_total_uses !== null
                ? max(
                    0,
                    $this->maximum_total_uses - $this->used_count
                )
                : null,

            'starts_at' => $this->starts_at?->toISOString(),

            'expires_at' => $this->expires_at?->toISOString(),

            'is_active' => $this->is_active,

            'is_available' => $this->isCurrentlyAvailable(),

            'notes' => $this->notes,

            'catalog_item_ids' => $this->whenLoaded(
                'catalogItems',
                fn () => $this->catalogItems
                    ->pluck('id')
                    ->values()
            ),

            'created_at' => $this->created_at?->toISOString(),

            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
