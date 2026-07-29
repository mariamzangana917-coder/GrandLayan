<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class CatalogItemImageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $publicUrl = $this->path
            ? url(Storage::disk('public')->url($this->path))
            : $this->url;

        return [
            'id' => $this->id,

            'path' => $this->path,
            'url' => $publicUrl,
            'alt_text' => $this->alt_text,

            'image_path' => $this->path,
            'image_url' => $publicUrl,

            'is_primary' => (bool) $this->is_primary,
            'sort_order' => (int) $this->sort_order,

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}