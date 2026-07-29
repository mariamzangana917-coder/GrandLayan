<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class OfferResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $imageUrl = $this->image_path
            ? url(Storage::disk('public')->url($this->image_path))
            : null;

        return [
            'id' => $this->id,

            'department' => [
                'id' => $this->department?->id,
                'code' => $this->department?->code,
                'name' => $this->department?->name,
            ],

            'catalog_item' => $this->catalogItem === null
                ? null
                : [
                    'id' => $this->catalogItem->id,
                    'name' => $this->catalogItem->name,
                    'type' => $this->catalogItem->type,
                    'price_type' => $this->catalogItem->price_type,
                    'price' => $this->catalogItem->price === null
                        ? null
                        : number_format(
                            (float) $this->catalogItem->price,
                            2,
                            '.',
                            '',
                        ),
                    'duration_minutes' => $this->catalogItem->duration_minutes,
                    'is_active' => (bool) $this->catalogItem->is_active,
                ],

            'title' => $this->title,
            'description' => $this->description,
            'badge_text' => $this->badge_text,
            'value_text' => $this->value_text,
            'details_text' => $this->details_text,
            'image_url' => $imageUrl,

            'starts_at' => $this->starts_at?->toISOString(),
            'ends_at' => $this->ends_at?->toISOString(),
            'is_active' => (bool) $this->is_active,
            'sort_order' => (int) $this->sort_order,
            'availability' => $this->availability(),

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
