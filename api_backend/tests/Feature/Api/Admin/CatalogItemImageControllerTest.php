<?php

namespace Tests\Feature\Api\Admin;

use App\Models\CatalogItem;
use App\Models\CatalogItemImage;
use App\Models\Category;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class CatalogItemImageControllerTest extends TestCase
{
    use RefreshDatabase;

    private CatalogItem $catalogItem;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');

        app(PermissionRegistrar::class)->forgetCachedPermissions();

        Role::findOrCreate('manager', 'web');
        Role::findOrCreate('customer', 'web');

        $department = Department::query()->create([
            'code' => Department::SALON,
            'name' => 'الصالون',
            'is_active' => true,
            'sort_order' => 1,
        ]);

        $category = Category::query()->create([
            'department_id' => $department->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);

        $this->catalogItem = CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);
    }

    public function test_unauthenticated_user_cannot_manage_catalog_images(): void
    {
        $this->getJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images"
        )->assertUnauthorized();

        $this->postJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images"
        )->assertUnauthorized();
    }

    public function test_customer_cannot_manage_catalog_images(): void
    {
        $customer = $this->createUser('customer', [
            'email' => 'customer@example.com',
            'phone' => '07700000002',
        ]);

        Sanctum::actingAs($customer, ['admin']);

        $this->getJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images"
        )->assertForbidden();
    }

    public function test_manager_can_list_catalog_item_images(): void
    {
        $this->actingAsManager();

        $first = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/first.png',
            'is_primary' => true,
            'sort_order' => 1,
        ]);

        $second = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/second.png',
            'is_primary' => false,
            'sort_order' => 2,
        ]);

        $response = $this->getJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images"
        );

        $response
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $first->id)
            ->assertJsonPath('data.0.is_primary', true)
            ->assertJsonPath('data.1.id', $second->id)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'path',
                        'url',
                        'alt_text',
                        'is_primary',
                        'sort_order',
                        'created_at',
                        'updated_at',
                    ],
                ],
            ]);
    }

    public function test_manager_can_upload_one_image(): void
    {
        $this->actingAsManager();

        $response = $this->post(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images",
            [
                'images' => [
                    $this->fakePng('haircut.png'),
                ],
            ],
            [
                'Accept' => 'application/json',
            ]
        );

        $response
            ->assertCreated()
            ->assertJsonPath('message', 'تم رفع الصور بنجاح.')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.is_primary', true)
            ->assertJsonPath('data.0.sort_order', 1);

        $image = CatalogItemImage::query()->firstOrFail();

        Storage::disk('public')->assertExists($image->path);

        $this->assertTrue($image->is_primary);
    }

    public function test_manager_can_upload_multiple_images(): void
    {
        $this->actingAsManager();

        $response = $this->post(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images",
            [
                'images' => [
                    $this->fakePng('first.png'),
                    $this->fakePng('second.png'),
                    $this->fakePng('third.png'),
                ],
            ],
            [
                'Accept' => 'application/json',
            ]
        );

        $response
            ->assertCreated()
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.is_primary', true)
            ->assertJsonPath('data.1.is_primary', false)
            ->assertJsonPath('data.2.is_primary', false);

        $this->assertDatabaseCount('catalog_item_images', 3);

        $this->assertSame(
            1,
            CatalogItemImage::query()
                ->where('is_primary', true)
                ->count()
        );
    }

    public function test_uploading_more_images_keeps_existing_primary_image(): void
    {
        $this->actingAsManager();

        $primary = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/existing.png',
            'is_primary' => true,
            'sort_order' => 1,
        ]);

        $this->post(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images",
            [
                'images' => [
                    $this->fakePng('new.png'),
                ],
            ],
            [
                'Accept' => 'application/json',
            ]
        )->assertCreated();

        $this->assertDatabaseHas('catalog_item_images', [
            'id' => $primary->id,
            'is_primary' => true,
        ]);

        $this->assertSame(
            1,
            CatalogItemImage::query()
                ->where('is_primary', true)
                ->count()
        );
    }

    public function test_image_upload_is_optional_for_catalog_item_creation(): void
    {
        $this->actingAsManager();

        $this->assertDatabaseCount('catalog_item_images', 0);

        $this->getJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images"
        )
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_upload_requires_at_least_one_image(): void
    {
        $this->actingAsManager();

        $response = $this->postJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images",
            [
                'images' => [],
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['images']);
    }

    public function test_upload_rejects_unsupported_file_type(): void
    {
        $this->actingAsManager();

        $response = $this->post(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images",
            [
                'images' => [
                    UploadedFile::fake()->create(
                        'document.pdf',
                        100,
                        'application/pdf'
                    ),
                ],
            ],
            [
                'Accept' => 'application/json',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['images.0']);
    }

    public function test_upload_rejects_more_than_ten_images_per_request(): void
    {
        $this->actingAsManager();

        $images = [];

        for ($index = 1; $index <= 11; $index++) {
            $images[] = $this->fakePng("image-{$index}.png");
        }

        $response = $this->post(
            "/api/admin/catalog-items/{$this->catalogItem->id}/images",
            [
                'images' => $images,
            ],
            [
                'Accept' => 'application/json',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['images']);
    }

    public function test_manager_can_update_image_metadata(): void
    {
        $this->actingAsManager();

        $image = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/image.png',
            'is_primary' => true,
            'sort_order' => 1,
        ]);

        $response = $this->patchJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}"
            ."/images/{$image->id}",
            [
                'alt_text' => 'صورة خدمة قص الشعر',
                'sort_order' => 5,
            ]
        );

        $response
            ->assertOk()
            ->assertJsonPath('message', 'تم تحديث الصورة بنجاح.')
            ->assertJsonPath('data.alt_text', 'صورة خدمة قص الشعر')
            ->assertJsonPath('data.sort_order', 5);

        $this->assertDatabaseHas('catalog_item_images', [
            'id' => $image->id,
            'alt_text' => 'صورة خدمة قص الشعر',
            'sort_order' => 5,
        ]);
    }

    public function test_manager_can_change_primary_image(): void
    {
        $this->actingAsManager();

        $first = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/first.png',
            'is_primary' => true,
            'sort_order' => 1,
        ]);

        $second = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/second.png',
            'is_primary' => false,
            'sort_order' => 2,
        ]);

        $response = $this->patchJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}"
            ."/images/{$second->id}",
            [
                'is_primary' => true,
            ]
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $second->id)
            ->assertJsonPath('data.is_primary', true);

        $this->assertDatabaseHas('catalog_item_images', [
            'id' => $first->id,
            'is_primary' => false,
        ]);

        $this->assertDatabaseHas('catalog_item_images', [
            'id' => $second->id,
            'is_primary' => true,
        ]);
    }

    public function test_manager_can_delete_non_primary_image(): void
    {
        $this->actingAsManager();

        CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/primary.png',
            'is_primary' => true,
            'sort_order' => 1,
        ]);

        $image = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/secondary.png',
            'is_primary' => false,
            'sort_order' => 2,
        ]);

        Storage::disk('public')->put($image->path, 'image-content');

        $response = $this->deleteJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}"
            ."/images/{$image->id}"
        );

        $response
            ->assertOk()
            ->assertJsonPath('message', 'تم حذف الصورة بنجاح.');

        $this->assertDatabaseMissing('catalog_item_images', [
            'id' => $image->id,
        ]);

        Storage::disk('public')->assertMissing($image->path);
    }

    public function test_deleting_primary_image_promotes_first_remaining_image(): void
    {
        $this->actingAsManager();

        $primary = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/primary.png',
            'is_primary' => true,
            'sort_order' => 1,
        ]);

        $remaining = CatalogItemImage::query()->create([
            'catalog_item_id' => $this->catalogItem->id,
            'path' => 'catalog/items/remaining.png',
            'is_primary' => false,
            'sort_order' => 2,
        ]);

        $this->deleteJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}"
            ."/images/{$primary->id}"
        )->assertOk();

        $this->assertDatabaseHas('catalog_item_images', [
            'id' => $remaining->id,
            'is_primary' => true,
        ]);
    }

    public function test_image_from_another_catalog_item_cannot_be_modified(): void
    {
        $this->actingAsManager();

        $otherItem = CatalogItem::query()->create([
            'category_id' => $this->catalogItem->category_id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'سشوار',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);

        $image = CatalogItemImage::query()->create([
            'catalog_item_id' => $otherItem->id,
            'path' => 'catalog/items/other.png',
            'is_primary' => true,
            'sort_order' => 1,
        ]);

        $this->patchJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}"
            ."/images/{$image->id}",
            [
                'alt_text' => 'محاولة تعديل',
            ]
        )->assertNotFound();

        $this->deleteJson(
            "/api/admin/catalog-items/{$this->catalogItem->id}"
            ."/images/{$image->id}"
        )->assertNotFound();
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

    private function fakePng(string $name): UploadedFile
    {
        $png = base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
            .'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            true
        );

        return UploadedFile::fake()->createWithContent(
            $name,
            $png === false ? '' : $png
        );
    }
}