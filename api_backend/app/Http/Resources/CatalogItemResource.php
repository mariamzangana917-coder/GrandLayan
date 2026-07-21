<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CatalogItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $mainImage = $this->relationLoaded('images')
            ? $this->images->firstWhere('is_primary', true)
            : null;

        $isCustomer = $request->user()?->hasRole('customer') === true;

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

            'is_favorite' => $this->when(
                $isCustomer,
                $this->relationLoaded('favorites')
                    ? $this->favorites->isNotEmpty()
                    : false
            ),

            'main_image' => $mainImage
                ? new CatalogItemImageResource($mainImage)
                : null,

            'images' => CatalogItemImageResource::collection(
                $this->whenLoaded('images')
            ),

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
