<?php

namespace Tests\Feature\GiftCards;

use App\Models\Appointment;
use App\Models\Department;
use App\Models\GiftCard;
use App\Models\GiftCardDesign;
use App\Models\GiftCardOrder;
use App\Models\GiftCardTransaction;
use App\Models\User;
use App\Services\GiftCards\IssueGiftCardService;
use App\Services\GiftCards\RedeemGiftCardService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class RedeemGiftCardServiceTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function gift_card_can_be_redeemed_using_its_readable_code(): void
    {
        $giftCard = $this->createIssuedGiftCard(100000);
        $appointment = Appointment::factory()->create();
        $manager = User::factory()->create();

        $transaction = app(RedeemGiftCardService::class)->execute(
            $giftCard->code,
            $appointment,
            25000,
            $manager,
            'استخدام جزء من رصيد البطاقة.'
        );

        $this->assertInstanceOf(
            GiftCardTransaction::class,
            $transaction
        );

        $this->assertDatabaseHas('gift_card_transactions', [
            'id' => $transaction->id,
            'gift_card_id' => $giftCard->id,
            'appointment_id' => $appointment->id,
            'performed_by_user_id' => $manager->id,
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
            'amount' => '25000.00',
            'balance_before' => '100000.00',
            'balance_after' => '75000.00',
            'notes' => 'استخدام جزء من رصيد البطاقة.',
        ]);

        $this->assertDatabaseHas('gift_cards', [
            'id' => $giftCard->id,
            'remaining_balance' => '75000.00',
            'status' => GiftCard::STATUS_ACTIVE,
            'fully_redeemed_at' => null,
        ]);
    }

    #[Test]
    public function gift_card_can_be_redeemed_using_its_qr_token(): void
    {
        $giftCard = $this->createIssuedGiftCard(80000);
        $appointment = Appointment::factory()->create();

        $transaction = app(RedeemGiftCardService::class)->execute(
            $giftCard->qr_token,
            $appointment->id,
            30000
        );

        $this->assertDatabaseHas('gift_card_transactions', [
            'id' => $transaction->id,
            'gift_card_id' => $giftCard->id,
            'appointment_id' => $appointment->id,
            'performed_by_user_id' => null,
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
            'amount' => '30000.00',
            'balance_before' => '80000.00',
            'balance_after' => '50000.00',
        ]);

        $this->assertSame(
            '50000.00',
            $giftCard->fresh()->remaining_balance
        );
    }

    #[Test]
    public function readable_code_is_accepted_without_matching_letter_case(): void
    {
        $giftCard = $this->createIssuedGiftCard(60000);
        $appointment = Appointment::factory()->create();

        $transaction = app(RedeemGiftCardService::class)->execute(
            strtolower($giftCard->code),
            $appointment,
            10000
        );

        $this->assertDatabaseHas('gift_card_transactions', [
            'id' => $transaction->id,
            'gift_card_id' => $giftCard->id,
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
            'amount' => '10000.00',
            'balance_before' => '60000.00',
            'balance_after' => '50000.00',
        ]);
    }

    #[Test]
    public function exact_remaining_balance_fully_redeems_the_gift_card(): void
    {
        $giftCard = $this->createIssuedGiftCard(50000);
        $appointment = Appointment::factory()->create();

        $transaction = app(RedeemGiftCardService::class)->execute(
            $giftCard->code,
            $appointment,
            50000
        );

        $freshGiftCard = $giftCard->fresh();

        $this->assertSame(
            GiftCard::STATUS_FULLY_REDEEMED,
            $freshGiftCard->status
        );

        $this->assertSame(
            '0.00',
            $freshGiftCard->remaining_balance
        );

        $this->assertNotNull(
            $freshGiftCard->fully_redeemed_at
        );

        $this->assertDatabaseHas('gift_card_transactions', [
            'id' => $transaction->id,
            'gift_card_id' => $giftCard->id,
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
            'amount' => '50000.00',
            'balance_before' => '50000.00',
            'balance_after' => '0.00',
        ]);
    }

    #[Test]
    public function redemption_is_rejected_when_balance_is_insufficient(): void
    {
        $giftCard = $this->createIssuedGiftCard(40000);
        $appointment = Appointment::factory()->create();

        try {
            app(RedeemGiftCardService::class)->execute(
                $giftCard->code,
                $appointment,
                50000
            );

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'amount',
                $exception->errors()
            );
        }

        $this->assertDatabaseHas('gift_cards', [
            'id' => $giftCard->id,
            'remaining_balance' => '40000.00',
            'status' => GiftCard::STATUS_ACTIVE,
        ]);

        $this->assertDatabaseMissing('gift_card_transactions', [
            'gift_card_id' => $giftCard->id,
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
        ]);
    }

    #[Test]
    public function expired_gift_card_cannot_be_redeemed(): void
    {
        $giftCard = $this->createIssuedGiftCard(70000);

        $giftCard->forceFill([
            'issued_at' => now()->subYears(2),
            'expires_at' => now()->subYear(),
        ])->save();

        $appointment = Appointment::factory()->create();

        try {
            app(RedeemGiftCardService::class)->execute(
                $giftCard->code,
                $appointment,
                10000
            );

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'gift_card',
                $exception->errors()
            );
        }

        $this->assertDatabaseHas('gift_cards', [
            'id' => $giftCard->id,
            'remaining_balance' => '70000.00',
        ]);

        $this->assertDatabaseMissing('gift_card_transactions', [
            'gift_card_id' => $giftCard->id,
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
        ]);
    }

    #[Test]
    public function fully_redeemed_gift_card_cannot_be_used_again(): void
    {
        $giftCard = $this->createIssuedGiftCard(30000);

        $department = Department::factory()
            ->salon()
            ->create();

        $firstAppointment = Appointment::factory()->create([
            'department_id' => $department->id,
        ]);

        app(RedeemGiftCardService::class)->execute(
            $giftCard->code,
            $firstAppointment,
            30000
        );

        $secondAppointment = Appointment::factory()->create([
            'department_id' => $department->id,
        ]);

        try {
            app(RedeemGiftCardService::class)->execute(
                $giftCard->code,
                $secondAppointment,
                10000
            );

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'gift_card',
                $exception->errors()
            );
        }

        $this->assertSame(
            1,
            GiftCardTransaction::query()
                ->where('gift_card_id', $giftCard->id)
                ->where(
                    'type',
                    GiftCardTransaction::TYPE_REDEMPTION
                )
                ->count()
        );
    }

    #[Test]
    public function unknown_gift_card_identifier_is_rejected(): void
    {
        $appointment = Appointment::factory()->create();

        try {
            app(RedeemGiftCardService::class)->execute(
                'GL-NOTF-OUND',
                $appointment,
                10000
            );

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'gift_card',
                $exception->errors()
            );
        }

        $this->assertDatabaseMissing('gift_card_transactions', [
            'appointment_id' => $appointment->id,
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
        ]);
    }

    #[Test]
    public function nonexistent_appointment_is_rejected(): void
    {
        $giftCard = $this->createIssuedGiftCard(90000);

        try {
            app(RedeemGiftCardService::class)->execute(
                $giftCard->code,
                999999999,
                10000
            );

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'appointment_id',
                $exception->errors()
            );
        }

        $this->assertSame(
            '90000.00',
            $giftCard->fresh()->remaining_balance
        );

        $this->assertDatabaseMissing('gift_card_transactions', [
            'gift_card_id' => $giftCard->id,
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
        ]);
    }

    #[Test]
    public function zero_amount_is_rejected(): void
    {
        $giftCard = $this->createIssuedGiftCard(50000);
        $appointment = Appointment::factory()->create();

        try {
            app(RedeemGiftCardService::class)->execute(
                $giftCard->code,
                $appointment,
                0
            );

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'amount',
                $exception->errors()
            );
        }

        $this->assertSame(
            '50000.00',
            $giftCard->fresh()->remaining_balance
        );
    }

    #[Test]
    public function negative_amount_is_rejected(): void
    {
        $giftCard = $this->createIssuedGiftCard(50000);
        $appointment = Appointment::factory()->create();

        try {
            app(RedeemGiftCardService::class)->execute(
                $giftCard->code,
                $appointment,
                -10000
            );

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'amount',
                $exception->errors()
            );
        }

        $this->assertSame(
            '50000.00',
            $giftCard->fresh()->remaining_balance
        );
    }

    #[Test]
    public function non_numeric_amount_is_rejected(): void
    {
        $giftCard = $this->createIssuedGiftCard(50000);
        $appointment = Appointment::factory()->create();

        try {
            app(RedeemGiftCardService::class)->execute(
                $giftCard->code,
                $appointment,
                'not-a-number'
            );

            $this->fail(
                'Expected validation exception was not thrown.'
            );
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey(
                'amount',
                $exception->errors()
            );
        }

        $this->assertSame(
            '50000.00',
            $giftCard->fresh()->remaining_balance
        );
    }

    #[Test]
    public function redemption_result_loads_expected_relationships(): void
    {
        $giftCard = $this->createIssuedGiftCard(100000);
        $appointment = Appointment::factory()->create();
        $manager = User::factory()->create();

        $transaction = app(RedeemGiftCardService::class)->execute(
            $giftCard->code,
            $appointment,
            20000,
            $manager
        );

        $this->assertTrue(
            $transaction->relationLoaded('giftCard')
        );

        $this->assertTrue(
            $transaction->relationLoaded('appointment')
        );

        $this->assertTrue(
            $transaction->relationLoaded('performedBy')
        );

        $this->assertTrue(
            $transaction->giftCard->relationLoaded('order')
        );

        $this->assertTrue(
            $transaction->giftCard->order->relationLoaded('design')
        );
    }

    /**
     * Create a valid active Gift Card through the real issuance service.
     */
    private function createIssuedGiftCard(
        int $amount
    ): GiftCard {
        $design = GiftCardDesign::factory()->create([
            'amount' => $amount,
            'validity_days' => 365,
            'is_active' => true,
        ]);

        $order = GiftCardOrder::factory()->create([
            'gift_card_design_id' => $design->id,
            'amount' => $amount,
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'payment_reference' => null,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);

        return app(IssueGiftCardService::class)->execute($order);
    }
}
