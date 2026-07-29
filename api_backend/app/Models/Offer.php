<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Offer extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'department_id',
        'catalog_item_id',
        'created_by_user_id',
        'title',
        'description',
        'badge_text',
        'value_text',
        'details_text',
        'image_path',
        'starts_at',
        'ends_at',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'immutable_datetime',
            'ends_at' => 'immutable_datetime',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function catalogItem(): BelongsTo
    {
        return $this->belongsTo(CatalogItem::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function scopeCurrent(Builder $query): Builder
    {
        return $query
            ->where('is_active', true)
            ->where('starts_at', '<=', now())
            ->where('ends_at', '>=', now());
    }

    public function availability(): string
    {
        if (! $this->is_active) {
            return 'inactive';
        }

        if ($this->starts_at->isFuture()) {
            return 'upcoming';
        }

        if ($this->ends_at->isPast()) {
            return 'expired';
        }

        return 'current';
    }
}
