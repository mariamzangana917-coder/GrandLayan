<?php

namespace Tests\Feature\Admin;

use App\Models\GiftCard;
use App\Models\GiftCardDesign;
use App\Models\GiftCardOrder;
use App\Models\GiftCardTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminGiftCardControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $manager;

    private User $customer;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager', 'web');
        Role::findOrCreate('customer', 'web');

        $this->manager = $this->createUser(
            name: 'مديرة كراند ليان',
            email: 'manager@giftcards.test',
            phone: '07700000001',
            role: 'manager'
        );

        $this->customer = $this->createUser(
            name: 'زبونة اختبار',
            email: 'customer@giftcards.test',
            phone: '07700000002',
            role: 'customer'
        );
    }

    public function test_guest_cannot_view_admin_gift_cards_list(): void
    {
        $response = $this->getJson('/api/admin/gift-cards');

        $response->assertUnauthorized();
    }

    public function test_customer_cannot_view_admin_gift_cards_list(): void
    {
        Sanctum::actingAs($this->customer);

        $response = $this->getJson('/api/admin/gift-cards');

        $response->assertForbidden();
    }

    public function test_manager_can_view_gift_cards_list(): void
    {
        Sanctum::actingAs($this->manager);

        $firstGiftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-LIST-0001'
        );

        $secondCustomer = $this->createUser(
            name: 'زبونة ثانية',
            email: 'second-customer@giftcards.test',
            phone: '07700000003',
            role: 'customer'
        );

        $secondGiftCard = $this->createGiftCard(
            customer: $secondCustomer,
            code: 'GL-LIST-0002'
        );

        $response = $this->getJson('/api/admin/gift-cards');

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 2)
            ->assertJsonFragment([
                'id' => $firstGiftCard->id,
                'code' => 'GL-LIST-0001',
            ])
            ->assertJsonFragment([
                'id' => $secondGiftCard->id,
                'code' => 'GL-LIST-0002',
            ]);
    }

    public function test_qr_token_is_not_returned_in_gift_cards_list(): void
    {
        Sanctum::actingAs($this->manager);

        $giftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-HIDDEN-QR',
            qrToken: 'secret-list-qr-token'
        );

        $response = $this->getJson('/api/admin/gift-cards');

        $response
            ->assertOk()
            ->assertJsonMissing([
                'qr_token' => $giftCard->qr_token,
            ]);

        $this->assertArrayNotHasKey(
            'qr_token',
            $response->json('data.0')
        );
    }

    public function test_manager_can_view_one_gift_card_with_qr_token(): void
    {
        Sanctum::actingAs($this->manager);

        $giftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-DETAILS-0001',
            qrToken: 'manager-visible-qr-token'
        );

        GiftCardTransaction::query()->create([
            'gift_card_id' => $giftCard->id,
            'appointment_id' => null,
            'performed_by_user_id' => null,
            'type' => GiftCardTransaction::TYPE_ISSUANCE,
            'amount' => $giftCard->initial_balance,
            'balance_before' => 0,
            'balance_after' => $giftCard->initial_balance,
            'notes' => 'Initial Gift Card issuance.',
        ]);

        $response = $this->getJson(
            "/api/admin/gift-cards/{$giftCard->id}"
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $giftCard->id)
            ->assertJsonPath('data.code', 'GL-DETAILS-0001')
            ->assertJsonPath(
                'data.qr_token',
                'manager-visible-qr-token'
            )
            ->assertJsonPath('data.transactions_count', 1)
            ->assertJsonCount(1, 'data.transactions')
            ->assertJsonPath(
                'data.transactions.0.type',
                GiftCardTransaction::TYPE_ISSUANCE
            );
    }

    public function test_guest_cannot_view_one_admin_gift_card(): void
    {
        $giftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-GUEST-DENIED'
        );

        $response = $this->getJson(
            "/api/admin/gift-cards/{$giftCard->id}"
        );

        $response->assertUnauthorized();
    }

    public function test_customer_cannot_view_one_admin_gift_card(): void
    {
        Sanctum::actingAs($this->customer);

        $giftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-CUSTOMER-DENIED'
        );

        $response = $this->getJson(
            "/api/admin/gift-cards/{$giftCard->id}"
        );

        $response->assertForbidden();
    }

    public function test_manager_can_search_gift_cards_by_code(): void
    {
        Sanctum::actingAs($this->manager);

        $matchingGiftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-SEARCH-7788'
        );

        $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-OTHER-9999'
        );

        $response = $this->getJson(
            '/api/admin/gift-cards?search=SEARCH-7788'
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $matchingGiftCard->id)
            ->assertJsonPath('data.0.code', 'GL-SEARCH-7788');
    }

    public function test_manager_can_search_gift_cards_by_customer_name(): void
    {
        Sanctum::actingAs($this->manager);

        $matchingCustomer = $this->createUser(
            name: 'سارة أحمد',
            email: 'sara@giftcards.test',
            phone: '07700000004',
            role: 'customer'
        );

        $otherCustomer = $this->createUser(
            name: 'نور علي',
            email: 'noor@giftcards.test',
            phone: '07700000005',
            role: 'customer'
        );

        $matchingGiftCard = $this->createGiftCard(
            customer: $matchingCustomer,
            code: 'GL-SARA-0001'
        );

        $this->createGiftCard(
            customer: $otherCustomer,
            code: 'GL-NOOR-0001'
        );

        $response = $this->getJson(
            '/api/admin/gift-cards?search='.urlencode('سارة')
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $matchingGiftCard->id);
    }

    public function test_manager_can_search_gift_cards_by_customer_phone(): void
    {
        Sanctum::actingAs($this->manager);

        $matchingCustomer = $this->createUser(
            name: 'زبونة الهاتف',
            email: 'phone-search@giftcards.test',
            phone: '07712345678',
            role: 'customer'
        );

        $matchingGiftCard = $this->createGiftCard(
            customer: $matchingCustomer,
            code: 'GL-PHONE-0001'
        );

        $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-PHONE-OTHER'
        );

        $response = $this->getJson(
            '/api/admin/gift-cards?search=07712345678'
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $matchingGiftCard->id);
    }

    public function test_manager_can_filter_gift_cards_by_status(): void
    {
        Sanctum::actingAs($this->manager);

        $activeGiftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-ACTIVE-0001',
            status: GiftCard::STATUS_ACTIVE
        );

        $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-REDEEMED-0001',
            status: GiftCard::STATUS_FULLY_REDEEMED,
            initialBalance: 100000,
            remainingBalance: 0,
            fullyRedeemedAt: now()
        );

        $response = $this->getJson(
            '/api/admin/gift-cards?status=active'
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $activeGiftCard->id)
            ->assertJsonPath(
                'data.0.status',
                GiftCard::STATUS_ACTIVE
            );
    }

    public function test_manager_can_filter_expired_gift_cards(): void
    {
        Sanctum::actingAs($this->manager);

        $expiredGiftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-EXPIRED-0001',
            status: GiftCard::STATUS_EXPIRED,
            issuedAt: now()->subYear()->subDay(),
            expiresAt: now()->subDay()
        );

        $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-FUTURE-0001'
        );

        $response = $this->getJson(
            '/api/admin/gift-cards?expired=1'
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $expiredGiftCard->id);
    }

    public function test_manager_can_filter_non_expired_gift_cards(): void
    {
        Sanctum::actingAs($this->manager);

        $nonExpiredGiftCard = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-NOT-EXPIRED-0001'
        );

        $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-OLD-EXPIRED-0001',
            status: GiftCard::STATUS_EXPIRED,
            issuedAt: now()->subYear()->subDay(),
            expiresAt: now()->subDay()
        );

        $response = $this->getJson(
            '/api/admin/gift-cards?not_expired=1'
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $nonExpiredGiftCard->id);
    }

    public function test_manager_can_filter_gift_cards_with_balance(): void
    {
        Sanctum::actingAs($this->manager);

        $giftCardWithBalance = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-WITH-BALANCE',
            initialBalance: 100000,
            remainingBalance: 50000
        );

        $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-WITHOUT-BALANCE',
            status: GiftCard::STATUS_FULLY_REDEEMED,
            initialBalance: 100000,
            remainingBalance: 0,
            fullyRedeemedAt: now()
        );

        $response = $this->getJson(
            '/api/admin/gift-cards?with_balance=1'
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $giftCardWithBalance->id);
    }

    public function test_manager_can_filter_gift_cards_without_balance(): void
    {
        Sanctum::actingAs($this->manager);

        $giftCardWithoutBalance = $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-ZERO-BALANCE',
            status: GiftCard::STATUS_FULLY_REDEEMED,
            initialBalance: 100000,
            remainingBalance: 0,
            fullyRedeemedAt: now()
        );

        $this->createGiftCard(
            customer: $this->customer,
            code: 'GL-POSITIVE-BALANCE',
            initialBalance: 100000,
            remainingBalance: 100000
        );

        $response = $this->getJson(
            '/api/admin/gift-cards?without_balance=1'
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath(
                'data.0.id',
                $giftCardWithoutBalance->id
            );
    }

    public function test_per_page_is_limited_to_one_hundred(): void
    {
        Sanctum::actingAs($this->manager);

        $response = $this->getJson(
            '/api/admin/gift-cards?per_page=500'
        );

        $response
            ->assertOk()
            ->assertJsonPath('meta.per_page', 100);
    }

    public function test_unknown_gift_card_returns_not_found(): void
    {
        Sanctum::actingAs($this->manager);

        $response = $this->getJson(
            '/api/admin/gift-cards/999999'
        );

        $response->assertNotFound();
    }

    private function createUser(
        string $name,
        string $email,
        string $phone,
        string $role
    ): User {
        $user = User::query()->create([
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'avatar' => null,
            'password' => Hash::make('Password123!'),
            'is_active' => true,
        ]);

        $user->assignRole($role);

        return $user;
    }

    private function createGiftCard(
        User $customer,
        string $code,
        string $qrToken = 'test-qr-token',
        string $status = GiftCard::STATUS_ACTIVE,
        int|float|string $initialBalance = 100000,
        int|float|string $remainingBalance = 100000,
        mixed $issuedAt = null,
        mixed $expiresAt = null,
        mixed $fullyRedeemedAt = null
    ): GiftCard {
        $design = GiftCardDesign::factory()->create();

        $order = GiftCardOrder::factory()
            ->completed()
            ->create([
                'customer_id' => $customer->id,
                'gift_card_design_id' => $design->id,
                'amount' => $initialBalance,
            ]);

        return GiftCard::query()->create([
            'gift_card_order_id' => $order->id,
            'code' => $code,
            'qr_token' => $qrToken.'-'.$order->id,
            'initial_balance' => $initialBalance,
            'remaining_balance' => $remainingBalance,
            'status' => $status,
            'issued_at' => $issuedAt ?? now(),
            'expires_at' => $expiresAt ?? now()->addYear(),
            'fully_redeemed_at' => $fullyRedeemedAt,
            'cancelled_at' => null,
        ]);
    }
}