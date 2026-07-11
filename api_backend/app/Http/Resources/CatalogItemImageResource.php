<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class CatalogItemImageResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'path' => $this->path,

            /*
             * Use the explicitly stored external URL when available.
             * Otherwise, generate the URL from the public storage disk.
             */
            'url' => $this->url
                ?? Storage::disk('public')->url($this->path),

            'alt_text' => $this->alt_text,
            'is_primary' => (bool) $this->is_primary,
            'sort_order' => (int) $this->sort_order,

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}