<?php

namespace Tests\Feature\Appointments;

use App\Models\CatalogItem;
use App\Models\Category;
use App\Models\Department;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class AppointmentDatabaseConstraintsTest extends TestCase
{
    use RefreshDatabase;

    private static int $referenceSequence = 1;

    public function test_appointment_rejects_unsupported_status(): void
    {
        [$customer, $department] = $this->createCustomerAndDepartment();

        $this->expectException(QueryException::class);

        DB::table('appointments')->insert(
            $this->appointmentPayload(
                customerId: $customer->id,
                departmentId: $department->id,
                status: 'invalid_status',
            )
        );
    }

    public function test_appointment_accepts_supported_status(): void
    {
        [$customer, $department] = $this->createCustomerAndDepartment();

        $appointmentId = DB::table('appointments')->insertGetId(
            $this->appointmentPayload(
                customerId: $customer->id,
                departmentId: $department->id,
                status: 'pending',
            )
        );

        $this->assertDatabaseHas('appointments', [
            'id' => $appointmentId,
            'status' => 'pending',
        ]);
    }

    public function test_appointment_rejects_unsupported_cancelled_by_value(): void
    {
        [$customer, $department] = $this->createCustomerAndDepartment();

        $payload = $this->appointmentPayload(
            customerId: $customer->id,
            departmentId: $department->id,
        );

        $payload['cancelled_by'] = 'employee';

        $this->expectException(QueryException::class);

        DB::table('appointments')->insert($payload);
    }

    public function test_same_catalog_item_cannot_be_added_twice_to_appointment(): void
    {
        [$appointmentId, $catalogItem] = $this->createAppointmentAndService();

        DB::table('appointment_items')->insert(
            $this->appointmentItemPayload(
                appointmentId: $appointmentId,
                catalogItem: $catalogItem,
            )
        );

        $this->expectException(QueryException::class);

        DB::table('appointment_items')->insert(
            $this->appointmentItemPayload(
                appointmentId: $appointmentId,
                catalogItem: $catalogItem,
            )
        );
    }

    public function test_fixed_price_appointment_item_requires_price(): void
    {
        [$appointmentId, $catalogItem] = $this->createAppointmentAndService();

        $payload = $this->appointmentItemPayload(
            appointmentId: $appointmentId,
            catalogItem: $catalogItem,
        );

        $payload['price_type'] = 'fixed';
        $payload['unit_price'] = null;

        $this->expectException(QueryException::class);

        DB::table('appointment_items')->insert($payload);
    }

    public function test_fixed_price_appointment_item_rejects_negative_price(): void
    {
        [$appointmentId, $catalogItem] = $this->createAppointmentAndService();

        $payload = $this->appointmentItemPayload(
            appointmentId: $appointmentId,
            catalogItem: $catalogItem,
        );

        $payload['price_type'] = 'fixed';
        $payload['unit_price'] = -1;

        $this->expectException(QueryException::class);

        DB::table('appointment_items')->insert($payload);
    }

    public function test_inspection_appointment_item_must_not_store_price(): void
    {
        [$appointmentId, $catalogItem] = $this->createAppointmentAndService();

        $payload = $this->appointmentItemPayload(
            appointmentId: $appointmentId,
            catalogItem: $catalogItem,
        );

        $payload['price_type'] = 'inspection';
        $payload['unit_price'] = 25000;

        $this->expectException(QueryException::class);

        DB::table('appointment_items')->insert($payload);
    }

    public function test_appointment_item_quantity_must_be_greater_than_zero(): void
    {
        [$appointmentId, $catalogItem] = $this->createAppointmentAndService();

        $payload = $this->appointmentItemPayload(
            appointmentId: $appointmentId,
            catalogItem: $catalogItem,
        );

        $payload['quantity'] = 0;

        $this->expectException(QueryException::class);

        DB::table('appointment_items')->insert($payload);
    }

    public function test_appointment_item_duration_must_be_greater_than_zero_when_present(): void
    {
        [$appointmentId, $catalogItem] = $this->createAppointmentAndService();

        $payload = $this->appointmentItemPayload(
            appointmentId: $appointmentId,
            catalogItem: $catalogItem,
        );

        $payload['duration_minutes'] = 0;

        $this->expectException(QueryException::class);

        DB::table('appointment_items')->insert($payload);
    }

    public function test_appointment_service_quantity_must_be_greater_than_zero(): void
    {
        [$appointmentItemId, $service] = $this->createAppointmentItemAndService();

        $payload = $this->appointmentServicePayload(
            appointmentItemId: $appointmentItemId,
            service: $service,
        );

        $payload['quantity'] = 0;

        $this->expectException(QueryException::class);

        DB::table('appointment_services')->insert($payload);
    }

    public function test_appointment_service_duration_must_be_greater_than_zero(): void
    {
        [$appointmentItemId, $service] = $this->createAppointmentItemAndService();

        $payload = $this->appointmentServicePayload(
            appointmentItemId: $appointmentItemId,
            service: $service,
        );

        $payload['duration_minutes'] = 0;

        $this->expectException(QueryException::class);

        DB::table('appointment_services')->insert($payload);
    }

    public function test_appointment_service_rejects_negative_price(): void
    {
        [$appointmentItemId, $service] = $this->createAppointmentItemAndService();

        $payload = $this->appointmentServicePayload(
            appointmentItemId: $appointmentItemId,
            service: $service,
        );

        $payload['unit_price'] = -1;

        $this->expectException(QueryException::class);

        DB::table('appointment_services')->insert($payload);
    }

    public function test_scheduled_end_must_be_after_scheduled_start(): void
    {
        [$appointmentItemId, $service] = $this->createAppointmentItemAndService();

        $payload = $this->appointmentServicePayload(
            appointmentItemId: $appointmentItemId,
            service: $service,
        );

        $payload['scheduled_start_at'] = now()->addDay();
        $payload['scheduled_end_at'] = now()->addDay()->subMinute();

        $this->expectException(QueryException::class);

        DB::table('appointment_services')->insert($payload);
    }

    public function test_same_service_cannot_be_repeated_inside_same_appointment_item(): void
    {
        [$appointmentItemId, $service] = $this->createAppointmentItemAndService();

        DB::table('appointment_services')->insert(
            $this->appointmentServicePayload(
                appointmentItemId: $appointmentItemId,
                service: $service,
            )
        );

        $this->expectException(QueryException::class);

        DB::table('appointment_services')->insert(
            $this->appointmentServicePayload(
                appointmentItemId: $appointmentItemId,
                service: $service,
            )
        );
    }

    public function test_package_cannot_be_used_as_executable_appointment_service(): void
    {
        [$appointmentItemId, $service] = $this->createAppointmentItemAndService();

        $package = CatalogItem::factory()->create([
            'category_id' => $service->category_id,
            'type' => CatalogItem::TYPE_PACKAGE,
            'name' => 'باكج غير صالح كخدمة تنفيذية',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 100000,
            'duration_minutes' => null,
            'is_active' => true,
        ]);

        $this->expectException(QueryException::class);

        DB::table('appointment_services')->insert(
            $this->appointmentServicePayload(
                appointmentItemId: $appointmentItemId,
                service: $package,
            )
        );
    }

    /**
     * @return array{0: User, 1: Department}
     */
    private function createCustomerAndDepartment(): array
    {
        $customer = User::factory()->create([
            'is_active' => true,
        ]);

        $department = Department::factory()->create([
            'code' => 'salon',
            'name' => 'الصالون',
            'is_active' => true,
        ]);

        return [$customer, $department];
    }

    /**
     * @return array{0: int, 1: CatalogItem}
     */
    private function createAppointmentAndService(): array
    {
        [$customer, $department] = $this->createCustomerAndDepartment();

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

        $appointmentId = DB::table('appointments')->insertGetId(
            $this->appointmentPayload(
                customerId: $customer->id,
                departmentId: $department->id,
            )
        );

        return [$appointmentId, $service];
    }

    /**
     * @return array{0: int, 1: CatalogItem}
     */
    private function createAppointmentItemAndService(): array
    {
        [$appointmentId, $service] = $this->createAppointmentAndService();

        $appointmentItemId = DB::table('appointment_items')->insertGetId(
            $this->appointmentItemPayload(
                appointmentId: $appointmentId,
                catalogItem: $service,
            )
        );

        return [$appointmentItemId, $service];
    }

    /**
     * @return array<string, mixed>
     */
    private function appointmentPayload(
        int $customerId,
        int $departmentId,
        string $status = 'pending',
    ): array {
        $reference = 'GL-TEST-'
            .str_pad(
                (string) self::$referenceSequence++,
                6,
                '0',
                STR_PAD_LEFT
            );

        return [
            'reference' => $reference,
            'customer_id' => $customerId,
            'department_id' => $departmentId,
            'status' => $status,
            'requested_start_at' => now()->addDay(),
            'confirmed_start_at' => null,
            'customer_notes' => null,
            'admin_notes' => null,
            'cancelled_by' => null,
            'cancellation_reason' => null,
            'cancelled_at' => null,
            'completed_at' => null,
            'no_show_at' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function appointmentItemPayload(
        int $appointmentId,
        CatalogItem $catalogItem,
    ): array {
        return [
            'appointment_id' => $appointmentId,
            'catalog_item_id' => $catalogItem->id,
            'item_type' => $catalogItem->type,
            'item_name' => $catalogItem->name,
            'price_type' => $catalogItem->price_type,
            'unit_price' => $catalogItem->price,
            'quantity' => 1,
            'duration_minutes' => $catalogItem->duration_minutes,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function appointmentServicePayload(
        int $appointmentItemId,
        CatalogItem $service,
    ): array {
        return [
            'appointment_item_id' => $appointmentItemId,
            'service_id' => $service->id,
            'service_name' => $service->name,
            'quantity' => 1,
            'duration_minutes' => $service->duration_minutes ?? 30,
            'unit_price' => $service->price,
            'scheduled_start_at' => null,
            'scheduled_end_at' => null,
            'notes' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
