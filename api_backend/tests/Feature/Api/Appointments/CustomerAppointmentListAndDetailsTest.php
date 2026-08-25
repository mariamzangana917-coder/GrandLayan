<?php

namespace Tests\Feature\Api\Appointments;

use App\Models\Appointment;
use App\Models\CatalogItem;
use App\Models\Category;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class CustomerAppointmentListAndDetailsTest extends TestCase
{
    use RefreshDatabase;

    private Role $customerRole;
    private Role $managerRole;

    protected function setUp(): void
    {
        parent::setUp();

        $this->customerRole = Role::create([
            'name' => 'customer',
            'guard_name' => 'web',
        ]);

        $this->managerRole = Role::create([
            'name' => 'manager',
            'guard_name' => 'web',
        ]);
    }

    public function test_guest_cannot_access_appointments_list(): void
    {
        $response = $this->getJson('/api/appointments');
        $response->assertUnauthorized();
    }

    public function test_manager_cannot_access_customer_appointments_route(): void
    {
        $manager = User::factory()->create(['is_active' => true]);
        $manager->assignRole($this->managerRole);

        Sanctum::actingAs($manager);

        $response = $this->getJson('/api/appointments');
        $response->assertForbidden();
    }

    public function test_customer_can_list_their_appointments_only(): void
    {
        $customerA = User::factory()->create(['is_active' => true]);
        $customerA->assignRole($this->customerRole);

        $customerB = User::factory()->create(['is_active' => true]);
        $customerB->assignRole($this->customerRole);

        $department = Department::factory()->salon()->create();

        $appointmentA1 = Appointment::factory()->create([
            'customer_id' => $customerA->id,
            'department_id' => $department->id,
            'reference' => 'GL-20260822-AAA1',
            'requested_start_at' => now()->addDays(2),
            'status' => Appointment::STATUS_PENDING,
        ]);

        $appointmentA2 = Appointment::factory()->create([
            'customer_id' => $customerA->id,
            'department_id' => $department->id,
            'reference' => 'GL-20260822-AAA2',
            'requested_start_at' => now()->addDays(3),
            'status' => Appointment::STATUS_CONFIRMED,
        ]);

        $appointmentB = Appointment::factory()->create([
            'customer_id' => $customerB->id,
            'department_id' => $department->id,
            'reference' => 'GL-20260822-BBB1',
            'requested_start_at' => now()->addDays(2),
            'status' => Appointment::STATUS_PENDING,
        ]);

        Sanctum::actingAs($customerA);

        $response = $this->getJson('/api/appointments');

        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.customer.id', $customerA->id)
            ->assertJsonPath('data.1.customer.id', $customerA->id);

        $returnedReferences = collect($response->json('data'))->pluck('reference')->all();
        $this->assertContains('GL-20260822-AAA1', $returnedReferences);
        $this->assertContains('GL-20260822-AAA2', $returnedReferences);
        $this->assertNotContains('GL-20260822-BBB1', $returnedReferences);
    }

    public function test_customer_can_view_single_appointment_details(): void
    {
        $customer = User::factory()->create(['is_active' => true]);
        $customer->assignRole($this->customerRole);

        $department = Department::factory()->salon()->create();
        $category = Category::factory()->create(['department_id' => $department->id]);
        $service = CatalogItem::factory()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'تنظيف بشرة',
            'price' => 50000,
            'duration_minutes' => 45,
        ]);

        $appointment = Appointment::factory()->create([
            'customer_id' => $customer->id,
            'department_id' => $department->id,
            'reference' => 'GL-20260822-DET1',
            'requested_start_at' => now()->addDays(2),
            'subtotal_amount' => 50000,
            'discount_amount' => 0,
            'final_amount' => 50000,
            'status' => Appointment::STATUS_PENDING,
        ]);

        $item = $appointment->items()->create([
            'catalog_item_id' => $service->id,
            'item_type' => CatalogItem::TYPE_SERVICE,
            'item_name' => $service->name,
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'unit_price' => 50000,
            'quantity' => 1,
            'duration_minutes' => 45,
        ]);

        $item->services()->create([
            'service_id' => $service->id,
            'service_name' => $service->name,
            'quantity' => 1,
            'duration_minutes' => 45,
            'unit_price' => 50000,
        ]);

        Sanctum::actingAs($customer);

        $response = $this->getJson("/api/appointments/{$appointment->id}");

        $response->assertOk()
            ->assertJsonPath('data.id', $appointment->id)
            ->assertJsonPath('data.reference', 'GL-20260822-DET1')
            ->assertJsonPath('data.department.name', $department->name)
            ->assertJsonPath('data.items.0.item_name', 'تنظيف بشرة')
            ->assertJsonPath('data.items.0.services.0.duration_minutes', 45);
    }

    public function test_customer_cannot_view_another_customers_appointment(): void
    {
        $customerA = User::factory()->create(['is_active' => true]);
        $customerA->assignRole($this->customerRole);

        $customerB = User::factory()->create(['is_active' => true]);
        $customerB->assignRole($this->customerRole);

        $department = Department::factory()->salon()->create();

        $appointmentB = Appointment::factory()->create([
            'customer_id' => $customerB->id,
            'department_id' => $department->id,
            'reference' => 'GL-20260822-PRIV',
            'requested_start_at' => now()->addDays(2),
            'status' => Appointment::STATUS_PENDING,
        ]);

        Sanctum::actingAs($customerA);

        $response = $this->getJson("/api/appointments/{$appointmentB->id}");
        $response->assertNotFound();
    }

    public function test_customer_can_cancel_their_pending_appointment(): void
    {
        $customer = User::factory()->create(['is_active' => true]);
        $customer->assignRole($this->customerRole);

        $department = Department::factory()->salon()->create();

        $appointment = Appointment::factory()->create([
            'customer_id' => $customer->id,
            'department_id' => $department->id,
            'reference' => 'GL-20260822-CNC1',
            'requested_start_at' => now()->addDays(2),
            'status' => Appointment::STATUS_PENDING,
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson("/api/appointments/{$appointment->id}/cancel", [
            'reason' => 'طرأ ظرف طارئ يمنعني من الحضور.',
        ]);

        $response->assertOk()
            ->assertJsonPath('message', 'تم إلغاء الموعد بنجاح.')
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.cancelled_by', 'customer')
            ->assertJsonPath('data.cancellation_reason', 'طرأ ظرف طارئ يمنعني من الحضور.');

        $this->assertDatabaseHas('appointments', [
            'id' => $appointment->id,
            'status' => Appointment::STATUS_CANCELLED,
            'cancelled_by' => 'customer',
            'cancellation_reason' => 'طرأ ظرف طارئ يمنعني من الحضور.',
        ]);
    }

    public function test_customer_cannot_cancel_another_customers_appointment(): void
    {
        $customerA = User::factory()->create(['is_active' => true]);
        $customerA->assignRole($this->customerRole);

        $customerB = User::factory()->create(['is_active' => true]);
        $customerB->assignRole($this->customerRole);

        $department = Department::factory()->salon()->create();

        $appointmentB = Appointment::factory()->create([
            'customer_id' => $customerB->id,
            'department_id' => $department->id,
            'reference' => 'GL-20260822-CNC2',
            'requested_start_at' => now()->addDays(2),
            'status' => Appointment::STATUS_PENDING,
        ]);

        Sanctum::actingAs($customerA);

        $response = $this->postJson("/api/appointments/{$appointmentB->id}/cancel", [
            'reason' => 'محاولة إلغاء غير مصرح بها',
        ]);

        $response->assertNotFound();

        $this->assertDatabaseHas('appointments', [
            'id' => $appointmentB->id,
            'status' => Appointment::STATUS_PENDING,
        ]);
    }

    public function test_customer_cannot_cancel_completed_appointment(): void
    {
        $customer = User::factory()->create(['is_active' => true]);
        $customer->assignRole($this->customerRole);

        $department = Department::factory()->salon()->create();

        $appointment = Appointment::factory()->create([
            'customer_id' => $customer->id,
            'department_id' => $department->id,
            'reference' => 'GL-20260822-CNC3',
            'requested_start_at' => now()->subDays(1),
            'status' => Appointment::STATUS_COMPLETED,
            'completed_at' => now()->subHours(5),
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson("/api/appointments/{$appointment->id}/cancel", [
            'reason' => 'محاولة إلغاء موعد مكتمل',
        ]);

        $response->assertUnprocessable();
    }
}
