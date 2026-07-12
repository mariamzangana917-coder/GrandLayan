<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PackageItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'service' => [
                'id' => $this->service->id,
                'name' => $this->service->name,
                'type' => $this->service->type,
                'price_type' => $this->service->price_type,
                'price' => $this->service->price,
                'duration_minutes' => $this->service->duration_minutes,
                'is_active' => (bool) $this->service->is_active,
            ],

            'quantity' => (int) $this->quantity,
            'notes' => $this->notes,

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}