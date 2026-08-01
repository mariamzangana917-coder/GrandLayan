<?php

namespace Tests\Feature\Admin;

use App\Models\GiftCardDesign;
use App\Models\GiftCardOrder;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class GiftCardDesignManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager');
        Role::findOrCreate('customer');
    }

    public function test_guest_cannot_view_gift_card_designs(): void
    {
        $this->getJson(
            '/api/admin/gift-card-designs'
        )->assertUnauthorized();
    }

    public function test_customer_cannot_view_admin_gift_card_designs(): void
    {
        $customer = User::factory()->create();
        $customer->assignRole('customer');

        Sanctum::actingAs($customer);

        $this->getJson(
            '/api/admin/gift-card-designs'
        )->assertForbidden();
    }

    public function test_manager_can_view_gift_card_designs(): void
    {
        $manager = $this->createManager();

        GiftCardDesign::factory()->create([
            'name' => 'بطاقة العناية الذهبية',
            'amount' => 50000,
            'sort_order' => 2,
        ]);

        GiftCardDesign::factory()->create([
            'name' => 'بطاقة الجمال الملكية',
            'amount' => 100000,
            'sort_order' => 1,
        ]);

        Sanctum::actingAs($manager);

        $this->getJson(
            '/api/admin/gift-card-designs'
        )
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath(
                'data.0.name',
                'بطاقة الجمال الملكية'
            )
            ->assertJsonPath(
                'data.1.name',
                'بطاقة العناية الذهبية'
            );
    }

    public function test_manager_can_search_and_filter_gift_card_designs(): void
    {
        $manager = $this->createManager();

        GiftCardDesign::factory()->create([
            'name' => 'بطاقة العروس الذهبية',
            'is_active' => true,
            'amount' => 150000,
        ]);

        GiftCardDesign::factory()->create([
            'name' => 'بطاقة قديمة',
            'is_active' => false,
            'amount' => 50000,
        ]);

        Sanctum::actingAs($manager);

        $this->getJson(
            '/api/admin/gift-card-designs'
            . '?search=العروس'
            . '&is_active=true'
            . '&amount=150000'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.name',
                'بطاقة العروس الذهبية'
            );
    }

    public function test_manager_can_create_gift_card_design_with_image(): void
    {
        Storage::fake('public');

        $manager = $this->createManager();

        Sanctum::actingAs($manager);

        $response = $this->post(
            '/api/admin/gift-card-designs',
            [
                'name' => 'بطاقة كراند ليان الذهبية',
                'description' => 'بطاقة هدية مميزة للخدمات.',
                'image' => UploadedFile::fake()
                    ->image('gold-card.jpg', 1200, 800),
                'amount' => 75000,
                'validity_days' => 365,
                'is_active' => true,
                'sort_order' => 1,
            ],
            [
                'Accept' => 'application/json',
            ]
        );

        $response
            ->assertCreated()
            ->assertJsonPath(
                'message',
                'تم إنشاء تصميم بطاقة الهدية بنجاح.'
            )
            ->assertJsonPath(
                'data.name',
                'بطاقة كراند ليان الذهبية'
            )
            ->assertJsonPath(
                'data.validity_days',
                365
            )
            ->assertJsonPath(
                'data.is_active',
                true
            );

        $design = GiftCardDesign::query()
            ->where('name', 'بطاقة كراند ليان الذهبية')
            ->firstOrFail();

        $this->assertNotNull($design->image_path);

        Storage::disk('public')->assertExists(
            $design->image_path
        );

        $this->assertDatabaseHas('gift_card_designs', [
            'id' => $design->id,
            'name' => 'بطاقة كراند ليان الذهبية',
            'amount' => 75000,
            'validity_days' => 365,
            'is_active' => true,
            'sort_order' => 1,
        ]);
    }

    public function test_creation_requires_valid_data(): void
    {
        $manager = $this->createManager();

        Sanctum::actingAs($manager);

        $this->postJson(
            '/api/admin/gift-card-designs',
            [
                'name' => '',
                'amount' => 0,
                'validity_days' => 0,
            ]
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'name',
                'amount',
                'validity_days',
            ]);
    }

    public function test_design_name_must_be_unique(): void
    {
        $manager = $this->createManager();

        GiftCardDesign::factory()->create([
            'name' => 'بطاقة مميزة',
        ]);

        Sanctum::actingAs($manager);

        $this->postJson(
            '/api/admin/gift-card-designs',
            [
                'name' => 'بطاقة مميزة',
                'amount' => 50000,
                'validity_days' => 365,
            ]
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('name');
    }

    public function test_manager_can_view_one_gift_card_design(): void
    {
        $manager = $this->createManager();

        $design = GiftCardDesign::factory()->create([
            'name' => 'بطاقة المناسبات',
            'amount' => 60000,
        ]);

        Sanctum::actingAs($manager);

        $this->getJson(
            "/api/admin/gift-card-designs/{$design->id}"
        )
            ->assertOk()
            ->assertJsonPath('data.id', $design->id)
            ->assertJsonPath(
                'data.name',
                'بطاقة المناسبات'
            );
    }

    public function test_unknown_gift_card_design_returns_not_found(): void
    {
        $manager = $this->createManager();

        Sanctum::actingAs($manager);

        $this->getJson(
            '/api/admin/gift-card-designs/999999'
        )->assertNotFound();
    }

    public function test_manager_can_update_gift_card_design(): void
    {
        $manager = $this->createManager();

        $design = GiftCardDesign::factory()->create([
            'name' => 'الاسم القديم',
            'amount' => 50000,
            'validity_days' => 180,
            'is_active' => true,
            'sort_order' => 5,
        ]);

        Sanctum::actingAs($manager);

        $this->patchJson(
            "/api/admin/gift-card-designs/{$design->id}",
            [
                'name' => 'الاسم الجديد',
                'amount' => 80000,
                'validity_days' => 365,
                'is_active' => false,
                'sort_order' => 2,
            ]
        )
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم تحديث تصميم بطاقة الهدية بنجاح.'
            )
            ->assertJsonPath(
                'data.name',
                'الاسم الجديد'
            )
            ->assertJsonPath(
                'data.is_active',
                false
            );

        $this->assertDatabaseHas('gift_card_designs', [
            'id' => $design->id,
            'name' => 'الاسم الجديد',
            'amount' => 80000,
            'validity_days' => 365,
            'is_active' => false,
            'sort_order' => 2,
        ]);
    }

    public function test_manager_can_replace_design_image(): void
    {
        Storage::fake('public');

        $manager = $this->createManager();

        $oldImagePath = UploadedFile::fake()
            ->image('old-image.jpg')
            ->store('gift-card-designs', 'public');

        $design = GiftCardDesign::factory()->create([
            'image_path' => $oldImagePath,
        ]);

        Sanctum::actingAs($manager);

        $response = $this->patch(
            "/api/admin/gift-card-designs/{$design->id}",
            [
                'image' => UploadedFile::fake()
                    ->image('new-image.jpg', 1200, 800),
            ],
            [
                'Accept' => 'application/json',
            ]
        );

        $response->assertOk();

        $design->refresh();

        $this->assertNotNull($design->image_path);
        $this->assertNotSame(
            $oldImagePath,
            $design->image_path
        );

        Storage::disk('public')->assertMissing(
            $oldImagePath
        );

        Storage::disk('public')->assertExists(
            $design->image_path
        );
    }

    public function test_manager_can_delete_only_design_image(): void
    {
        Storage::fake('public');

        $manager = $this->createManager();

        $imagePath = UploadedFile::fake()
            ->image('design.jpg')
            ->store('gift-card-designs', 'public');

        $design = GiftCardDesign::factory()->create([
            'image_path' => $imagePath,
        ]);

        Sanctum::actingAs($manager);

        $this->deleteJson(
            "/api/admin/gift-card-designs/{$design->id}/image"
        )
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم حذف صورة تصميم بطاقة الهدية بنجاح.'
            )
            ->assertJsonPath(
                'data.image_path',
                null
            );

        Storage::disk('public')->assertMissing(
            $imagePath
        );

        $this->assertDatabaseHas('gift_card_designs', [
            'id' => $design->id,
            'image_path' => null,
        ]);
    }

    public function test_deleting_missing_design_image_returns_validation_error(): void
    {
        $manager = $this->createManager();

        $design = GiftCardDesign::factory()->create([
            'image_path' => null,
        ]);

        Sanctum::actingAs($manager);

        $this->deleteJson(
            "/api/admin/gift-card-designs/{$design->id}/image"
        )
            ->assertUnprocessable()
            ->assertJsonPath(
                'message',
                'لا توجد صورة مرتبطة بهذا التصميم.'
            );
    }

    public function test_manager_can_delete_unused_gift_card_design(): void
    {
        Storage::fake('public');

        $manager = $this->createManager();

        $imagePath = UploadedFile::fake()
            ->image('unused-design.jpg')
            ->store('gift-card-designs', 'public');

        $design = GiftCardDesign::factory()->create([
            'image_path' => $imagePath,
        ]);

        Sanctum::actingAs($manager);

        $this->deleteJson(
            "/api/admin/gift-card-designs/{$design->id}"
        )
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم حذف تصميم بطاقة الهدية بنجاح.'
            );

        $this->assertDatabaseMissing('gift_card_designs', [
            'id' => $design->id,
        ]);

        Storage::disk('public')->assertMissing(
            $imagePath
        );
    }

    public function test_manager_cannot_delete_design_linked_to_orders(): void
    {
        $manager = $this->createManager();

        $design = GiftCardDesign::factory()->create();

        GiftCardOrder::factory()->create([
            'gift_card_design_id' => $design->id,
        ]);

        Sanctum::actingAs($manager);

        $this->deleteJson(
            "/api/admin/gift-card-designs/{$design->id}"
        )
            ->assertUnprocessable()
            ->assertJsonPath(
                'message',
                'لا يمكن حذف التصميم لأنه مرتبط بطلبات بطاقات هدية. يمكنك تعطيله بدلًا من حذفه.'
            );

        $this->assertDatabaseHas('gift_card_designs', [
            'id' => $design->id,
        ]);
    }

    private function createManager(): User
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');

        return $manager;
    }
}