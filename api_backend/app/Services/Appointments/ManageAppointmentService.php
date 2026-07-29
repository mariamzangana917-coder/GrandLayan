<?php

namespace App\Services\Appointments;

use App\Models\Appointment;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ManageAppointmentService
{
    public function __construct(
        private readonly AppointmentCouponService $appointmentCouponService,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public function update(Appointment $appointment, array $data): Appointment
    {
        return DB::transaction(function () use ($appointment, $data): Appointment {
            $locked = $this->lock($appointment);

            if (! $locked->canBeEdited()) {
                $this->invalidTransition();
            }

            if (
                $locked->status === Appointment::STATUS_CONFIRMED
                && array_key_exists('requested_start_at', $data)
                && ! array_key_exists('confirmed_start_at', $data)
            ) {
                $data['confirmed_start_at'] = $data['requested_start_at'];
            }

            $locked->update($data);

            return $this->load($locked);
        }, 3);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function confirm(Appointment $appointment, array $data): Appointment
    {
        return $this->transition(
            $appointment,
            Appointment::STATUS_CONFIRMED,
            function (Appointment $locked) use ($data): array {
                return [
                    'confirmed_start_at' => $data['confirmed_start_at']
                            ?? $locked->requested_start_at,
                    'admin_notes' => $data['admin_notes']
                            ?? $locked->admin_notes,
                ];
            }
        );
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function start(Appointment $appointment, array $data): Appointment
    {
        return $this->transition(
            $appointment,
            Appointment::STATUS_IN_PROGRESS,
            fn (Appointment $locked): array => [
                'admin_notes' => $data['admin_notes']
                        ?? $locked->admin_notes,
            ]
        );
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function complete(Appointment $appointment, array $data): Appointment
    {
        return $this->transition(
            $appointment,
            Appointment::STATUS_COMPLETED,
            fn (Appointment $locked): array => [
                'completed_at' => now(),
                'admin_notes' => $data['admin_notes']
                        ?? $locked->admin_notes,
            ]
        );
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function cancel(Appointment $appointment, array $data): Appointment
    {
        return $this->transition(
            $appointment,
            Appointment::STATUS_CANCELLED,
            fn (Appointment $locked): array => [
                'cancelled_by' => 'manager',
                'cancellation_reason' => trim($data['reason']),
                'cancelled_at' => now(),
                'admin_notes' => $data['admin_notes']
                        ?? $locked->admin_notes,
            ]
        );
    }

    public function cancelByCustomer(
        Appointment $appointment,
        ?string $reason = null
    ): Appointment {
        return $this->transition(
            $appointment,
            Appointment::STATUS_CANCELLED,
            fn (Appointment $locked): array => [
                'cancelled_by' => 'customer',
                'cancellation_reason' => filled($reason)
                    ? trim($reason)
                    : 'تم إلغاء الموعد من قبل الزبونة.',
                'cancelled_at' => now(),
            ]
        );
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function markNoShow(
        Appointment $appointment,
        array $data
    ): Appointment {
        return DB::transaction(function () use ($appointment, $data): Appointment {
            $locked = $this->lock($appointment);
            $effectiveStart = $locked->confirmed_start_at
                ?? $locked->requested_start_at;

            if (
                ! $locked->canTransitionTo(Appointment::STATUS_NO_SHOW)
                || $effectiveStart->isFuture()
            ) {
                $this->invalidTransition(
                    'لا يمكن تنفيذ هذا الإجراء على حالة الموعد الحالية.'
                );
            }

            $locked->update([
                'status' => Appointment::STATUS_NO_SHOW,
                'no_show_at' => now(),
                'admin_notes' => $data['admin_notes']
                        ?? $locked->admin_notes,
            ]);

            return $this->load($locked);
        }, 3);
    }

    /**
     * @param  callable(Appointment): array<string, mixed>  $attributes
     */
    private function transition(
        Appointment $appointment,
        string $targetStatus,
        callable $attributes
    ): Appointment {
        return DB::transaction(function () use (
            $appointment,
            $targetStatus,
            $attributes
        ): Appointment {
            $locked = $this->lock($appointment);

            if (! $locked->canTransitionTo($targetStatus)) {
                $this->invalidTransition();
            }

            $locked->update([
                'status' => $targetStatus,
                ...$attributes($locked),
            ]);

            if ($targetStatus === Appointment::STATUS_CANCELLED) {
                $this->appointmentCouponService
                    ->releaseForAppointment($locked);
            }

            return $this->load($locked);
        }, 3);
    }

    private function lock(Appointment $appointment): Appointment
    {
        return Appointment::query()
            ->whereKey($appointment->getKey())
            ->lockForUpdate()
            ->firstOrFail();
    }

    private function load(Appointment $appointment): Appointment
    {
        return $appointment->load([
            'customer',
            'department',
            'coupon',
            'items.services',
        ]);
    }

    private function invalidTransition(
        string $message = 'لا يمكن تنفيذ هذا الإجراء على حالة الموعد الحالية.'
    ): never {
        throw ValidationException::withMessages([
            'status' => [$message],
        ]);
    }
}
