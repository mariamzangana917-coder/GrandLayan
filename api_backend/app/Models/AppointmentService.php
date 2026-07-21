<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AppointmentService extends Model
{
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'appointment_item_id',
        'service_id',
        'service_name',
        'quantity',
        'duration_minutes',
        'unit_price',
        'scheduled_start_at',
        'scheduled_end_at',
        'notes',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'appointment_item_id' => 'integer',
            'service_id' => 'integer',
            'quantity' => 'integer',
            'duration_minutes' => 'integer',
            'unit_price' => 'decimal:2',
            'scheduled_start_at' => 'datetime',
            'scheduled_end_at' => 'datetime',
        ];
    }

    public function appointmentItem(): BelongsTo
    {
        return $this->belongsTo(AppointmentItem::class);
    }

    public function service(): BelongsTo
    {
        return $this->belongsTo(
            CatalogItem::class,
            'service_id'
        );
    }
}
