<?php

namespace Tests\Feature\Api\Admin;

use App\Models\CatalogItem;
use App\Models\Category;
use App\Models\Department;
use App\Models\PackageItem;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class PackageItemControllerTest extends TestCase
{
    use RefreshDatabase;

    private Department $salon;

    private Department $clinic;

    private Category $salonCategory;

    private Category $clinicCategory;

    private CatalogItem $package;

    private CatalogItem $service;

    protected function setUp(): void
    {
        parent::setUp();

        app(PermissionRegistrar::class)->forgetCachedPermissions();

        Role::findOrCreate('manager', 'web');
        Role::findOrCreate('customer', 'web');

        $this->salon = Department::query()->create([
            'code' => Department::SALON,
            'name' => 'الصالون',
            'is_active' => true,
            'sort_order' => 1,
        ]);

        $this->clinic = Department::query()->create([
            'code' => Department::CLINIC,
            'name' => 'العيادة',
            'is_active' => true,
            'sort_order' => 2,
        ]);

        $this->salonCategory = Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'بكجات العرايس',
            'is_active' => true,
        ]);

        $this->clinicCategory = Category::query()->create([
            'department_id' => $this->clinic->id,
            'name' => 'الفيلر',
            'is_active' => true,
        ]);

        $this->package = $this->createPackage(
            $this->salonCategory,
            'باكج العروس'
        );

        $this->service = $this->createService(
            $this->salonCategory,
            'مكياج'
        );
    }

    public function test_unauthenticated_user_cannot_manage_package_contents(): void
    {
        $this->getJson(
            "/api/admin/packages/{$this->package->id}/items"
        )->assertUnauthorized();

        $this->postJson(
            "/api/admin/packages/{$this->package->id}/items",
            [
                'service_id' => $this->service->id,
                'quantity' => 1,
            ]
        )->assertUnauthorized();
    }

    public function test_customer_cannot_manage_package_contents(): void
    {
        $customer = $this->createUser('customer', [
            'email' => 'customer@example.com',
            'phone' => '07700000002',
        ]);

        Sanctum::actingAs($customer, ['admin']);

        $this->getJson(
            "/api/admin/packages/{$this->package->id}/items"
        )->assertForbidden();

        $this->postJson(
            "/api/admin/packages/{$this->package->id}/items",
            [
                'service_id' => $this->service->id,
                'quantity' => 1,
            ]
        )->assertForbidden();
    }

    public function test_manager_can_list_package_contents(): void
    {
        $this->actingAsManager();

        $secondService = $this->createService(
            $this->salonCategory,
            'تسريحة'
        );

        $firstItem = PackageItem::query()->create([
            'package_id' => $this->package->id,
            'service_id' => $this->service->id,
            'quantity' => 1,
            'notes' => 'مكياج كامل',
        ]);

        $secondItem = PackageItem::query()->create([
            'package_id' => $this->package->id,
            'service_id' => $secondService->id,
            'quantity' => 1,
            'notes' => null,
        ]);

        $response = $this->getJson(
            "/api/admin/packages/{$this->package->id}/items"
        );

        $response
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $firstItem->id)
            ->assertJsonPath('data.0.service.id', $this->service->id)
            ->assertJsonPath('data.0.quantity', 1)
            ->assertJsonPath('data.0.notes', 'مكياج كامل')
            ->assertJsonPath('data.1.id', $secondItem->id)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'service' => [
                            'id',
                            'name',
                            'type',
                            'price_type',
                            'price',
                            'duration_minutes',
                            'is_active',
                        ],
                        'quantity',
                        'notes',
                        'created_at',
                        'updated_at',
                    ],
                ],
            ]);
    }

    public function test_manager_can_add_service_to_package(): void
    {
        $this->actingAsManager();

        $response = $this->postJson(
            "/api/admin/packages/{$this->package->id}/items",
            [
                'service_id' => $this->service->id,
                'quantity' => 1,
                'notes' => 'الخدمة مشمولة بالكامل',
            ]
        );

        $response
            ->assertCreated()
            ->assertJsonPath(
                'message',
                'تمت إضافة الخدمة إلى الباكج بنجاح.'
            )
            ->assertJsonPath('data.service.id', $this->service->id)
            ->assertJsonPath('data.service.name', 'مكياج')
            ->assertJsonPath('data.quantity', 1)
            ->assertJsonPath(
                'data.notes',
                'الخدمة مشمولة بالكامل'
            );

        $this->assertDatabaseHas('package_items', [
            'package_id' => $this->package->id,
            'service_id' => $this->service->id,
            'quantity' => 1,
            'notes' => 'الخدمة مشمولة بالكامل',
        ]);
    }

    public function test_manager_can_update_package_item(): void
    {
        $this->actingAsManager();

        $packageItem = PackageItem::query()->create([
            'package_id' => $this->package->id,
            'service_id' => $this->service->id,
            'quantity' => 1,
            'notes' => null,
        ]);

        $response = $this->patchJson(
            "/api/admin/packages/{$this->package->id}"
            ."/items/{$packageItem->id}",
            [
                'quantity' => 2,
                'notes' => 'مرتان ضمن الباكج',
            ]
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم تحديث محتوى الباكج بنجاح.'
            )
            ->assertJsonPath('data.quantity', 2)
            ->assertJsonPath('data.notes', 'مرتان ضمن الباكج');

        $this->assertDatabaseHas('package_items', [
            'id' => $packageItem->id,
            'quantity' => 2,
            'notes' => 'مرتان ضمن الباكج',
        ]);
    }

    public function test_manager_can_remove_service_from_package(): void
    {
        $this->actingAsManager();

        $packageItem = PackageItem::query()->create([
            'package_id' => $this->package->id,
            'service_id' => $this->service->id,
            'quantity' => 1,
        ]);

        $response = $this->deleteJson(
            "/api/admin/packages/{$this->package->id}"
            ."/items/{$packageItem->id}"
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم حذف الخدمة من الباكج بنجاح.'
            );

        $this->assertDatabaseMissing('package_items', [
            'id' => $packageItem->id,
        ]);
    }

    public function test_same_service_cannot_be_added_twice_to_same_package(): void
    {
        $this->actingAsManager();

        PackageItem::query()->create([
            'package_id' => $this->package->id,
            'service_id' => $this->service->id,
            'quantity' => 1,
        ]);

        $response = $this->postJson(
            "/api/admin/packages/{$this->package->id}/items",
            [
                'service_id' => $this->service->id,
                'quantity' => 1,
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['service_id']);

        $this->assertDatabaseCount('package_items', 1);
    }

    public function test_service_from_different_department_cannot_be_added(): void
    {
        $this->actingAsManager();

        $clinicService = $this->createService(
            $this->clinicCategory,
            'الفيلر الكوري'
        );

        $response = $this->postJson(
            "/api/admin/packages/{$this->package->id}/items",
            [
                'service_id' => $clinicService->id,
                'quantity' => 1,
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['service_id']);

        $this->assertDatabaseCount('package_items', 0);
    }

    public function test_package_cannot_be_added_as_service(): void
    {
        $this->actingAsManager();

        $anotherPackage = $this->createPackage(
            $this->salonCategory,
            'باكج آخر'
        );

        $response = $this->postJson(
            "/api/admin/packages/{$this->package->id}/items",
            [
                'service_id' => $anotherPackage->id,
                'quantity' => 1,
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['service_id']);
    }

    public function test_service_cannot_be_used_as_package_route_parent(): void
    {
        $this->actingAsManager();

        $response = $this->getJson(
            "/api/admin/packages/{$this->service->id}/items"
        );

        $response
            ->assertUnprocessable()
            ->assertJsonPath(
                'message',
                'العنصر المحدد ليس باكج.'
            );
    }

    public function test_package_item_from_another_package_cannot_be_modified(): void
    {
        $this->actingAsManager();

        $otherPackage = $this->createPackage(
            $this->salonCategory,
            'باكج آخر'
        );

        $packageItem = PackageItem::query()->create([
            'package_id' => $otherPackage->id,
            'service_id' => $this->service->id,
            'quantity' => 1,
        ]);

        $this->patchJson(
            "/api/admin/packages/{$this->package->id}"
            ."/items/{$packageItem->id}",
            [
                'quantity' => 2,
            ]
        )->assertNotFound();

        $this->deleteJson(
            "/api/admin/packages/{$this->package->id}"
            ."/items/{$packageItem->id}"
        )->assertNotFound();
    }

    public function test_store_validation_rejects_invalid_data(): void
    {
        $this->actingAsManager();

        $response = $this->postJson(
            "/api/admin/packages/{$this->package->id}/items",
            [
                'service_id' => 999999,
                'quantity' => 0,
                'notes' => str_repeat('a', 2001),
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'service_id',
                'quantity',
                'notes',
            ]);
    }

    public function test_update_validation_rejects_invalid_data(): void
    {
        $this->actingAsManager();

        $packageItem = PackageItem::query()->create([
            'package_id' => $this->package->id,
            'service_id' => $this->service->id,
            'quantity' => 1,
        ]);

        $response = $this->patchJson(
            "/api/admin/packages/{$this->package->id}"
            ."/items/{$packageItem->id}",
            [
                'quantity' => 0,
                'notes' => str_repeat('a', 2001),
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'quantity',
                'notes',
            ]);
    }

    private function actingAsManager(): User
    {
        $manager = $this->createUser('manager');

        Sanctum::actingAs($manager, ['admin']);

        return $manager;
    }

    /**
     * @param array<string, mixed> $attributes
     */
    private function createUser(
        string $role,
        array $attributes = []
    ): User {
        $user = User::query()->create(array_merge([
            'name' => 'Grand Layan User',
            'email' => 'manager@example.com',
            'phone' => '07700000001',
            'password' => 'Password123!',
            'is_active' => true,
        ], $attributes));

        $user->assignRole($role);

        return $user;
    }

    private function createService(
        Category $category,
        string $name
    ): CatalogItem {
        return CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => $name,
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 50000,
            'duration_minutes' => 60,
            'is_active' => true,
        ]);
    }

    private function createPackage(
        Category $category,
        string $name
    ): CatalogItem {
        return CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_PACKAGE,
            'name' => $name,
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 350000,
            'duration_minutes' => 180,
            'is_active' => true,
        ]);
    }
}