<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class PostResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'department' => $this->department,

            'image_path' => $this->image_path,

            'image_url' => $this->image_path
                ? Storage::disk('public')->url($this->image_path)
                : null,

            'description' => $this->description,

            'is_active' => (bool) $this->is_active,

            'created_by' => $this->created_by,

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}