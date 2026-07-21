<?php

namespace Tests\Feature\Api\Admin;

use App\Models\Appointment;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminAppointmentControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $manager;

    private User $customer;

    private Department $salon;

    private Department $clinic;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager');
        Role::findOrCreate('customer');

        $this->manager = User::factory()->create();
        $this->manager->assignRole('manager');

        $this->customer = User::factory()->create([
            'name' => 'سارة أحمد',
            'phone' => '07700000001',
        ]);
        $this->customer->assignRole('customer');

        $this->salon = Department::factory()->create([
            'code' => 'salon',
            'name' => 'الصالون',
        ]);

        $this->clinic = Department::factory()->create([
            'code' => 'clinic',
            'name' => 'العيادة',
        ]);

        Sanctum::actingAs($this->manager);
    }

    public function test_manager_can_search_filter_and_paginate_appointments(): void
    {
        Appointment::factory()->create([
            'customer_id' => $this->customer->id,
            'department_id' => $this->salon->id,
            'reference' => 'GL-SEARCH-001',
            'status' => Appointment::STATUS_PENDING,
            'requested_start_at' => now()->addDays(2),
        ]);

        Appointment::factory()->confirmed()->create([
            'customer_id' => $this->customer->id,
            'department_id' => $this->clinic->id,
            'reference' => 'GL-OTHER-001',
            'requested_start_at' => now()->addDays(3),
            'confirmed_start_at' => now()->addDays(3),
        ]);

        $response = $this->getJson(
            '/api/admin/appointments?search=SEARCH'
            .'&status=pending'
            ."&department_id={$this->salon->id}"
            .'&per_page=1'
        );

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.reference', 'GL-SEARCH-001')
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonPath('meta.total', 1);
    }

    public function test_customer_cannot_manage_admin_appointments(): void
    {
        Sanctum::actingAs($this->customer);

        $appointment = $this->pendingAppointment();

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/confirm"
        )->assertForbidden();
    }

    public function test_manager_can_confirm_pending_appointment(): void
    {
        $appointment = $this->pendingAppointment();
        $confirmedAt = now()->addDays(2)->startOfMinute();

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/confirm",
            ['confirmed_start_at' => $confirmedAt->toISOString()]
        )
            ->assertOk()
            ->assertJsonPath('data.status', Appointment::STATUS_CONFIRMED);

        $this->assertDatabaseHas('appointments', [
            'id' => $appointment->id,
            'status' => Appointment::STATUS_CONFIRMED,
        ]);
    }

    public function test_manager_can_edit_pending_or_confirmed_appointment(): void
    {
        $appointment = $this->pendingAppointment();
        $newStart = now()->addDays(4)->startOfMinute();

        $this->patchJson(
            "/api/admin/appointments/{$appointment->id}",
            [
                'requested_start_at' => $newStart->toISOString(),
                'admin_notes' => 'تعديل إداري',
            ]
        )
            ->assertOk()
            ->assertJsonPath('data.admin_notes', 'تعديل إداري');

        $this->assertDatabaseHas('appointments', [
            'id' => $appointment->id,
            'admin_notes' => 'تعديل إداري',
        ]);
    }

    public function test_manager_can_start_and_complete_confirmed_appointment(): void
    {
        $appointment = Appointment::factory()->confirmed()->create([
            'customer_id' => $this->customer->id,
            'department_id' => $this->salon->id,
        ]);

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/start"
        )
            ->assertOk()
            ->assertJsonPath('data.status', Appointment::STATUS_IN_PROGRESS);

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/complete"
        )
            ->assertOk()
            ->assertJsonPath('data.status', Appointment::STATUS_COMPLETED)
            ->assertJsonPath('data.completed_at', fn ($value) => $value !== null);
    }

    public function test_manager_can_cancel_pending_appointment_with_reason(): void
    {
        $appointment = $this->pendingAppointment();

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/cancel",
            ['reason' => 'طلبت الزبونة الإلغاء']
        )
            ->assertOk()
            ->assertJsonPath('data.status', Appointment::STATUS_CANCELLED)
            ->assertJsonPath('data.cancelled_by', 'manager')
            ->assertJsonPath(
                'data.cancellation_reason',
                'طلبت الزبونة الإلغاء'
            );
    }

    public function test_manager_can_mark_past_confirmed_appointment_as_no_show(): void
    {
        $appointment = Appointment::factory()->confirmed()->create([
            'customer_id' => $this->customer->id,
            'department_id' => $this->salon->id,
            'requested_start_at' => now()->subHour(),
            'confirmed_start_at' => now()->subHour(),
        ]);

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/no-show"
        )
            ->assertOk()
            ->assertJsonPath('data.status', Appointment::STATUS_NO_SHOW)
            ->assertJsonPath('data.no_show_at', fn ($value) => $value !== null);
    }

    public function test_invalid_state_transition_is_rejected(): void
    {
        $appointment = Appointment::factory()->completed()->create([
            'customer_id' => $this->customer->id,
            'department_id' => $this->salon->id,
        ]);

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/confirm"
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
    }

    public function test_no_show_cannot_be_recorded_before_appointment_time(): void
    {
        $appointment = Appointment::factory()->confirmed()->create([
            'customer_id' => $this->customer->id,
            'department_id' => $this->salon->id,
            'requested_start_at' => now()->addDay(),
            'confirmed_start_at' => now()->addDay(),
        ]);

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/no-show"
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
    }

    public function test_cancellation_reason_is_required(): void
    {
        $appointment = $this->pendingAppointment();

        $this->postJson(
            "/api/admin/appointments/{$appointment->id}/cancel"
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('reason');
    }

    private function pendingAppointment(): Appointment
    {
        return Appointment::factory()->create([
            'customer_id' => $this->customer->id,
            'department_id' => $this->salon->id,
            'status' => Appointment::STATUS_PENDING,
        ]);
    }
}
