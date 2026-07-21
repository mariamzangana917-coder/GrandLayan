<?php

namespace Database\Factories;

use App\Models\GiftCard;
use App\Models\GiftCardTransaction;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<GiftCardTransaction>
 */
class GiftCardTransactionFactory extends Factory
{
    protected $model = GiftCardTransaction::class;

    /**
     * Define the model's default state.
     *
     * The default transaction represents Gift Card issuance.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $amount = fake()->randomElement([
            25000,
            50000,
            75000,
            100000,
        ]);

        return [
            'gift_card_id' => GiftCard::factory()
                ->withBalance($amount),
            'appointment_id' => null,
            'performed_by_user_id' => auth()->id(),
            'type' => GiftCardTransaction::TYPE_ISSUANCE,
            'amount' => $amount,
            'balance_before' => 0,
            'balance_after' => $amount,
            'notes' => 'Initial Gift Card issuance.',
        ];
    }

    /**
     * Create a redemption transaction.
     */
    public function redemption(
        int|float|string $amount = 25000,
        int|float|string $balanceBefore = 100000
    ): static {
        $balanceAfter = (float) $balanceBefore - (float) $amount;

        return $this->state(fn (): array => [
            'type' => GiftCardTransaction::TYPE_REDEMPTION,
            'amount' => $amount,
            'balance_before' => $balanceBefore,
            'balance_after' => $balanceAfter,
            'notes' => 'Gift Card balance redeemed.',
        ]);
    }

    /**
     * Create a refund transaction.
     */
    public function refund(
        int|float|string $amount = 25000,
        int|float|string $balanceBefore = 50000
    ): static {
        $balanceAfter = (float) $balanceBefore + (float) $amount;

        return $this->state(fn (): array => [
            'type' => GiftCardTransaction::TYPE_REFUND,
            'amount' => $amount,
            'balance_before' => $balanceBefore,
            'balance_after' => $balanceAfter,
            'notes' => 'Amount returned to Gift Card balance.',
        ]);
    }

    /**
     * Create a manual credit adjustment.
     */
    public function adjustmentCredit(
        int|float|string $amount = 10000,
        int|float|string $balanceBefore = 50000
    ): static {
        $balanceAfter = (float) $balanceBefore + (float) $amount;

        return $this->state(fn (): array => [
            'type' => GiftCardTransaction::TYPE_ADJUSTMENT_CREDIT,
            'amount' => $amount,
            'balance_before' => $balanceBefore,
            'balance_after' => $balanceAfter,
            'notes' => 'Manual balance credit adjustment.',
        ]);
    }

    /**
     * Create a manual debit adjustment.
     */
    public function adjustmentDebit(
        int|float|string $amount = 10000,
        int|float|string $balanceBefore = 50000
    ): static {
        $balanceAfter = (float) $balanceBefore - (float) $amount;

        return $this->state(fn (): array => [
            'type' => GiftCardTransaction::TYPE_ADJUSTMENT_DEBIT,
            'amount' => $amount,
            'balance_before' => $balanceBefore,
            'balance_after' => $balanceAfter,
            'notes' => 'Manual balance debit adjustment.',
        ]);
    }

    /**
     * Create a cancellation transaction.
     */
    public function cancellation(
        int|float|string $balanceBefore = 50000
    ): static {
        return $this->state(fn (): array => [
            'type' => GiftCardTransaction::TYPE_CANCELLATION,
            'amount' => $balanceBefore,
            'balance_before' => $balanceBefore,
            'balance_after' => 0,
            'notes' => 'Remaining Gift Card balance cancelled.',
        ]);
    }
}
