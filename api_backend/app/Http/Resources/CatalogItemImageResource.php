<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class CatalogItemImageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'image_url' => $this->path
                ? url(Storage::disk('public')->url($this->path))
                : null,

            'image_path' => $this->path,

            'is_primary' => (bool) $this->is_primary,

            'sort_order' => (int) $this->sort_order,
        ];
    }
}