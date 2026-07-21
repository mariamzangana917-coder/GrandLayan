<?php

namespace Tests\Feature\Api\Admin;

use App\Models\Category;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class CategoryControllerTest extends TestCase
{
    use RefreshDatabase;

    private Department $salon;

    private Department $clinic;

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
    }

    public function test_unauthenticated_user_cannot_access_categories(): void
    {
        $this->getJson('/api/admin/categories')
            ->assertUnauthorized();

        $this->postJson('/api/admin/categories', [
            'department_id' => $this->salon->id,
            'name' => 'الشعر',
        ])->assertUnauthorized();
    }

    public function test_customer_cannot_access_category_management(): void
    {
        $customer = $this->createUser('customer', [
            'email' => 'customer@example.com',
            'phone' => '07700000002',
        ]);

        Sanctum::actingAs($customer, ['admin']);

        $this->getJson('/api/admin/categories')
            ->assertForbidden();

        $this->postJson('/api/admin/categories', [
            'department_id' => $this->salon->id,
            'name' => 'الشعر',
        ])->assertForbidden();
    }

    public function test_manager_can_list_categories(): void
    {
        $this->actingAsManager();

        $hair = Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'الشعر',
            'description' => 'خدمات الشعر',
            'is_active' => true,
        ]);

        $filler = Category::query()->create([
            'department_id' => $this->clinic->id,
            'name' => 'الفيلر',
            'description' => 'خدمات الفيلر',
            'is_active' => true,
        ]);

        $response = $this->getJson('/api/admin/categories');

        $response
            ->assertOk()
            ->assertJsonPath('data.0.id', $hair->id)
            ->assertJsonPath('data.0.department.code', Department::SALON)
            ->assertJsonPath('data.1.id', $filler->id)
            ->assertJsonPath('data.1.department.code', Department::CLINIC)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'department' => [
                            'id',
                            'code',
                            'name',
                        ],
                        'name',
                        'description',
                        'is_active',
                        'created_at',
                        'updated_at',
                    ],
                ],
            ]);
    }

    public function test_manager_can_filter_categories_by_department(): void
    {
        $this->actingAsManager();

        Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);

        Category::query()->create([
            'department_id' => $this->clinic->id,
            'name' => 'الفيلر',
            'is_active' => true,
        ]);

        $response = $this->getJson(
            '/api/admin/categories?department=salon'
        );

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'الشعر')
            ->assertJsonPath(
                'data.0.department.code',
                Department::SALON
            );
    }

    public function test_manager_can_filter_categories_by_active_status(): void
    {
        $this->actingAsManager();

        Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);

        Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'خدمة متوقفة',
            'is_active' => false,
        ]);

        $response = $this->getJson(
            '/api/admin/categories?is_active=true'
        );

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'الشعر')
            ->assertJsonPath('data.0.is_active', true);
    }

    public function test_manager_can_create_category(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/categories', [
            'department_id' => $this->salon->id,
            'name' => 'العناية بالشعر',
            'description' => 'خدمات العناية وعلاج الشعر',
            'is_active' => true,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath(
                'message',
                'تم إنشاء التصنيف بنجاح.'
            )
            ->assertJsonPath('data.name', 'العناية بالشعر')
            ->assertJsonPath(
                'data.department.code',
                Department::SALON
            )
            ->assertJsonPath('data.is_active', true);

        $this->assertDatabaseHas('categories', [
            'department_id' => $this->salon->id,
            'name' => 'العناية بالشعر',
            'is_active' => true,
            'deleted_at' => null,
        ]);
    }

    public function test_category_name_cannot_be_duplicated_in_same_department(): void
    {
        $this->actingAsManager();

        Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'Hair',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/admin/categories', [
            'department_id' => $this->salon->id,
            'name' => 'HAIR',
            'is_active' => true,
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name']);

        $this->assertDatabaseCount('categories', 1);
    }

    public function test_same_category_name_is_allowed_in_different_departments(): void
    {
        $this->actingAsManager();

        Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'العناية',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/admin/categories', [
            'department_id' => $this->clinic->id,
            'name' => 'العناية',
            'is_active' => true,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.name', 'العناية')
            ->assertJsonPath(
                'data.department.code',
                Department::CLINIC
            );

        $this->assertDatabaseCount('categories', 2);
    }

    public function test_manager_can_view_category_details(): void
    {
        $this->actingAsManager();

        $category = Category::query()->create([
            'department_id' => $this->clinic->id,
            'name' => 'البوتكس',
            'description' => 'أنواع البوتكس',
            'is_active' => true,
        ]);

        $response = $this->getJson(
            "/api/admin/categories/{$category->id}"
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $category->id)
            ->assertJsonPath('data.name', 'البوتكس')
            ->assertJsonPath(
                'data.department.code',
                Department::CLINIC
            );
    }

    public function test_manager_can_update_category(): void
    {
        $this->actingAsManager();

        $category = Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'الشعر',
            'description' => null,
            'is_active' => true,
        ]);

        $response = $this->patchJson(
            "/api/admin/categories/{$category->id}",
            [
                'name' => 'خدمات الشعر',
                'description' => 'قص وصبغ وعلاجات الشعر',
                'is_active' => false,
            ]
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم تحديث التصنيف بنجاح.'
            )
            ->assertJsonPath('data.name', 'خدمات الشعر')
            ->assertJsonPath('data.is_active', false);

        $this->assertDatabaseHas('categories', [
            'id' => $category->id,
            'name' => 'خدمات الشعر',
            'description' => 'قص وصبغ وعلاجات الشعر',
            'is_active' => false,
        ]);
    }

    public function test_manager_can_soft_delete_category_without_catalog_items(): void
    {
        $this->actingAsManager();

        $category = Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'تصنيف مؤقت',
            'is_active' => true,
        ]);

        $response = $this->deleteJson(
            "/api/admin/categories/{$category->id}"
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم حذف التصنيف بنجاح.'
            );

        $this->assertSoftDeleted('categories', [
            'id' => $category->id,
        ]);
    }

    public function test_category_validation_rejects_invalid_data(): void
    {
        $this->actingAsManager();

        $response = $this->postJson('/api/admin/categories', [
            'department_id' => 999999,
            'name' => '',
            'description' => str_repeat('a', 2001),
            'is_active' => 'invalid',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'department_id',
                'name',
                'description',
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
}
