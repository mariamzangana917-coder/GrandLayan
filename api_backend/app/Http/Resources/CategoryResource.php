<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class CategoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'department_id' => $this->department_id,

            'department' => [
                'id' => $this->department->id,
                'code' => $this->department->code,
                'name' => $this->department->name,
            ],

            'name' => $this->name,
            'description' => $this->description,

            'image_path' => $this->image_path,

            'image_url' => $this->image_path !== null
                ? url(
                    Storage::url(
                        $this->image_path
                    )
                )
                : null,

            'is_active' => (bool) $this->is_active,

            'catalog_items_count' =>
                $this->whenCounted(
                    'catalogItems'
                ),

            'created_at' =>
                $this->created_at?->toISOString(),

            'updated_at' =>
                $this->updated_at?->toISOString(),
        ];
    }
}