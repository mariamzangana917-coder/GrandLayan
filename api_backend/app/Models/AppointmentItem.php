<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AppointmentItem extends Model
{
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'appointment_id',
        'catalog_item_id',
        'item_type',
        'item_name',
        'price_type',
        'unit_price',
        'quantity',
        'duration_minutes',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'appointment_id' => 'integer',
            'catalog_item_id' => 'integer',
            'unit_price' => 'decimal:2',
            'quantity' => 'integer',
            'duration_minutes' => 'integer',
        ];
    }

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }

    public function catalogItem(): BelongsTo
    {
        return $this->belongsTo(CatalogItem::class);
    }

    public function services(): HasMany
    {
        return $this->hasMany(AppointmentService::class)
            ->orderBy('id');
    }
}
