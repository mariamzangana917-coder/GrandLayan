<?php

namespace App\Services\Chat;

use App\Models\CatalogItem;

class GrandLayanKnowledgeService
{
    /**
     * @return array<int, array<string, mixed>>
     */
    public function services(): array
    {
        return CatalogItem::query()
            ->with('department:id,name')
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(function (CatalogItem $item): array {
                return [
                    'id' => $item->id,
                    'name' => $item->name,
                    'department' => $item->department?->name,
                    'type' => $item->type,
                    'price_type' => $item->price_type,
                    'price' => $item->price,
                    'duration_minutes' => $item->duration_minutes,
                    'description' => $item->description,
                ];
            })
            ->all();
    }
}