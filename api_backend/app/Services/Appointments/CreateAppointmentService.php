<?php

namespace App\Services\Appointments;

use App\Models\Appointment;
use App\Models\CatalogItem;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CreateAppointmentService
{
    /**
     * Create a complete appointment with immutable snapshots.
     *
     * @param  array<string, mixed>  $data
     */
    public function create(User $customer, array $data): Appointment
    {
        return DB::transaction(function () use (
            $customer,
            $data
        ): Appointment {
            $catalogItemIds = collect($data['items'])
                ->pluck('catalog_item_id')
                ->map(fn ($id): int => (int) $id)
                ->all();

            $catalogItems = CatalogItem::query()
                ->with([
                    'category',
                    'packageServices.category',
                ])
                ->whereIn('id', $catalogItemIds)
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            $appointment = Appointment::query()->create([
                'reference' => $this->generateUniqueReference(),
                'customer_id' => $customer->id,
                'department_id' => (int) $data['department_id'],
                'status' => Appointment::STATUS_PENDING,
                'requested_start_at' => $data['requested_start_at'],
                'confirmed_start_at' => null,
                'customer_notes' => $data['customer_notes'] ?? null,
                'admin_notes' => null,
            ]);

            foreach ($data['items'] as $submittedItem) {
                $catalogItem = $catalogItems->get(
                    (int) $submittedItem['catalog_item_id']
                );

                /*
                 * The request validation guarantees this item exists.
                 * This additional check protects against unexpected races.
                 */
                if (! $catalogItem instanceof CatalogItem) {
                    abort(
                        422,
                        'إحدى الخدمات لم تعد متاحة للحجز.'
                    );
                }

                $quantity = (int) $submittedItem['quantity'];

                $appointmentItem = $appointment->items()->create([
                    'catalog_item_id' => $catalogItem->id,
                    'item_type' => $catalogItem->type,
                    'item_name' => $catalogItem->name,
                    'price_type' => $catalogItem->price_type,
                    'unit_price' => $catalogItem->price,
                    'quantity' => $quantity,
                    'duration_minutes' => $this->calculateItemDuration(
                        $catalogItem
                    ),
                ]);

                if ($catalogItem->isService()) {
                    $appointmentItem->services()->create([
                        'service_id' => $catalogItem->id,
                        'service_name' => $catalogItem->name,
                        'quantity' => $quantity,
                        'duration_minutes' => (int) $catalogItem->duration_minutes,
                        'unit_price' => $catalogItem->price,
                        'scheduled_start_at' => null,
                        'scheduled_end_at' => null,
                        'notes' => null,
                    ]);

                    continue;
                }

                foreach ($catalogItem->packageServices as $service) {
                    $componentQuantity =
                        (int) $service->pivot->quantity
                        * $quantity;

                    $appointmentItem->services()->create([
                        'service_id' => $service->id,
                        'service_name' => $service->name,
                        'quantity' => $componentQuantity,
                        'duration_minutes' => (int) $service->duration_minutes,

                        /*
                         * The customer bought the package as one commercial
                         * item, so its components do not receive separate
                         * prices in the appointment.
                         */
                        'unit_price' => null,

                        'scheduled_start_at' => null,
                        'scheduled_end_at' => null,
                        'notes' => $service->pivot->notes,
                    ]);
                }
            }

            return $appointment
                ->load([
                    'customer',
                    'department',
                    'items.services',
                ]);
        }, 3);
    }

    private function calculateItemDuration(
        CatalogItem $catalogItem
    ): ?int {
        if ($catalogItem->isService()) {
            return (int) $catalogItem->duration_minutes;
        }

        /** @var Collection<int, CatalogItem> $services */
        $services = $catalogItem->packageServices;

        $totalDuration = $services->sum(
            fn (CatalogItem $service): int => (int) $service->duration_minutes
                * (int) $service->pivot->quantity
        );

        return $totalDuration > 0
            ? $totalDuration
            : null;
    }

    private function generateUniqueReference(): string
    {
        do {
            $reference = sprintf(
                'GL-%s-%s',
                now()->format('Ymd'),
                Str::upper(Str::random(8))
            );
        } while (
            Appointment::query()
                ->where('reference', $reference)
                ->exists()
        );

        return $reference;
    }
}
