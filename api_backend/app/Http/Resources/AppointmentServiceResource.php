<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AppointmentServiceResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'service_id' => $this->service_id,
            'service_name' => $this->service_name,

            'quantity' => (int) $this->quantity,
            'duration_minutes' => (int) $this->duration_minutes,

            'unit_price' => $this->unit_price,

            'scheduled_start_at' => $this->scheduled_start_at?->toISOString(),

            'scheduled_end_at' => $this->scheduled_end_at?->toISOString(),

            'notes' => $this->notes,
        ];
    }
}
