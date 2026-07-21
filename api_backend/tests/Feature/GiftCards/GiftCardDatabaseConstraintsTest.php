<?php

namespace Tests\Feature\GiftCards;

use App\Models\GiftCard;
use App\Models\GiftCardDesign;
use App\Models\GiftCardOrder;
use App\Models\GiftCardTransaction;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class GiftCardDatabaseConstraintsTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function valid_gift_card_design_can_be_created(): void
    {
        $design = GiftCardDesign::factory()->create([
            'name' => 'هدية ذهبية',
            'amount' => 100000,
            'validity_days' => 365,
            'is_active' => true,
            'sort_order' => 1,
        ]);

        $this->assertDatabaseHas('gift_card_designs', [
            'id' => $design->id,
            'name' => 'هدية ذهبية',
            'amount' => 100000,
            'validity_days' => 365,
            'is_active' => true,
            'sort_order' => 1,
        ]);
    }

    #[Test]
    public function gift_card_design_amount_must_be_greater_than_zero(): void
    {
        $this->expectException(QueryException::class);

        GiftCardDesign::factory()->create([
            'amount' => 0,
        ]);
    }

    #[Test]
    public function gift_card_design_rejects_negative_amount(): void
    {
        $this->expectException(QueryException::class);

        GiftCardDesign::factory()->create([
            'amount' => -25000,
        ]);
    }

    #[Test]
    public function gift_card_design_validity_days_must_be_greater_than_zero(): void
    {
        $this->expectException(QueryException::class);

        GiftCardDesign::factory()->create([
            'validity_days' => 0,
        ]);
    }

    #[Test]
    public function gift_card_design_rejects_negative_validity_days(): void
    {
        $this->expectException(QueryException::class);

        GiftCardDesign::factory()->create([
            'validity_days' => -1,
        ]);
    }

    #[Test]
    public function gift_card_design_sort_order_cannot_be_negative(): void
    {
        $this->expectException(QueryException::class);

        GiftCardDesign::factory()->create([
            'sort_order' => -1,
        ]);
    }

    #[Test]
    public function gift_card_initial_balance_must_be_greater_than_zero(): void
    {
        $this->expectException(QueryException::class);

        GiftCard::factory()->create([
            'initial_balance' => 0,
            'remaining_balance' => 0,
        ]);
    }

    #[Test]
    public function gift_card_rejects_negative_initial_balance(): void
    {
        $this->expectException(QueryException::class);

        GiftCard::factory()->create([
            'initial_balance' => -100,
            'remaining_balance' => -100,
        ]);
    }

    #[Test]
    public function gift_card_rejects_negative_remaining_balance(): void
    {
        $this->expectException(QueryException::class);

        GiftCard::factory()->create([
            'remaining_balance' => -1,
        ]);
    }

    #[Test]
    public function remaining_balance_cannot_exceed_initial_balance(): void
    {
        $this->expectException(QueryException::class);

        GiftCard::factory()->create([
            'initial_balance' => 50000,
            'remaining_balance' => 60000,
        ]);
    }

    #[Test]
    public function gift_card_code_must_be_unique(): void
    {
        $giftCard = GiftCard::factory()->create();

        $this->expectException(QueryException::class);

        GiftCard::factory()->create([
            'code' => $giftCard->code,
        ]);
    }

    #[Test]
    public function gift_card_qr_token_must_be_unique(): void
    {
        $giftCard = GiftCard::factory()->create();

        $this->expectException(QueryException::class);

        GiftCard::factory()->create([
            'qr_token' => $giftCard->qr_token,
        ]);
    }

    #[Test]
    public function gift_card_rejects_invalid_status(): void
    {
        $this->expectException(QueryException::class);

        GiftCard::factory()->create([
            'status' => 'invalid-status',
        ]);
    }

    #[Test]
    public function valid_gift_card_order_can_be_created(): void
    {
        $order = GiftCardOrder::factory()->create();

        $this->assertDatabaseHas('gift_card_orders', [
            'id' => $order->id,
        ]);
    }

    #[Test]
    public function gift_card_order_rejects_invalid_payment_status(): void
    {
        $this->expectException(QueryException::class);

        GiftCardOrder::factory()->create([
            'payment_status' => 'invalid-status',
        ]);
    }

    #[Test]
    public function gift_card_order_rejects_invalid_status(): void
    {
        $this->expectException(QueryException::class);

        GiftCardOrder::factory()->create([
            'status' => 'invalid-status',
        ]);
    }

    #[Test]
    public function gift_card_order_amount_must_be_greater_than_zero(): void
    {
        $this->expectException(QueryException::class);

        GiftCardOrder::factory()->create([
            'amount' => 0,
        ]);
    }

    #[Test]
    public function gift_card_order_rejects_negative_amount(): void
    {
        $this->expectException(QueryException::class);

        GiftCardOrder::factory()->create([
            'amount' => -50000,
        ]);
    }

    #[Test]
    public function gift_card_order_requires_valid_customer(): void
    {
        $this->expectException(QueryException::class);

        GiftCardOrder::factory()->create([
            'customer_id' => 999999999,
        ]);
    }

    #[Test]
    public function gift_card_order_requires_valid_design(): void
    {
        $this->expectException(QueryException::class);

        GiftCardOrder::factory()->create([
            'gift_card_design_id' => 999999999,
        ]);
    }

    #[Test]
    public function valid_gift_card_transaction_can_be_created(): void
    {
        $transaction = GiftCardTransaction::factory()->create();

        $this->assertDatabaseHas('gift_card_transactions', [
            'id' => $transaction->id,
        ]);
    }

    #[Test]
    public function gift_card_transaction_rejects_invalid_type(): void
    {
        $this->expectException(QueryException::class);

        GiftCardTransaction::factory()->create([
            'type' => 'invalid-type',
        ]);
    }

    #[Test]
    public function gift_card_transaction_amount_must_be_greater_than_zero(): void
    {
        $this->expectException(QueryException::class);

        GiftCardTransaction::factory()->create([
            'amount' => 0,
        ]);
    }

    #[Test]
    public function gift_card_transaction_rejects_negative_amount(): void
    {
        $this->expectException(QueryException::class);

        GiftCardTransaction::factory()->create([
            'amount' => -1000,
        ]);
    }

    #[Test]
    public function gift_card_transaction_balance_before_cannot_be_negative(): void
    {
        $this->expectException(QueryException::class);

        GiftCardTransaction::factory()->create([
            'balance_before' => -1,
        ]);
    }

    #[Test]
    public function gift_card_transaction_balance_after_cannot_be_negative(): void
    {
        $this->expectException(QueryException::class);

        GiftCardTransaction::factory()->create([
            'balance_after' => -1,
        ]);
    }

    #[Test]
    public function gift_card_transaction_requires_valid_gift_card(): void
    {
        $this->expectException(QueryException::class);

        GiftCardTransaction::factory()->create([
            'gift_card_id' => 999999999,
        ]);
    }

    #[Test]
    public function gift_card_transaction_requires_valid_performed_by_user_when_present(): void
    {
        $this->expectException(QueryException::class);

        GiftCardTransaction::factory()->create([
            'performed_by' => 999999999,
        ]);
    }
}
