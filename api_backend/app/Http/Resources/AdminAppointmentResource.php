<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminAppointmentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'reference' => $this->reference,
            'status' => $this->status,

            'customer' => [
                'id' => $this->customer->id,
                'name' => $this->customer->name,
                'phone' => $this->customer->phone,
                'email' => $this->customer->email,
                'is_active' => $this->customer->is_active,
            ],

            'department' => [
                'id' => $this->department->id,
                'code' => $this->department->code,
                'name' => $this->department->name,
            ],

            'requested_start_at' => $this->requested_start_at?->toISOString(),

            'confirmed_start_at' => $this->confirmed_start_at?->toISOString(),

            'customer_notes' => $this->customer_notes,
            'admin_notes' => $this->admin_notes,

            'cancelled_by' => $this->cancelled_by,
            'cancellation_reason' => $this->cancellation_reason,

            'cancelled_at' => $this->cancelled_at?->toISOString(),

            'completed_at' => $this->completed_at?->toISOString(),

            'no_show_at' => $this->no_show_at?->toISOString(),

            'items' => AppointmentItemResource::collection(
                $this->whenLoaded('items')
            ),

            'created_at' => $this->created_at?->toISOString(),

            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
