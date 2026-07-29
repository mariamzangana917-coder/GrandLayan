<?php

namespace Tests\Feature\Api\Offers;

use App\Models\CatalogItem;
use App\Models\Category;
use App\Models\Department;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class OfferApiTest extends TestCase
{
    use RefreshDatabase;

    private Department $salon;

    private Department $clinic;

    private CatalogItem $salonService;

    private CatalogItem $clinicService;

    private User $manager;

    private User $customer;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');

        Carbon::setTestNow(Carbon::parse('2026-07-29 12:00:00'));

        app(PermissionRegistrar::class)->forgetCachedPermissions();

        Role::findOrCreate('manager', 'web');
        Role::findOrCreate('customer', 'web');

        $this->manager = $this->createUser(
            role: 'manager',
            email: 'manager-offers@example.com',
            phone: '07710000001',
        );

        $this->customer = $this->createUser(
            role: 'customer',
            email: 'customer-offers@example.com',
            phone: '07710000002',
        );

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

        $salonCategory = Category::query()->create([
            'department_id' => $this->salon->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);

        $clinicCategory = Category::query()->create([
            'department_id' => $this->clinic->id,
            'name' => 'البشرة',
            'is_active' => true,
        ]);

        $this->salonService = CatalogItem::query()->create([
            'category_id' => $salonCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص الشعر',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);

        $this->clinicService = CatalogItem::query()->create([
            'category_id' => $clinicCategory->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'تنظيف البشرة',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 50000,
            'duration_minutes' => 45,
            'is_active' => true,
        ]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_guest_cannot_access_admin_offers(): void
    {
        $this->getJson('/api/admin/offers')
            ->assertUnauthorized();

        $this->postJson('/api/admin/offers', [])
            ->assertUnauthorized();
    }

    public function test_customer_cannot_access_admin_offers(): void
    {
        Sanctum::actingAs($this->customer, ['customer']);

        $this->getJson('/api/admin/offers')
            ->assertForbidden();

        $this->postJson('/api/admin/offers', [])
            ->assertForbidden();
    }

    public function test_manager_can_create_offer_with_image_and_catalog_item(): void
    {
        $this->actingAsManager();

        $response = $this->post(
            '/api/admin/offers',
            [
                'department_id' => $this->salon->id,
                'catalog_item_id' => $this->salonService->id,
                'title' => 'عرض العناية المتكاملة',
                'description' => 'عرض خاص على خدمة قص الشعر.',
                'badge_text' => 'عرض',
                'value_text' => 'خصم 20%',
                'details_text' => 'لفترة محدودة',
                'starts_at' => now()->subHour()->toISOString(),
                'ends_at' => now()->addDays(7)->toISOString(),
                'is_active' => true,
                'sort_order' => 3,
                'image' => $this->fakePng('salon-offer.png'),
            ],
            ['Accept' => 'application/json'],
        );

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'عرض العناية المتكاملة')
            ->assertJsonPath('data.department.id', $this->salon->id)
            ->assertJsonPath('data.department.code', Department::SALON)
            ->assertJsonPath('data.catalog_item.id', $this->salonService->id)
            ->assertJsonPath('data.is_active', true)
            ->assertJsonPath('data.sort_order', 3)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'department',
                    'catalog_item',
                    'title',
                    'description',
                    'badge_text',
                    'value_text',
                    'details_text',
                    'image_url',
                    'starts_at',
                    'ends_at',
                    'is_active',
                    'sort_order',
                    'availability',
                    'created_at',
                    'updated_at',
                ],
            ]);

        $offer = DB::table('offers')->first();

        $this->assertNotNull($offer);
        $this->assertSame($this->manager->id, $offer->created_by_user_id);
        $this->assertNotNull($offer->image_path);

        Storage::disk('public')->assertExists($offer->image_path);
    }

    public function test_offer_creation_requires_valid_data(): void
    {
        $this->actingAsManager();

        $this->postJson('/api/admin/offers', [
            'department_id' => 999999,
            'title' => 'x',
            'starts_at' => now()->addDay()->toISOString(),
            'ends_at' => now()->toISOString(),
            'is_active' => 'not-boolean',
            'sort_order' => -1,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'department_id',
                'title',
                'image',
                'ends_at',
                'is_active',
                'sort_order',
            ]);

        $this->assertDatabaseCount('offers', 0);
    }

    public function test_offer_rejects_catalog_item_from_another_department(): void
    {
        $this->actingAsManager();

        $this->post(
            '/api/admin/offers',
            [
                'department_id' => $this->salon->id,
                'catalog_item_id' => $this->clinicService->id,
                'title' => 'عرض غير صالح',
                'starts_at' => now()->subHour()->toISOString(),
                'ends_at' => now()->addDay()->toISOString(),
                'is_active' => true,
                'sort_order' => 0,
                'image' => $this->fakePng('invalid-offer.png'),
            ],
            ['Accept' => 'application/json'],
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('catalog_item_id');

        $this->assertDatabaseCount('offers', 0);
    }

    public function test_manager_can_search_filter_and_order_offers(): void
    {
        $this->actingAsManager();

        $later = $this->createOffer([
            'department_id' => $this->salon->id,
            'title' => 'عرض الشعر الثاني',
            'sort_order' => 8,
        ]);

        $first = $this->createOffer([
            'department_id' => $this->salon->id,
            'title' => 'عرض الشعر الأول',
            'sort_order' => 1,
        ]);

        $this->createOffer([
            'department_id' => $this->clinic->id,
            'title' => 'عرض البشرة',
            'sort_order' => 0,
        ]);

        $response = $this->getJson(
            '/api/admin/offers?department=salon&search=الشعر&is_active=1'
            .'&availability=current&per_page=20',
        );

        $response
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $first)
            ->assertJsonPath('data.1.id', $later)
            ->assertJsonPath('data.0.department.code', Department::SALON)
            ->assertJsonStructure([
                'data',
                'links',
                'meta',
            ]);
    }

    public function test_manager_can_view_offer_details(): void
    {
        $this->actingAsManager();

        $offerId = $this->createOffer([
            'catalog_item_id' => $this->salonService->id,
            'title' => 'عرض التفاصيل',
        ]);

        $this->getJson("/api/admin/offers/{$offerId}")
            ->assertOk()
            ->assertJsonPath('data.id', $offerId)
            ->assertJsonPath('data.catalog_item.id', $this->salonService->id)
            ->assertJsonPath('data.title', 'عرض التفاصيل');
    }

    public function test_manager_can_update_offer_metadata(): void
    {
        $this->actingAsManager();

        $offerId = $this->createOffer();

        $this->patchJson("/api/admin/offers/{$offerId}", [
            'title' => 'العرض المحدث',
            'description' => 'تفاصيل جديدة',
            'badge_text' => 'جديد',
            'value_text' => 'خصم 25%',
            'details_text' => 'حتى نهاية الأسبوع',
            'starts_at' => now()->subHours(2)->toISOString(),
            'ends_at' => now()->addDays(10)->toISOString(),
            'is_active' => false,
            'sort_order' => 9,
        ])
            ->assertOk()
            ->assertJsonPath('data.title', 'العرض المحدث')
            ->assertJsonPath('data.is_active', false)
            ->assertJsonPath('data.sort_order', 9);

        $this->assertDatabaseHas('offers', [
            'id' => $offerId,
            'title' => 'العرض المحدث',
            'is_active' => false,
            'sort_order' => 9,
        ]);
    }

    public function test_manager_can_replace_offer_image_and_old_file_is_deleted(): void
    {
        $this->actingAsManager();

        $oldPath = 'offers/old-image.png';

        Storage::disk('public')->put($oldPath, 'old-image');

        $offerId = $this->createOffer([
            'image_path' => $oldPath,
        ]);

        $response = $this->post(
            "/api/admin/offers/{$offerId}/image",
            [
                'image' => $this->fakePng('replacement.png'),
            ],
            ['Accept' => 'application/json'],
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $offerId)
            ->assertJsonStructure([
                'data' => [
                    'image_url',
                ],
            ]);

        $newPath = DB::table('offers')
            ->where('id', $offerId)
            ->value('image_path');

        $this->assertNotSame($oldPath, $newPath);

        Storage::disk('public')->assertMissing($oldPath);
        Storage::disk('public')->assertExists($newPath);
    }

    public function test_manager_can_soft_delete_offer_and_remove_its_image(): void
    {
        $this->actingAsManager();

        $path = 'offers/delete-me.png';

        Storage::disk('public')->put($path, 'image');

        $offerId = $this->createOffer([
            'image_path' => $path,
        ]);

        $this->deleteJson("/api/admin/offers/{$offerId}")
            ->assertOk();

        $this->assertSoftDeleted('offers', [
            'id' => $offerId,
        ]);

        Storage::disk('public')->assertMissing($path);
    }

    public function test_guest_cannot_access_customer_offers(): void
    {
        $this->getJson('/api/customer/offers')
            ->assertUnauthorized();
    }

    public function test_manager_cannot_access_customer_offers(): void
    {
        Sanctum::actingAs($this->manager, ['admin']);

        $this->getJson('/api/customer/offers')
            ->assertForbidden();
    }

    public function test_customer_sees_only_active_current_offers(): void
    {
        $this->actingAsCustomer();

        $visible = $this->createOffer([
            'title' => 'العرض الظاهر',
            'is_active' => true,
            'starts_at' => now()->subDay(),
            'ends_at' => now()->addDay(),
        ]);

        $this->createOffer([
            'title' => 'عرض غير فعال',
            'is_active' => false,
            'starts_at' => now()->subDay(),
            'ends_at' => now()->addDay(),
        ]);

        $this->createOffer([
            'title' => 'عرض قادم',
            'is_active' => true,
            'starts_at' => now()->addHour(),
            'ends_at' => now()->addDays(2),
        ]);

        $this->createOffer([
            'title' => 'عرض منتهي',
            'is_active' => true,
            'starts_at' => now()->subDays(2),
            'ends_at' => now()->subHour(),
        ]);

        $this->getJson('/api/customer/offers')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $visible)
            ->assertJsonPath('data.0.title', 'العرض الظاهر')
            ->assertJsonPath('data.0.availability', 'current');
    }

    public function test_customer_can_filter_current_offers_by_department(): void
    {
        $this->actingAsCustomer();

        $salonOffer = $this->createOffer([
            'department_id' => $this->salon->id,
            'title' => 'عرض الصالون',
        ]);

        $this->createOffer([
            'department_id' => $this->clinic->id,
            'title' => 'عرض العيادة',
        ]);

        $this->getJson('/api/customer/offers?department=salon')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $salonOffer)
            ->assertJsonPath('data.0.department.code', Department::SALON);
    }

    public function test_customer_offer_response_contains_safe_linked_catalog_item_data(): void
    {
        $this->actingAsCustomer();

        $offerId = $this->createOffer([
            'catalog_item_id' => $this->salonService->id,
        ]);

        $response = $this->getJson("/api/customer/offers/{$offerId}");

        $response
            ->assertOk()
            ->assertJsonPath('data.catalog_item.id', $this->salonService->id)
            ->assertJsonPath('data.catalog_item.name', 'قص الشعر')
            ->assertJsonPath('data.catalog_item.price', '25000.00')
            ->assertJsonMissingPath('data.image_path')
            ->assertJsonMissingPath('data.created_by_user_id');
    }

    public function test_customer_cannot_view_inactive_upcoming_expired_or_deleted_offer(): void
    {
        $this->actingAsCustomer();

        $offerIds = [
            $this->createOffer([
                'is_active' => false,
            ]),
            $this->createOffer([
                'starts_at' => now()->addHour(),
                'ends_at' => now()->addDays(2),
            ]),
            $this->createOffer([
                'starts_at' => now()->subDays(2),
                'ends_at' => now()->subHour(),
            ]),
            $this->createOffer([
                'deleted_at' => now(),
            ]),
        ];

        foreach ($offerIds as $offerId) {
            $this->getJson("/api/customer/offers/{$offerId}")
                ->assertNotFound();
        }
    }

    public function test_database_rejects_offer_with_invalid_date_range(): void
    {
        $this->expectException(QueryException::class);

        $this->createOffer([
            'starts_at' => now()->addDay(),
            'ends_at' => now(),
        ]);
    }

    public function test_database_rejects_negative_offer_sort_order(): void
    {
        $this->expectException(QueryException::class);

        $this->createOffer([
            'sort_order' => -1,
        ]);
    }

    private function actingAsManager(): void
    {
        Sanctum::actingAs($this->manager, ['admin']);
    }

    private function actingAsCustomer(): void
    {
        Sanctum::actingAs($this->customer, ['customer']);
    }

    /**
     * @param array<string, mixed> $overrides
     */
    private function createOffer(array $overrides = []): int
    {
        $attributes = array_merge([
            'department_id' => $this->salon->id,
            'catalog_item_id' => null,
            'created_by_user_id' => $this->manager->id,
            'title' => 'عرض تجريبي',
            'description' => 'وصف العرض التجريبي.',
            'badge_text' => 'عرض',
            'value_text' => 'خصم 20%',
            'details_text' => 'لفترة محدودة',
            'image_path' => 'offers/test-offer.png',
            'starts_at' => now()->subHour(),
            'ends_at' => now()->addDays(7),
            'is_active' => true,
            'sort_order' => 0,
            'created_at' => now(),
            'updated_at' => now(),
            'deleted_at' => null,
        ], $overrides);

        return (int) DB::table('offers')->insertGetId($attributes);
    }

    private function createUser(
        string $role,
        string $email,
        string $phone,
    ): User {
        $user = User::query()->create([
            'name' => 'Grand Layan User',
            'email' => $email,
            'phone' => $phone,
            'password' => 'Password123!',
            'is_active' => true,
        ]);

        $user->assignRole($role);

        return $user;
    }

    private function fakePng(string $name): UploadedFile
    {
        $png = base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
            .'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            true,
        );

        return UploadedFile::fake()->createWithContent(
            $name,
            $png === false ? '' : $png,
        );
    }
}
