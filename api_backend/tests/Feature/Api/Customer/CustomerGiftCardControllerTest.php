<?php

namespace Tests\Feature\Api\Customer;

use App\Models\GiftCard;
use App\Models\GiftCardOrder;
use App\Models\GiftCardTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class CustomerGiftCardControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('manager');
        Role::findOrCreate('customer');
    }

    public function test_guest_cannot_view_customer_gift_cards(): void
    {
        $this->getJson('/api/customer/gift-cards')
            ->assertUnauthorized();
    }

    public function test_manager_cannot_view_customer_gift_cards(): void
    {
        $manager = User::factory()->create();

        $manager->assignRole('manager');

        Sanctum::actingAs($manager);

        $this->getJson('/api/customer/gift-cards')
            ->assertForbidden();
    }

    public function test_customer_can_view_only_their_own_gift_cards(): void
    {
        $customer = $this->createCustomer();
        $otherCustomer = $this->createCustomer();

        $firstOwnedGiftCard = $this->createGiftCardForCustomer(
            $customer,
            [
                'code' => 'GL-OWN-0001',
            ]
        );

        $secondOwnedGiftCard = $this->createGiftCardForCustomer(
            $customer,
            [
                'code' => 'GL-OWN-0002',
            ]
        );

        $otherCustomerGiftCard = $this->createGiftCardForCustomer(
            $otherCustomer,
            [
                'code' => 'GL-OTHER-0001',
            ]
        );

        Sanctum::actingAs($customer);

        $response = $this->getJson('/api/customer/gift-cards');

        $response
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonFragment([
                'id' => $firstOwnedGiftCard->id,
                'code' => 'GL-OWN-0001',
            ])
            ->assertJsonFragment([
                'id' => $secondOwnedGiftCard->id,
                'code' => 'GL-OWN-0002',
            ])
            ->assertJsonMissing([
                'id' => $otherCustomerGiftCard->id,
                'code' => 'GL-OTHER-0001',
            ]);
    }

    public function test_customer_gift_card_list_does_not_expose_qr_token(): void
    {
        $customer = $this->createCustomer();

        $giftCard = $this->createGiftCardForCustomer(
            $customer,
            [
                'qr_token' => 'secure-list-qr-token',
            ]
        );

        Sanctum::actingAs($customer);

        $response = $this->getJson('/api/customer/gift-cards');

        $response
            ->assertOk()
            ->assertJsonPath('data.0.id', $giftCard->id)
            ->assertJsonMissingPath('data.0.qr_token')
            ->assertJsonMissing([
                'qr_token' => 'secure-list-qr-token',
            ]);
    }

    public function test_customer_can_view_their_own_gift_card_details_with_qr_token(): void
    {
        $customer = $this->createCustomer();

        $giftCard = $this->createGiftCardForCustomer(
            $customer,
            [
                'code' => 'GL-DETAILS-0001',
                'qr_token' => 'secure-details-qr-token',
                'initial_balance' => 100000,
                'remaining_balance' => 75000,
            ]
        );

        GiftCardTransaction::factory()
            ->for($giftCard)
            ->create();

        Sanctum::actingAs($customer);

        $response = $this->getJson(
            "/api/customer/gift-cards/{$giftCard->id}"
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $giftCard->id)
            ->assertJsonPath('data.code', 'GL-DETAILS-0001')
            ->assertJsonPath(
                'data.qr_token',
                'secure-details-qr-token'
            )
            ->assertJsonPath('data.initial_balance', '100000.00')
            ->assertJsonPath('data.remaining_balance', '75000.00')
            ->assertJsonPath('data.transactions_count', 1);
    }

    public function test_customer_cannot_view_another_customers_gift_card(): void
    {
        $customer = $this->createCustomer();
        $otherCustomer = $this->createCustomer();

        $otherCustomerGiftCard = $this->createGiftCardForCustomer(
            $otherCustomer
        );

        Sanctum::actingAs($customer);

        $this->getJson(
            "/api/customer/gift-cards/{$otherCustomerGiftCard->id}"
        )->assertNotFound();
    }

    public function test_unknown_gift_card_returns_not_found(): void
    {
        $customer = $this->createCustomer();

        Sanctum::actingAs($customer);

        $this->getJson('/api/customer/gift-cards/999999')
            ->assertNotFound();
    }

