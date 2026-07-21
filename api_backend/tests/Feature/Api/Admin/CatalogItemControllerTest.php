<?php

namespace Tests\Feature\Api\Admin;

use App\Models\CatalogItem;
use App\Models\Category;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class CatalogItemControllerTest extends TestCase
{
    use RefreshDatabase;

    private Department $salon;

    private Department $clinic;

    private Category $hairCategory;

    private Category $fillerCategory;

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

        $this->hairCategory = Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);

        $this->fillerCategory = Category::query()->create([
            'department_id' => $this->clinic->id,
            'name' => 'الفيلر',
            'is_active' => true,
        ]);
    }

    public function test_unauthenticated_user_cannot_access_catalog_items(): void
    {
        $this->getJson('/api/admin/catalog-items')
            ->assertUnauthorized();

        $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
        ])->assertUnauthorized();
    }

    public function test_customer_cannot_access_catalog_item_management(): void
    {
        $customer = $this->createUser('customer', [
            'email' => 'customer@example.com',
            'phone' => '07700000002',
        ]);

        Sanctum::actingAs($customer, ['admin']);

        $this->getJson('/api/admin/catalog-items')
            ->assertForbidden();

        $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
        ])->assertForbidden();
    }

    public function test_manager_can_list_catalog_items(): void
    {
        $this->actingAsManager();

        $haircut = $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'قص',
            'price' => 25000,
        ]);

        $filler = $this->createCatalogItem([
            'category_id' => $this->fillerCategory->id,
            'name' => 'الفيلر الكوري',
            'price' => 100000,
        ]);

        $response = $this->getJson('/api/admin/catalog-items');

        $response
            ->assertOk()
            ->assertJsonPath('data.0.id', $haircut->id)
            ->assertJsonPath('data.0.category.id', $this->hairCategory->id)
            ->assertJsonPath('data.0.department.code', Department::SALON)
            ->assertJsonPath('data.1.id', $filler->id)
            ->assertJsonPath('data.1.department.code', Department::CLINIC)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'category' => [
                            'id',
                            'name',
                        ],
                        'department' => [
                            'id',
                            'code',
                            'name',
                        ],
                        'type',
                        'name',
                        'description',
                        'instructions',
                        'price_type',
                        'price',
                        'duration_minutes',
                        'is_active',
                        'created_at',
                        'updated_at',
                    ],
                ],
            ]);
    }

    public function test_manager_can_filter_catalog_items_by_department(): void
    {
        $this->actingAsManager();

        $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'قص',
            'price' => 25000,
        ]);

        $this->createCatalogItem([
            'category_id' => $this->fillerCategory->id,
            'name' => 'الفيلر الكوري',
            'price' => 100000,
        ]);

        $response = $this->getJson(
            '/api/admin/catalog-items?department=salon'
        );

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'قص')
            ->assertJsonPath(
                'data.0.department.code',
                Department::SALON
            );
    }

    public function test_manager_can_filter_catalog_items_by_category(): void
    {
        $this->actingAsManager();

        $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'قص',
            'price' => 25000,
        ]);

        $this->createCatalogItem([
            'category_id' => $this->fillerCategory->id,
            'name' => 'الفيلر الكوري',
            'price' => 100000,
        ]);

        $response = $this->getJson(
            "/api/admin/catalog-items?category_id={$this->hairCategory->id}"
        );

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'قص');
    }

    public function test_manager_can_filter_catalog_items_by_type(): void
    {
        $this->actingAsManager();

        $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price' => 25000,
        ]);

        $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_PACKAGE,
            'name' => 'باكج العروس',
            'price' => 350000,
        ]);

        $response = $this->getJson(
            '/api/admin/catalog-items?type=package'
        );

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.type', CatalogItem::TYPE_PACKAGE)
            ->assertJsonPath('data.0.name', 'باكج العروس');
    }

    public function test_manager_can_filter_catalog_items_by_active_status(): void
    {
        $this->actingAsManager();

        $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'قص',
            'price' => 25000,
            'is_active' => true,
        ]);

        $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'خدمة متوقفة',
            'price' => 30000,
            'is_active' => false,
        ]);

        $response = $this->getJson(
            '/api/admin/catalog-items?is_active=false'
        );

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'خدمة متوقفة')
            ->assertJsonPath('data.0.is_active', false);
    }

    public function test_manager_can_create_fixed_price_service(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'description' => 'قص شعر مع سشوار',
            'instructions' => 'الحضور قبل الموعد بعشر دقائق',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 45,
            'is_active' => true,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath(
                'message',
                'تم إنشاء الخدمة بنجاح.'
            )
            ->assertJsonPath('data.name', 'قص')
            ->assertJsonPath('data.type', CatalogItem::TYPE_SERVICE)
            ->assertJsonPath(
                'data.price_type',
                CatalogItem::PRICE_TYPE_FIXED
            )
            ->assertJsonPath('data.price', '25000.00')
            ->assertJsonPath('data.department.code', Department::SALON);

        $this->assertDatabaseHas('catalog_items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 45,
            'is_active' => true,
            'deleted_at' => null,
        ]);
    }

    public function test_manager_can_create_inspection_price_service(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'صبغ',
            'price_type' => CatalogItem::PRICE_TYPE_INSPECTION,
            'price' => null,
            'duration_minutes' => 120,
            'is_active' => true,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.name', 'صبغ')
            ->assertJsonPath(
                'data.price_type',
                CatalogItem::PRICE_TYPE_INSPECTION
            )
            ->assertJsonPath('data.price', null);

        $this->assertDatabaseHas('catalog_items', [
            'category_id' => $this->hairCategory->id,
            'name' => 'صبغ',
            'price_type' => CatalogItem::PRICE_TYPE_INSPECTION,
            'price' => null,
        ]);
    }

    public function test_manager_can_create_package(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_PACKAGE,
            'name' => 'باكج العروس 350',
            'description' => 'ميك أب وتسريحة وأظافر ورموش وعدسات',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 350000,
            'duration_minutes' => 180,
            'is_active' => true,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath(
                'message',
                'تم إنشاء الباكج بنجاح.'
            )
            ->assertJsonPath('data.type', CatalogItem::TYPE_PACKAGE)
            ->assertJsonPath('data.name', 'باكج العروس 350');
    }

    public function test_fixed_price_item_requires_price(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => null,
            'duration_minutes' => 30,
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['price']);
    }

    public function test_inspection_price_item_must_not_have_price(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'صبغ',
            'price_type' => CatalogItem::PRICE_TYPE_INSPECTION,
            'price' => 50000,
            'duration_minutes' => 120,
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['price']);
    }

    public function test_catalog_item_rejects_negative_price(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => -1000,
            'duration_minutes' => 30,
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['price']);
    }

    public function test_duration_must_be_greater_than_zero(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'سشوار',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 0,
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['duration_minutes']);
    }

    public function test_catalog_item_name_cannot_be_duplicated_in_same_category(): void
    {
        $this->actingAsManager();

        $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'Hair Cut',
            'price' => 25000,
        ]);

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'HAIR CUT',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 30,
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name']);

        $this->assertDatabaseCount('catalog_items', 1);
    }

    public function test_same_catalog_item_name_is_allowed_in_different_categories(): void
    {
        $this->actingAsManager();

        $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'العناية',
            'price' => 25000,
        ]);

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->fillerCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'العناية',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 100000,
            'duration_minutes' => 30,
        ]);

        $response->assertCreated();

        $this->assertDatabaseCount('catalog_items', 2);
    }

    public function test_inactive_category_cannot_receive_new_catalog_item(): void
    {
        $this->actingAsManager();

        $this->hairCategory->update([
            'is_active' => false,
        ]);

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 30,
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['category_id']);
    }

    public function test_manager_can_view_catalog_item_details(): void
    {
        $this->actingAsManager();

        $item = $this->createCatalogItem([
            'category_id' => $this->fillerCategory->id,
            'name' => 'الفيلر الكوري',
            'price' => 100000,
        ]);

        $response = $this->getJson(
            "/api/admin/catalog-items/{$item->id}"
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $item->id)
            ->assertJsonPath('data.name', 'الفيلر الكوري')
            ->assertJsonPath('data.department.code', Department::CLINIC);
    }

    public function test_manager_can_update_catalog_item(): void
    {
        $this->actingAsManager();

        $item = $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'قص',
            'price' => 25000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);

        $response = $this->patchJson(
            "/api/admin/catalog-items/{$item->id}",
            [
                'name' => 'قص مع سشوار',
                'price_type' => CatalogItem::PRICE_TYPE_FIXED,
                'price' => 30000,
                'duration_minutes' => 45,
                'is_active' => false,
            ]
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم تحديث العنصر بنجاح.'
            )
            ->assertJsonPath('data.name', 'قص مع سشوار')
            ->assertJsonPath('data.price', '30000.00')
            ->assertJsonPath('data.duration_minutes', 45)
            ->assertJsonPath('data.is_active', false);

        $this->assertDatabaseHas('catalog_items', [
            'id' => $item->id,
            'name' => 'قص مع سشوار',
            'price' => 30000,
            'duration_minutes' => 45,
            'is_active' => false,
        ]);
    }

    public function test_manager_can_soft_delete_catalog_item(): void
    {
        $this->actingAsManager();

        $item = $this->createCatalogItem([
            'category_id' => $this->hairCategory->id,
            'name' => 'خدمة مؤقتة',
            'price' => 20000,
        ]);

        $response = $this->deleteJson(
            "/api/admin/catalog-items/{$item->id}"
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم حذف العنصر بنجاح.'
            );

        $this->assertSoftDeleted('catalog_items', [
            'id' => $item->id,
        ]);
    }

    public function test_catalog_item_validation_rejects_invalid_data(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/catalog-items', [
            'category_id' => 999999,
            'type' => 'product',
            'name' => '',
            'description' => str_repeat('a', 5001),
            'instructions' => str_repeat('b', 5001),
            'price_type' => 'unknown',
            'price' => 'invalid',
            'duration_minutes' => -5,
            'is_active' => 'invalid',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'category_id',
                'type',
                'name',
                'description',
                'instructions',
                'price_type',
                'price',
                'duration_minutes',
                'is_active',
            ]);
    }

    private function actingAsManager(): User
    {
        $manager = $this->createUser('manager');

        Sanctum::actingAs($manager, ['admin']);

        return $manager;
    }

    /**
     * @param  array<string, mixed>  $attributes
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

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function createCatalogItem(
        array $attributes = []
    ): CatalogItem {
        return CatalogItem::query()->create(array_merge([
            'category_id' => $this->hairCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'خدمة',
            'description' => null,
            'instructions' => null,
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 30,
            'is_active' => true,
        ], $attributes));
    }
}
