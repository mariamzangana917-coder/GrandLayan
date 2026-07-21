<?php

namespace Tests\Feature\GiftCards;

use App\Models\GiftCard;
use App\Models\GiftCardDesign;
use App\Models\GiftCardOrder;
use App\Models\GiftCardTransaction;
use App\Models\User;
use App\Services\GiftCards\IssueGiftCardService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class IssueGiftCardServiceTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function cash_order_can_be_confirmed_and_gift_card_issued(): void
    {
        $design = GiftCardDesign::factory()->create([
            'amount' => 100000,
            'validity_days' => 365,
            'is_active' => true,
        ]);

        $customer = User::factory()->create();

        $order = GiftCardOrder::factory()->create([
            'customer_id' => $customer->id,
            'gift_card_design_id' => $design->id,
            'amount' => $design->amount,
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'payment_reference' => null,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        $giftCard = app(IssueGiftCardService::class)->execute($order);

        $this->assertInstanceOf(GiftCard::class, $giftCard);

        $this->assertDatabaseHas('gift_cards', [
            'id' => $giftCard->id,
            'gift_card_order_id' => $order->id,
            'initial_balance' => '100000.00',
            'remaining_balance' => '100000.00',
            'status' => GiftCard::STATUS_ACTIVE,
        ]);

        $this->assertDatabaseHas('gift_card_orders', [
            'id' => $order->id,
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PAID,
            'payment_reference' => null,
            'status' => GiftCardOrder::STATUS_COMPLETED,
        ]);

        $this->assertNotNull($order->fresh()->paid_at);
        $this->assertNotNull($order->fresh()->completed_at);
    }

    #[Test]
    public function issuance_creates_an_issuance_transaction(): void
    {
        $design = GiftCardDesign::factory()->create([
            'amount' => 75000,
        ]);

        $order = GiftCardOrder::factory()->create([
            'gift_card_design_id' => $design->id,
            'amount' => $design->amount,
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        $giftCard = app(IssueGiftCardService::class)->execute($order);

        $this->assertDatabaseHas('gift_card_transactions', [
            'gift_card_id' => $giftCard->id,
            'appointment_id' => null,
            'performed_by_user_id' => null,
            'type' => GiftCardTransaction::TYPE_ISSUANCE,
            'amount' => '75000.00',
            'balance_before' => '0.00',
            'balance_after' => '75000.00',
        ]);

        $this->assertSame(
            1,
            GiftCardTransaction::query()
                ->where('gift_card_id', $giftCard->id)
                ->where('type', GiftCardTransaction::TYPE_ISSUANCE)
                ->count()
        );
    }

    #[Test]
    public function electronic_order_requires_a_payment_reference(): void
    {
        $order = GiftCardOrder::factory()->create([
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_ELECTRONIC,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'payment_reference' => null,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        try {
            app(IssueGiftCardService::class)->execute($order);

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'payment_reference',
                $exception->errors()
            );
        }

        $this->assertDatabaseMissing('gift_cards', [
            'gift_card_order_id' => $order->id,
        ]);

        $this->assertDatabaseHas('gift_card_orders', [
            'id' => $order->id,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'status' => GiftCardOrder::STATUS_PENDING,
        ]);
    }

    #[Test]
    public function electronic_order_can_be_issued_with_payment_reference(): void
    {
        $order = GiftCardOrder::factory()->create([
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_ELECTRONIC,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'payment_reference' => null,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        $giftCard = app(IssueGiftCardService::class)->execute(
            $order,
            'PAY-GL-2026-000001'
        );

        $this->assertDatabaseHas('gift_card_orders', [
            'id' => $order->id,
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_ELECTRONIC,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PAID,
            'payment_reference' => 'PAY-GL-2026-000001',
            'status' => GiftCardOrder::STATUS_COMPLETED,
        ]);

        $this->assertDatabaseHas('gift_cards', [
            'id' => $giftCard->id,
            'gift_card_order_id' => $order->id,
        ]);
    }

    #[Test]
    public function repeated_issue_calls_return_the_same_gift_card(): void
    {
        $order = GiftCardOrder::factory()->create([
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        $service = app(IssueGiftCardService::class);

        $firstGiftCard = $service->execute($order);
        $secondGiftCard = $service->execute($order->fresh());

        $this->assertSame(
            $firstGiftCard->id,
            $secondGiftCard->id
        );

        $this->assertSame(
            1,
            GiftCard::query()
                ->where('gift_card_order_id', $order->id)
                ->count()
        );

        $this->assertSame(
            1,
            GiftCardTransaction::query()
                ->where('gift_card_id', $firstGiftCard->id)
                ->where('type', GiftCardTransaction::TYPE_ISSUANCE)
                ->count()
        );
    }

    #[Test]
    public function cancelled_order_cannot_be_issued(): void
    {
        $order = GiftCardOrder::factory()->create([
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'status' => GiftCardOrder::STATUS_CANCELLED,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => now(),
            'refunded_at' => null,
        ]);

        $this->expectException(ValidationException::class);

        app(IssueGiftCardService::class)->execute($order);
    }

    #[Test]
    public function failed_payment_order_cannot_be_issued(): void
    {
        $order = GiftCardOrder::factory()->create([
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_ELECTRONIC,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_FAILED,
            'payment_reference' => null,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        $this->expectException(ValidationException::class);

        app(IssueGiftCardService::class)->execute(
            $order,
            'FAILED-PAYMENT-REFERENCE'
        );
    }

    #[Test]
    public function expiry_date_uses_the_design_validity_days(): void
    {
        $design = GiftCardDesign::factory()->create([
            'validity_days' => 180,
        ]);

        $order = GiftCardOrder::factory()->create([
            'gift_card_design_id' => $design->id,
            'amount' => $design->amount,
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        $giftCard = app(IssueGiftCardService::class)->execute($order);

        $this->assertSame(
            180,
            (int) $giftCard->issued_at->diffInDays(
                $giftCard->expires_at
            )
        );
    }

    #[Test]
    public function issued_card_has_readable_code_and_secure_qr_token(): void
    {
        $order = GiftCardOrder::factory()->create([
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        $giftCard = app(IssueGiftCardService::class)->execute($order);

        $this->assertMatchesRegularExpression(
            '/^GL-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/',
            $giftCard->code
        );

        $this->assertSame(64, strlen($giftCard->qr_token));

        $this->assertMatchesRegularExpression(
            '/^[a-f0-9]{64}$/',
            $giftCard->qr_token
        );
    }
}
