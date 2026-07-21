<?php

namespace Database\Factories;

use App\Models\Appointment;
use App\Models\Department;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Appointment>
 */
class AppointmentFactory extends Factory
{
    protected $model = Appointment::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'reference' => sprintf(
                'GL-%s-%s',
                now()->format('Ymd'),
                Str::upper(Str::random(8))
            ),

            'customer_id' => User::factory(),

            'department_id' => Department::factory(),

            'status' => Appointment::STATUS_PENDING,

            'requested_start_at' => now()->addDay(),

            'confirmed_start_at' => null,

            'customer_notes' => null,

            'admin_notes' => null,

            'cancelled_by' => null,

            'cancellation_reason' => null,

            'cancelled_at' => null,

            'completed_at' => null,

            'no_show_at' => null,
        ];
    }

    public function confirmed(): static
    {
        return $this->state(function (): array {
            return [
                'status' => Appointment::STATUS_CONFIRMED,
                'confirmed_start_at' => now()->addDay(),
            ];
        });
    }

    public function inProgress(): static
    {
        return $this->state(function (): array {
            return [
                'status' => Appointment::STATUS_IN_PROGRESS,
                'confirmed_start_at' => now()->addDay(),
            ];
        });
    }

    public function completed(): static
    {
        return $this->state(function (): array {
            return [
                'status' => Appointment::STATUS_COMPLETED,
                'confirmed_start_at' => now()->subHours(2),
                'completed_at' => now(),
            ];
        });
    }

    public function cancelled(): static
    {
        return $this->state(function (): array {
            return [
                'status' => Appointment::STATUS_CANCELLED,
                'cancelled_by' => 'manager',
                'cancellation_reason' => 'إلغاء تجريبي.',
                'cancelled_at' => now(),
            ];
        });
    }
}
