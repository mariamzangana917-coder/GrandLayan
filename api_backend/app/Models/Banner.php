<?php

namespace App\Models;

use App\Enums\BannerActionType;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Banner extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'subtitle',
        'image_path',
        'action_type',
        'action_target_id',
        'external_url',
        'starts_at',
        'ends_at',
        'sort_order',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'action_type' => BannerActionType::class,
            'action_target_id' => 'integer',
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'sort_order' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function scopeVisibleNow(Builder $query, ?CarbonInterface $now = null): Builder
    {
        $now ??= now();

        return $query
            ->where('is_active', true)
            ->where(function (Builder $query) use ($now): void {
                $query->whereNull('starts_at')
                    ->orWhere('starts_at', '<=', $now);
            })
            ->where(function (Builder $query) use ($now): void {
                $query->whereNull('ends_at')
                    ->orWhere('ends_at', '>=', $now);
            });
    }

    public function getDisplayStatusAttribute(): string
    {
        if (! $this->is_active) {
            return 'disabled';
        }

        if ($this->starts_at?->isFuture()) {
            return 'scheduled';
        }

        if ($this->ends_at?->isPast()) {
            return 'expired';
        }

        return 'active';
    }
}
