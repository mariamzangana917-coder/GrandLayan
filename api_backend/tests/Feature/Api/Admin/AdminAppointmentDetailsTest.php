<?php

namespace Tests\Feature\Api\Admin;

use App\Models\Appointment;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminAppointmentDetailsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager');
        Role::findOrCreate('customer');
    }

    public function test_guest_cannot_view_appointment_details(): void
    {
        $appointment = Appointment::factory()->create();

        $this->getJson(
            "/api/admin/appointments/{$appointment->id}"
        )->assertUnauthorized();
    }

    public function test_customer_cannot_view_admin_appointment_details(): void
    {
        $customer = User::factory()->create();
        $customer->assignRole('customer');

        $appointment = Appointment::factory()->create();

        Sanctum::actingAs($customer);

        $this->getJson(
            "/api/admin/appointments/{$appointment->id}"
        )->assertForbidden();
    }

    public function test_manager_can_view_appointment_details(): void
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        $customer = User::factory()->create([
            'name' => 'سارة أحمد',
        ]);
        $customer->assignRole('customer');

        $department = Department::factory()->create();

        $appointment = Appointment::factory()->create([
            'customer_id' => $customer->id,
            'department_id' => $department->id,
            'status' => Appointment::STATUS_PENDING,
        ]);

        Sanctum::actingAs($manager);

        $this->getJson(
            "/api/admin/appointments/{$appointment->id}"
        )
            ->assertOk()
            ->assertJsonPath(
                'data.id',
                $appointment->id
            )
            ->assertJsonPath(
                'data.customer.name',
                'سارة أحمد'
            )
            ->assertJsonPath(
                'data.status',
                Appointment::STATUS_PENDING
            );
    }

    public function test_unknown_appointment_returns_not_found(): void
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        Sanctum::actingAs($manager);

        $this->getJson(
            '/api/admin/appointments/999999'
        )->assertNotFound();
    }
}