public function test_customer_can_view_their_gift_card_transactions_newest_first(): void
{
    $customer = $this->createCustomer();

    $manager = User::factory()->create();
    $manager->assignRole('manager');

    $giftCard = $this->createGiftCardForCustomer(
        $customer,
        [
            'initial_balance' => 100000,
            'remaining_balance' => 75000,
        ]
    );

    $oldestTransaction = GiftCardTransaction::factory()
        ->for($giftCard)
        ->create([
            'type' => GiftCardTransaction::TYPE_ISSUANCE,
            'amount' => 100000,
            'balance_before' => 0,
            'balance_after' => 100000,
            'notes' => 'First transaction.',
        ]);

    $middleTransaction = GiftCardTransaction::factory()
        ->for($giftCard)
        ->adjustmentDebit(
            amount: 50000,
            balanceBefore: 100000
        )
        ->create([
            'performed_by_user_id' => $manager->id,
            'notes' => 'Second transaction.',
        ]);

    $newestTransaction = GiftCardTransaction::factory()
        ->for($giftCard)
        ->adjustmentCredit(
            amount: 25000,
            balanceBefore: 50000
        )
        ->create([
            'performed_by_user_id' => $manager->id,
            'notes' => 'Third transaction.',
        ]);

    Sanctum::actingAs($customer);

    $response = $this->getJson(
        "/api/customer/gift-cards/{$giftCard->id}/transactions"
    );

    $response
        ->assertOk()
        ->assertJsonCount(3, 'data')
        ->assertJsonPath('data.0.id', $newestTransaction->id)
        ->assertJsonPath(
            'data.0.type',
            GiftCardTransaction::TYPE_ADJUSTMENT_CREDIT
        )
        ->assertJsonPath('data.1.id', $middleTransaction->id)
        ->assertJsonPath(
            'data.1.type',
            GiftCardTransaction::TYPE_ADJUSTMENT_DEBIT
        )
        ->assertJsonPath('data.2.id', $oldestTransaction->id)
        ->assertJsonPath(
            'data.2.type',
            GiftCardTransaction::TYPE_ISSUANCE
        );
}

    public function test_customer_cannot_view_transactions_of_another_customers_gift_card(): void
    {
        $customer = $this->createCustomer();
        $otherCustomer = $this->createCustomer();

        $otherCustomerGiftCard = $this->createGiftCardForCustomer(
            $otherCustomer
        );

        GiftCardTransaction::factory()
            ->for($otherCustomerGiftCard)
            ->create();

        Sanctum::actingAs($customer);

        $this->getJson(
            "/api/customer/gift-cards/{$otherCustomerGiftCard->id}/transactions"
        )->assertNotFound();
    }

    public function test_customer_gift_card_transactions_are_paginated(): void
    {
        $customer = $this->createCustomer();

        $giftCard = $this->createGiftCardForCustomer($customer);

        GiftCardTransaction::factory()
            ->count(21)
            ->for($giftCard)
            ->create();

        Sanctum::actingAs($customer);

        $response = $this->getJson(
            "/api/customer/gift-cards/{$giftCard->id}/transactions"
        );

        $response
            ->assertOk()
            ->assertJsonCount(20, 'data')
            ->assertJsonPath('meta.current_page', 1)
            ->assertJsonPath('meta.per_page', 20)
            ->assertJsonPath('meta.total', 21)
            ->assertJsonPath('meta.last_page', 2);
    }

    /**
     * Create a user with the customer role.
     */
    private function createCustomer(): User
    {
        $customer = User::factory()->create();

        $customer->assignRole('customer');

        return $customer;
    }

    /**
     * Create a completed Gift Card order and issued Gift Card
     * belonging to the specified customer.
     *
     * @param  array<string, mixed>  $giftCardAttributes
     */
    private function createGiftCardForCustomer(
        User $customer,
        array $giftCardAttributes = []
    ): GiftCard {
        $order = GiftCardOrder::factory()
            ->completed()
            ->for($customer, 'customer')
            ->create();

        return GiftCard::factory()
            ->for($order, 'order')
            ->create($giftCardAttributes);
    }
}
