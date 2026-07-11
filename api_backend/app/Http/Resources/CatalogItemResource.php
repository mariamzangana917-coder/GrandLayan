<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CatalogItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'department' => [
                'id' => $this->category->department->id,
                'code' => $this->category->department->code,
                'name' => $this->category->department->name,
            ],

            'category' => [
                'id' => $this->category->id,
                'name' => $this->category->name,
            ],

            'type' => $this->type,
            'name' => $this->name,
            'description' => $this->description,
            'instructions' => $this->instructions,

            'price_type' => $this->price_type,
            'price' => $this->price,

            'duration_minutes' => $this->duration_minutes,
            'is_active' => (bool) $this->is_active,

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}