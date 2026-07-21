<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\Coupon;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class AdminCouponTest extends TestCase
{
    use RefreshDatabase;

    private User $manager;

    private User $customer;

    protected function setUp(): void
    {
        parent::setUp();

        app(PermissionRegistrar::class)
            ->forgetCachedPermissions();

        $managerRole = Role::query()->create([
            'name' => 'manager',
            'guard_name' => 'web',
        ]);

        $customerRole = Role::query()->create([
            'name' => 'customer',
            'guard_name' => 'web',
        ]);

        app(PermissionRegistrar::class)
            ->forgetCachedPermissions();

        $this->manager = User::factory()->create([
            'is_active' => true,
        ]);

        $this->manager->assignRole($managerRole);

        $this->customer = User::factory()->create([
            'is_active' => true,
        ]);

        $this->customer->assignRole($customerRole);
    }

    public function test_guest_cannot_access_coupons(): void
    {
        $this->getJson('/api/admin/coupons')
            ->assertUnauthorized();
    }

    public function test_customer_cannot_access_coupon_management(): void
    {
        Sanctum::actingAs($this->customer);

        $this->getJson('/api/admin/coupons')
            ->assertForbidden();
    }

    public function test_manager_can_list_coupons(): void
    {
        Sanctum::actingAs($this->manager);

        Coupon::factory()
            ->count(3)
            ->create();

        $this->getJson('/api/admin/coupons')
            ->assertOk()
            ->assertJsonCount(3, 'data');
    }

    public function test_manager_can_create_coupon(): void
    {
        Sanctum::actingAs($this->manager);

        $payload = [
            'name' => 'خصم الزبائن الجدد',
            'code' => 'WELCOME20',
            'discount_type' => 'percentage',
            'discount_value' => 20,
            'minimum_order_amount' => 50000,
            'maximum_discount_amount' => 25000,
            'department_id' => null,
            'maximum_total_uses' => 100,
            'maximum_uses_per_customer' => 1,
            'starts_at' => now()
                ->subDay()
                ->toISOString(),
            'expires_at' => now()
                ->addMonth()
                ->toISOString(),
            'is_active' => true,
            'notes' => 'كوبون ترحيبي للزبائن الجدد',
            'catalog_item_ids' => [],
        ];

        $response = $this->postJson(
            '/api/admin/coupons',
            $payload
        );

        $response
            ->assertCreated()
            ->assertJsonPath(
                'data.name',
                'خصم الزبائن الجدد'
            )
            ->assertJsonPath(
                'data.code',
                'WELCOME20'
            )
            ->assertJsonPath(
                'data.discount_type',
                'percentage'
            )
            ->assertJsonPath(
                'data.discount_value',
                20
            )
            ->assertJsonPath(
                'data.is_active',
                true
            );

        $this->assertDatabaseHas('coupons', [
            'name' => 'خصم الزبائن الجدد',
            'code' => 'WELCOME20',
            'discount_type' => 'percentage',
            'is_active' => true,
            'used_count' => 0,
        ]);
    }

    public function test_coupon_creation_requires_valid_data(): void
    {
        Sanctum::actingAs($this->manager);

        $response = $this->postJson(
            '/api/admin/coupons',
            [
                'name' => '',
                'code' => '',
                'discount_type' => 'invalid-type',
                'discount_value' => 0,
                'maximum_total_uses' => 0,
                'maximum_uses_per_customer' => 0,
                'starts_at' => now()
                    ->addMonth()
                    ->toISOString(),
                'expires_at' => now()
                    ->toISOString(),
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'name',
                'code',
                'discount_type',
                'discount_value',
                'maximum_total_uses',
                'maximum_uses_per_customer',
                'expires_at',
            ]);

        $this->assertDatabaseCount('coupons', 0);
    }

    public function test_manager_can_update_coupon(): void
    {
        Sanctum::actingAs($this->manager);

        $coupon = Coupon::factory()->create([
            'name' => 'خصم قديم',
            'code' => 'OLD10',
            'discount_type' => 'percentage',
            'discount_value' => 10,
            'is_active' => true,
        ]);

        $response = $this->putJson(
            "/api/admin/coupons/{$coupon->id}",
            [
                'name' => 'خصم محدث',
                'code' => 'NEW25',
                'discount_type' => 'percentage',
                'discount_value' => 25,
                'minimum_order_amount' => 75000,
                'maximum_discount_amount' => 30000,
                'department_id' => null,
                'maximum_total_uses' => 200,
                'maximum_uses_per_customer' => 2,
                'starts_at' => now()
                    ->subDay()
                    ->toISOString(),
                'expires_at' => now()
                    ->addMonths(2)
                    ->toISOString(),
                'is_active' => true,
                'notes' => 'تم تحديث الكوبون',
                'catalog_item_ids' => [],
            ]
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.name',
                'خصم محدث'
            )
            ->assertJsonPath(
                'data.code',
                'NEW25'
            )
            ->assertJsonPath(
                'data.discount_value',
                25
            );

        $this->assertDatabaseHas('coupons', [
            'id' => $coupon->id,
            'name' => 'خصم محدث',
            'code' => 'NEW25',
            'discount_value' => 25,
        ]);
    }

    public function test_manager_can_delete_unused_coupon(): void
    {
        Sanctum::actingAs($this->manager);

        $coupon = Coupon::factory()->create();

        $response = $this->deleteJson(
            "/api/admin/coupons/{$coupon->id}"
        );

        $response->assertOk();

        $this->assertDatabaseMissing('coupons', [
            'id' => $coupon->id,
        ]);
    }

    public function test_manager_can_search_coupons_by_name_or_code(): void
    {
        Sanctum::actingAs($this->manager);

        Coupon::factory()->create([
            'name' => 'خصم العيد',
            'code' => 'EID25',
        ]);

        Coupon::factory()->create([
            'name' => 'خصم الصيف',
            'code' => 'SUMMER15',
        ]);

        $this->getJson(
            '/api/admin/coupons?search=العيد'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.name',
                'خصم العيد'
            );

        $this->getJson(
            '/api/admin/coupons?search=SUMMER15'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.code',
                'SUMMER15'
            );
    }

    public function test_manager_can_filter_coupons_by_discount_type(): void
    {
        Sanctum::actingAs($this->manager);

        Coupon::factory()
            ->percentage()
            ->create([
                'name' => 'خصم نسبي',
                'code' => 'PERCENT20',
            ]);

        Coupon::factory()
            ->fixed()
            ->create([
                'name' => 'خصم ثابت',
                'code' => 'FIXED10',
            ]);

        $this->getJson(
            '/api/admin/coupons?discount_type=percentage'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.discount_type',
                'percentage'
            );

        $this->getJson(
            '/api/admin/coupons?discount_type=fixed'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.discount_type',
                'fixed'
            );
    }

    public function test_manager_can_filter_coupons_by_active_status(): void
    {
        Sanctum::actingAs($this->manager);

        Coupon::factory()->create([
            'name' => 'كوبون فعال',
            'code' => 'ACTIVE10',
            'is_active' => true,
        ]);

        Coupon::factory()
            ->inactive()
            ->create([
                'name' => 'كوبون غير فعال',
                'code' => 'INACTIVE10',
            ]);

        $this->getJson(
            '/api/admin/coupons?is_active=1'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.is_active',
                true
            );

        $this->getJson(
            '/api/admin/coupons?is_active=0'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.is_active',
                false
            );
    }

    public function test_manager_can_filter_coupons_by_availability(): void
    {
        Sanctum::actingAs($this->manager);

        Coupon::factory()->create([
            'name' => 'كوبون متاح',
            'code' => 'AVAILABLE10',
            'starts_at' => now()->subDay(),
            'expires_at' => now()->addMonth(),
            'is_active' => true,
            'maximum_total_uses' => 100,
            'used_count' => 0,
        ]);

        Coupon::factory()
            ->upcoming()
            ->create([
                'name' => 'كوبون قادم',
                'code' => 'UPCOMING10',
                'is_active' => true,
            ]);

        Coupon::factory()
            ->expired()
            ->create([
                'name' => 'كوبون منتهي',
                'code' => 'EXPIRED10',
                'is_active' => true,
            ]);

        Coupon::factory()->create([
            'name' => 'كوبون مستنفد',
            'code' => 'EXHAUSTED10',
            'starts_at' => now()->subDay(),
            'expires_at' => now()->addMonth(),
            'is_active' => true,
            'maximum_total_uses' => 5,
            'used_count' => 5,
        ]);

        $this->getJson(
            '/api/admin/coupons?availability=available'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.code',
                'AVAILABLE10'
            );

        $this->getJson(
            '/api/admin/coupons?availability=upcoming'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.code',
                'UPCOMING10'
            );

        $this->getJson(
            '/api/admin/coupons?availability=expired'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.code',
                'EXPIRED10'
            );

        $this->getJson(
            '/api/admin/coupons?availability=exhausted'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath(
                'data.0.code',
                'EXHAUSTED10'
            );
    }

    public function test_used_coupon_is_deactivated_instead_of_deleted(): void
    {
        Sanctum::actingAs($this->manager);

        $coupon = Coupon::factory()->create([
            'name' => 'كوبون مستخدم',
            'code' => 'USED10',
            'is_active' => true,
        ]);

        $appointment = Appointment::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $coupon->redemptions()->create([
            'customer_id' => $this->customer->id,
            'appointment_id' => $appointment->id,
            'subtotal_amount' => 50000,
            'discount_amount' => 10000,
            'final_amount' => 40000,
            'redeemed_at' => now(),
            'status' => 'applied',
        ]);

        $response = $this->deleteJson(
            "/api/admin/coupons/{$coupon->id}"
        );

        $response->assertOk();

        $this->assertDatabaseHas('coupons', [
            'id' => $coupon->id,
            'is_active' => false,
        ]);

        $this->assertDatabaseHas(
            'coupon_redemptions',
            [
                'coupon_id' => $coupon->id,
                'customer_id' => $this->customer->id,
                'appointment_id' => $appointment->id,
                'subtotal_amount' => 50000,
                'discount_amount' => 10000,
                'final_amount' => 40000,
                'status' => 'applied',
            ]
        );
    }
}
