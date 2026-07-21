<?php

namespace Tests\Feature\Api\Appointments;

use App\Models\CatalogItem;
use App\Models\Category;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class CreateAppointmentTest extends TestCase
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

    public function test_guest_cannot_create_appointment(): void
    {
        $response = $this->postJson('/api/appointments', []);

        $response->assertUnauthorized();
    }

    public function test_manager_cannot_use_customer_appointment_creation_route(): void
    {
        $manager = User::factory()->create([
            'is_active' => true,
        ]);

        $manager->assignRole($this->managerRole);

        Sanctum::actingAs($manager);

        $response = $this->postJson('/api/appointments', []);

        $response->assertForbidden();
    }

    public function test_inactive_customer_cannot_create_appointment(): void
    {
        $customer = User::factory()->inactive()->create();
        $customer->assignRole($this->customerRole);

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', []);

        $response->assertForbidden();
    }

    public function test_customer_can_create_appointment_with_single_service(): void
    {
        [$customer, $department, $service] =
            $this->createCustomerDepartmentAndService();

        Sanctum::actingAs($customer);

        $requestedStartAt = now()
            ->addDays(2)
            ->setTime(10, 0)
            ->toIso8601String();

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => $requestedStartAt,
            'customer_notes' => 'أفضل الموعد صباحًا.',
            'items' => [
                [
                    'catalog_item_id' => $service->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.customer.id', $customer->id)
            ->assertJsonPath('data.department.id', $department->id)
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath(
                'data.items.0.catalog_item_id',
                $service->id
            )
            ->assertJsonPath(
                'data.items.0.item_name',
                $service->name
            )
            ->assertJsonPath(
                'data.items.0.unit_price',
                '25000.00'
            )
            ->assertJsonPath(
                'data.items.0.duration_minutes',
                30
            );

        $this->assertDatabaseHas('appointments', [
            'customer_id' => $customer->id,
            'department_id' => $department->id,
            'status' => 'pending',
            'customer_notes' => 'أفضل الموعد صباحًا.',
        ]);

        $appointmentId = DB::table('appointments')
            ->where('customer_id', $customer->id)
            ->value('id');

        $this->assertDatabaseHas('appointment_items', [
            'appointment_id' => $appointmentId,
            'catalog_item_id' => $service->id,
            'item_type' => CatalogItem::TYPE_SERVICE,
            'item_name' => $service->name,
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'unit_price' => '25000.00',
            'quantity' => 1,
            'duration_minutes' => 30,
        ]);

        $this->assertDatabaseHas('appointment_services', [
            'service_id' => $service->id,
            'service_name' => $service->name,
            'quantity' => 1,
            'duration_minutes' => 30,
            'unit_price' => '25000.00',
        ]);
    }

    public function test_customer_can_create_appointment_with_multiple_services(): void
    {
        [$customer, $department, $firstService] =
            $this->createCustomerDepartmentAndService();

        $secondService = CatalogItem::factory()->create([
            'category_id' => $firstService->category_id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'سشوار',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 45,
            'is_active' => true,
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->addDays(2)
                ->setTime(11, 0)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $firstService->id,
                    'quantity' => 1,
                ],
                [
                    'catalog_item_id' => $secondService->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertCreated()
            ->assertJsonCount(2, 'data.items');

        $this->assertDatabaseCount('appointments', 1);
        $this->assertDatabaseCount('appointment_items', 2);
        $this->assertDatabaseCount('appointment_services', 2);
    }

    public function test_package_is_expanded_into_executable_services(): void
    {
        [$customer, $department, $firstService] =
            $this->createCustomerDepartmentAndService();

        $secondService = CatalogItem::factory()->create([
            'category_id' => $firstService->category_id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'تسريحة',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 50000,
            'duration_minutes' => 60,
            'is_active' => true,
        ]);

        $package = CatalogItem::factory()->create([
            'category_id' => $firstService->category_id,
            'type' => CatalogItem::TYPE_PACKAGE,
            'name' => 'باكج العروس',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 350000,
            'duration_minutes' => null,
            'is_active' => true,
        ]);

        DB::table('package_items')->insert([
            [
                'package_id' => $package->id,
                'service_id' => $firstService->id,
                'quantity' => 1,
                'notes' => 'تنفيذ المكياج أولًا.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'package_id' => $package->id,
                'service_id' => $secondService->id,
                'quantity' => 1,
                'notes' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->addDays(3)
                ->setTime(12, 0)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $package->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath(
                'data.items.0.item_type',
                CatalogItem::TYPE_PACKAGE
            )
            ->assertJsonPath(
                'data.items.0.unit_price',
                '350000.00'
            )
            ->assertJsonCount(
                2,
                'data.items.0.services'
            );

        $this->assertDatabaseCount('appointments', 1);
        $this->assertDatabaseCount('appointment_items', 1);
        $this->assertDatabaseCount('appointment_services', 2);

        $this->assertDatabaseHas('appointment_services', [
            'service_id' => $firstService->id,
            'service_name' => $firstService->name,
            'unit_price' => null,
            'notes' => 'تنفيذ المكياج أولًا.',
        ]);

        $this->assertDatabaseHas('appointment_services', [
            'service_id' => $secondService->id,
            'service_name' => $secondService->name,
            'unit_price' => null,
        ]);
    }

    public function test_customer_cannot_book_item_from_another_department(): void
    {
        [$customer, $salon, $salonService] =
            $this->createCustomerDepartmentAndService();

        $clinic = Department::factory()->clinic()->create();

        $clinicCategory = Category::factory()->create([
            'department_id' => $clinic->id,
            'name' => 'الفيلر',
            'is_active' => true,
        ]);

        $clinicService = CatalogItem::factory()->create([
            'category_id' => $clinicCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'فيلر كوري',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 100000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $salon->id,
            'requested_start_at' => now()
                ->addDays(2)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $salonService->id,
                    'quantity' => 1,
                ],
                [
                    'catalog_item_id' => $clinicService->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items');

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_customer_cannot_book_inactive_catalog_item(): void
    {
        [$customer, $department, $service] =
            $this->createCustomerDepartmentAndService();

        $service->update([
            'is_active' => false,
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->addDays(2)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $service->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items.0.catalog_item_id');

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_customer_cannot_book_deleted_catalog_item(): void
    {
        [$customer, $department, $service] =
            $this->createCustomerDepartmentAndService();

        $service->delete();

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->addDays(2)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $service->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items.0.catalog_item_id');

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_customer_cannot_book_in_the_past(): void
    {
        [$customer, $department, $service] =
            $this->createCustomerDepartmentAndService();

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->subHour()
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $service->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('requested_start_at');

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_same_catalog_item_cannot_be_submitted_twice(): void
    {
        [$customer, $department, $service] =
            $this->createCustomerDepartmentAndService();

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->addDays(2)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $service->id,
                    'quantity' => 1,
                ],
                [
                    'catalog_item_id' => $service->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(
                'items.1.catalog_item_id'
            );

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_package_without_services_cannot_be_booked(): void
    {
        [$customer, $department, $service] =
            $this->createCustomerDepartmentAndService();

        $package = CatalogItem::factory()->create([
            'category_id' => $service->category_id,
            'type' => CatalogItem::TYPE_PACKAGE,
            'name' => 'باكج فارغ',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 100000,
            'duration_minutes' => null,
            'is_active' => true,
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->addDays(2)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $package->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items');

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_service_without_duration_cannot_be_booked(): void
    {
        [$customer, $department, $service] =
            $this->createCustomerDepartmentAndService();

        $service->update([
            'duration_minutes' => null,
        ]);

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->addDays(2)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $service->id,
                    'quantity' => 1,
                ],
            ],
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items');

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_backend_ignores_client_supplied_price_duration_and_customer(): void
    {
        [$customer, $department, $service] =
            $this->createCustomerDepartmentAndService();

        $otherCustomer = User::factory()->create([
            'is_active' => true,
        ]);
        $otherCustomer->assignRole($this->customerRole);

        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/appointments', [
            'customer_id' => $otherCustomer->id,
            'department_id' => $department->id,
            'requested_start_at' => now()
                ->addDays(2)
                ->toIso8601String(),
            'items' => [
                [
                    'catalog_item_id' => $service->id,
                    'quantity' => 1,
                    'unit_price' => 1,
                    'duration_minutes' => 1,
                ],
            ],
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath(
                'data.customer.id',
                $customer->id
            )
            ->assertJsonPath(
                'data.items.0.unit_price',
                '25000.00'
            )
            ->assertJsonPath(
                'data.items.0.duration_minutes',
                30
            );

        $this->assertDatabaseHas('appointments', [
            'customer_id' => $customer->id,
        ]);

        $this->assertDatabaseMissing('appointments', [
            'customer_id' => $otherCustomer->id,
        ]);
    }

    /**
     * @return array{0: User, 1: Department, 2: CatalogItem}
     */
    private function createCustomerDepartmentAndService(): array
    {
        $customer = User::factory()->create([
            'is_active' => true,
        ]);

        $customer->assignRole($this->customerRole);

        $department = Department::factory()->salon()->create();

        $category = Category::factory()->create([
            'department_id' => $department->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);

        $service = CatalogItem::factory()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص شعر',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);

        return [
            $customer,
            $department,
            $service,
        ];
    }
}
