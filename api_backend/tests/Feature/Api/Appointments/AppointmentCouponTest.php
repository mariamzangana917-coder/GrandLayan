<?php

namespace Tests\Feature\Api\Appointments;

use App\Models\CatalogItem;
use App\Models\Category;
use App\Models\Coupon;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AppointmentCouponTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;

    private Department $department;

    private Category $category;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer', 'web');

        $this->customer = User::factory()->create([
            'is_active' => true,
        ]);
        $this->customer->assignRole('customer');

        $this->department = Department::factory()->salon()->create();

        $this->category = Category::factory()->create([
            'department_id' => $this->department->id,
            'is_active' => true,
        ]);

        Sanctum::actingAs($this->customer);
    }

    public function test_fixed_price_booking_without_coupon_stores_totals(): void
    {
        $service = $this->createFixedService(price: 50000);

        $response = $this->postAppointment([
            ['catalog_item_id' => $service->id, 'quantity' => 2],
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.coupon', null)
            ->assertJsonPath('data.subtotal_amount', '100000.00')
            ->assertJsonPath('data.discount_amount', '0.00')
            ->assertJsonPath('data.final_amount', '100000.00');

        $this->assertDatabaseHas('appointments', [
            'customer_id' => $this->customer->id,
            'department_id' => $this->department->id,
            'coupon_id' => null,
            'subtotal_amount' => '100000.00',
            'discount_amount' => '0.00',
            'final_amount' => '100000.00',
        ]);
    }

    public function test_percentage_coupon_is_applied_with_maximum_discount_cap(): void
    {
        $service = $this->createFixedService(price: 50000);

        $coupon = $this->createCoupon([
            'code' => 'SAVE20',
            'discount_type' => Coupon::TYPE_PERCENTAGE,
            'discount_value' => 20,
            'maximum_discount_amount' => 15000,
        ]);

        $response = $this->postAppointment(
            items: [
                ['catalog_item_id' => $service->id, 'quantity' => 2],
            ],
            couponCode: 'save20',
        );

        $response
            ->assertCreated()
            ->assertJsonPath('data.coupon.id', $coupon->id)
            ->assertJsonPath('data.coupon.code', 'SAVE20')
            ->assertJsonPath('data.subtotal_amount', '100000.00')
            ->assertJsonPath('data.discount_amount', '15000.00')
            ->assertJsonPath('data.final_amount', '85000.00');

        $this->assertDatabaseHas('coupon_redemptions', [
            'coupon_id' => $coupon->id,
            'customer_id' => $this->customer->id,
            'subtotal_amount' => '100000.00',
            'discount_amount' => '15000.00',
            'final_amount' => '85000.00',
            'status' => 'applied',
        ]);

        $this->assertDatabaseHas('coupons', [
            'id' => $coupon->id,
            'used_count' => 1,
        ]);
    }

    public function test_fixed_coupon_never_reduces_total_below_zero(): void
    {
        $service = $this->createFixedService(price: 50000);

        $this->createCoupon([
            'code' => 'FIXED70',
            'discount_type' => Coupon::TYPE_FIXED,
            'discount_value' => 70000,
            'maximum_discount_amount' => null,
        ]);

        $this->postAppointment(
            items: [
                ['catalog_item_id' => $service->id, 'quantity' => 1],
            ],
            couponCode: 'FIXED70',
        )
            ->assertCreated()
            ->assertJsonPath('data.subtotal_amount', '50000.00')
            ->assertJsonPath('data.discount_amount', '50000.00')
            ->assertJsonPath('data.final_amount', '0.00');
    }

    public function test_item_restricted_coupon_discounts_only_eligible_items(): void
    {
        $eligibleService = $this->createFixedService(
            name: 'خدمة مشمولة',
            price: 40000,
        );

        $otherService = $this->createFixedService(
            name: 'خدمة غير مشمولة',
            price: 60000,
        );

        $coupon = $this->createCoupon([
            'code' => 'ONLYONE',
            'discount_type' => Coupon::TYPE_PERCENTAGE,
            'discount_value' => 50,
        ]);

        $coupon->catalogItems()->sync([$eligibleService->id]);

        $this->postAppointment(
            items: [
                ['catalog_item_id' => $eligibleService->id, 'quantity' => 1],
                ['catalog_item_id' => $otherService->id, 'quantity' => 1],
            ],
            couponCode: 'ONLYONE',
        )
            ->assertCreated()
            ->assertJsonPath('data.subtotal_amount', '100000.00')
            ->assertJsonPath('data.discount_amount', '20000.00')
            ->assertJsonPath('data.final_amount', '80000.00');
    }

    public function test_coupon_minimum_amount_is_checked_against_eligible_items(): void
    {
        $eligibleService = $this->createFixedService(
            name: 'خدمة مشمولة',
            price: 40000,
        );

        $otherService = $this->createFixedService(
            name: 'خدمة غير مشمولة',
            price: 60000,
        );

        $coupon = $this->createCoupon([
            'code' => 'MINIMUM',
            'minimum_order_amount' => 50000,
        ]);

        $coupon->catalogItems()->sync([$eligibleService->id]);

        $this->postAppointment(
            items: [
                ['catalog_item_id' => $eligibleService->id, 'quantity' => 1],
                ['catalog_item_id' => $otherService->id, 'quantity' => 1],
            ],
            couponCode: 'MINIMUM',
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('coupon_code');

        $this->assertDatabaseCount('appointments', 0);
        $this->assertDatabaseCount('coupon_redemptions', 0);
    }

    public function test_coupon_from_another_department_is_rejected(): void
    {
        $service = $this->createFixedService(price: 50000);
        $clinic = Department::factory()->clinic()->create();

        $this->createCoupon([
            'code' => 'CLINICONLY',
            'department_id' => $clinic->id,
        ]);

        $this->postAppointment(
            items: [
                ['catalog_item_id' => $service->id, 'quantity' => 1],
            ],
            couponCode: 'CLINICONLY',
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('coupon_code');

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_unavailable_or_unknown_coupon_is_rejected(): void
    {
        $service = $this->createFixedService(price: 50000);

        $this->createCoupon([
            'code' => 'EXPIRED',
            'expires_at' => now()->subMinute(),
        ]);

        foreach (['DOES-NOT-EXIST', 'EXPIRED'] as $code) {
            $this->postAppointment(
                items: [
                    ['catalog_item_id' => $service->id, 'quantity' => 1],
                ],
                couponCode: $code,
            )
                ->assertUnprocessable()
                ->assertJsonValidationErrors('coupon_code');
        }

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_coupon_usage_limits_are_enforced(): void
    {
        $service = $this->createFixedService(price: 50000);

        $coupon = $this->createCoupon([
            'code' => 'ONCE',
            'maximum_total_uses' => 1,
            'maximum_uses_per_customer' => 1,
        ]);

        $this->postAppointment(
            items: [
                ['catalog_item_id' => $service->id, 'quantity' => 1],
            ],
            couponCode: 'ONCE',
        )->assertCreated();

        $this->postAppointment(
            items: [
                ['catalog_item_id' => $service->id, 'quantity' => 1],
            ],
            couponCode: 'ONCE',
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('coupon_code');

        $this->assertDatabaseHas('coupons', [
            'id' => $coupon->id,
            'used_count' => 1,
        ]);
        $this->assertDatabaseCount('coupon_redemptions', 1);
    }

    public function test_coupon_cannot_be_applied_when_booking_contains_inspection_price(): void
    {
        $inspectionService = CatalogItem::factory()->create([
            'category_id' => $this->category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'خدمة بعد المعاينة',
            'price_type' => 'inspection',
            'price' => null,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);

        $this->createCoupon([
            'code' => 'INSPECT10',
        ]);

        $this->postAppointment(
            items: [
                ['catalog_item_id' => $inspectionService->id, 'quantity' => 1],
            ],
            couponCode: 'INSPECT10',
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('coupon_code');

        $this->assertDatabaseCount('appointments', 0);
    }

    public function test_cancelling_appointment_releases_coupon_usage_once(): void
    {
        $service = $this->createFixedService(price: 50000);

        $coupon = $this->createCoupon([
            'code' => 'RETURN10',
            'maximum_total_uses' => 1,
            'maximum_uses_per_customer' => 1,
        ]);

        $created = $this->postAppointment(
            items: [
                ['catalog_item_id' => $service->id, 'quantity' => 1],
            ],
            couponCode: 'RETURN10',
        )->assertCreated();

        $appointmentId = (int) $created->json('data.id');

        $this->postJson("/api/appointments/{$appointmentId}/cancel", [
            'reason' => 'تغيير الموعد',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');

        $this->assertDatabaseHas('coupon_redemptions', [
            'coupon_id' => $coupon->id,
            'appointment_id' => $appointmentId,
            'status' => 'cancelled',
        ]);

        $this->assertDatabaseHas('coupons', [
            'id' => $coupon->id,
            'used_count' => 0,
        ]);

        $this->postJson("/api/appointments/{$appointmentId}/cancel", [
            'reason' => 'محاولة ثانية',
        ])->assertUnprocessable();

        $this->assertDatabaseHas('coupons', [
            'id' => $coupon->id,
            'used_count' => 0,
        ]);
    }

    private function createFixedService(
        string $name = 'خدمة ثابتة السعر',
        int $price = 50000,
    ): CatalogItem {
        return CatalogItem::factory()->create([
            'category_id' => $this->category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => $name,
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => $price,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    private function createCoupon(array $overrides = []): Coupon
    {
        return Coupon::query()->create([
            'name' => 'كوبون اختبار',
            'code' => 'TEST10',
            'discount_type' => Coupon::TYPE_PERCENTAGE,
            'discount_value' => 10,
            'minimum_order_amount' => null,
            'maximum_discount_amount' => null,
            'department_id' => $this->department->id,
            'maximum_total_uses' => null,
            'maximum_uses_per_customer' => 1,
            'used_count' => 0,
            'starts_at' => now()->subMinute(),
            'expires_at' => now()->addMonth(),
            'is_active' => true,
            'notes' => null,
            ...$overrides,
        ]);
    }

    /**
     * @param  array<int, array{catalog_item_id: int, quantity: int}>  $items
     */
    private function postAppointment(
        array $items,
        ?string $couponCode = null,
    ) {
        $payload = [
            'department_id' => $this->department->id,
            'requested_start_at' => now()->addDays(2)->toIso8601String(),
            'items' => $items,
        ];

        if ($couponCode !== null) {
            $payload['coupon_code'] = $couponCode;
        }

        return $this->postJson('/api/appointments', $payload);
    }
}