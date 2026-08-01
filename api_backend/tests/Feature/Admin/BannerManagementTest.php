<?php

namespace Tests\Feature\Admin;

use App\Enums\BannerActionType;
use App\Models\Banner;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class BannerManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
        Role::findOrCreate('manager', 'web');
        Role::findOrCreate('customer', 'web');
    }

    public function test_guest_cannot_access_admin_banners(): void
    {
        $this->getJson('/api/admin/banners')
            ->assertUnauthorized();
    }

    public function test_customer_cannot_access_admin_banners(): void
    {
        $customer = User::factory()->create();
        $customer->assignRole('customer');
        Sanctum::actingAs($customer);

        $this->getJson('/api/admin/banners')
            ->assertForbidden();
    }

    public function test_manager_can_create_banner(): void
    {
        $this->actingAsManager();

        $response = $this->post('/api/admin/banners', [
            'title' => 'عرض العرائس',
            'subtitle' => 'احجزي موعدك الآن',
            'image' => UploadedFile::fake()->image('banner.jpg', 1200, 600)->size(500),
            'action_type' => BannerActionType::Booking->value,
            'starts_at' => now()->subMinute()->toIso8601String(),
            'ends_at' => now()->addWeek()->toIso8601String(),
            'sort_order' => 1,
            'is_active' => true,
        ], ['Accept' => 'application/json']);

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'عرض العرائس')
            ->assertJsonPath('data.action_type', 'booking')
            ->assertJsonPath('data.is_active', true);

        $banner = Banner::query()->firstOrFail();

        Storage::disk('public')->assertExists($banner->image_path);

        $this->assertDatabaseHas('banners', [
            'title' => 'عرض العرائس',
            'action_type' => 'booking',
            'sort_order' => 1,
            'is_active' => true,
        ]);
    }

    public function test_external_link_must_use_https(): void
    {
        $this->actingAsManager();

        $this->post('/api/admin/banners', [
            'image' => UploadedFile::fake()->image('banner.jpg', 1200, 600),
            'action_type' => BannerActionType::ExternalUrl->value,
            'external_url' => 'http://example.com',
        ], ['Accept' => 'application/json'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('external_url');
    }

    public function test_target_is_required_for_targeted_action(): void
    {
        $this->actingAsManager();

        $this->post('/api/admin/banners', [
            'image' => UploadedFile::fake()->image('banner.jpg', 1200, 600),
            'action_type' => BannerActionType::CatalogItem->value,
        ], ['Accept' => 'application/json'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('action_target_id');
    }

    public function test_manager_can_replace_banner_image(): void
    {
        $this->actingAsManager();

        Storage::disk('public')->put('banners/old.jpg', 'old');

        $banner = Banner::factory()->create([
            'image_path' => 'banners/old.jpg',
            'action_type' => BannerActionType::None,
            'action_target_id' => null,
            'external_url' => null,
        ]);

        $this->post("/api/admin/banners/{$banner->id}", [
            '_method' => 'PUT',
            'image' => UploadedFile::fake()->image('new.webp', 1200, 600),
        ], ['Accept' => 'application/json'])
            ->assertOk();

        $banner->refresh();

        Storage::disk('public')->assertMissing('banners/old.jpg');
        Storage::disk('public')->assertExists($banner->image_path);
    }

    public function test_deleting_banner_removes_database_record_and_image(): void
    {
        $this->actingAsManager();

        Storage::disk('public')->put('banners/delete-me.jpg', 'content');

        $banner = Banner::factory()->create([
            'image_path' => 'banners/delete-me.jpg',
        ]);

        $this->deleteJson("/api/admin/banners/{$banner->id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('banners', ['id' => $banner->id]);
        Storage::disk('public')->assertMissing('banners/delete-me.jpg');
    }

    private function actingAsManager(): User
    {
        $manager = User::factory()->create();
        $manager->assignRole('manager');
        Sanctum::actingAs($manager);

        return $manager;
    }
}
