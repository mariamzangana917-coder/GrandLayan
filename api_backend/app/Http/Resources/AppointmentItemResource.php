<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AppointmentItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'catalog_item_id' => $this->catalog_item_id,
            'item_type' => $this->item_type,
            'item_name' => $this->item_name,

            'price_type' => $this->price_type,
            'unit_price' => $this->unit_price,

            'quantity' => (int) $this->quantity,

            'duration_minutes' => $this->duration_minutes !== null
                    ? (int) $this->duration_minutes
                    : null,

            'services' => AppointmentServiceResource::collection(
                $this->whenLoaded('services')
            ),
        ];
    }
}
