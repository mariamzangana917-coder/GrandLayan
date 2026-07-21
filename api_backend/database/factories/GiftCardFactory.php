<?php

namespace Database\Factories;

use App\Models\GiftCard;
use App\Models\GiftCardOrder;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<GiftCard>
 */
class GiftCardFactory extends Factory
{
    protected $model = GiftCard::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $balance = fake()->randomElement([
            25000,
            50000,
            75000,
            100000,
            150000,
            200000,
        ]);

        return [
            'gift_card_order_id' => GiftCardOrder::factory()->completed(),
            'code' => $this->generateCode(),
            'qr_token' => (string) Str::uuid(),
            'initial_balance' => $balance,
            'remaining_balance' => $balance,
            'status' => GiftCard::STATUS_ACTIVE,
            'issued_at' => now(),
            'expires_at' => now()->addYear(),
            'fully_redeemed_at' => null,
            'cancelled_at' => null,
        ];
    }

    /**
     * Generate a readable unique Gift Card code.
     */
    private function generateCode(): string
    {
        return sprintf(
            'GL-%s-%s-%s',
            strtoupper(fake()->unique()->bothify('??##')),
            strtoupper(fake()->bothify('####')),
            strtoupper(fake()->bothify('??##'))
        );
    }

    /**
     * Set a specific initial and remaining balance.
     */
    public function withBalance(int|float|string $balance): static
    {
        return $this->state(fn (): array => [
            'initial_balance' => $balance,
            'remaining_balance' => $balance,
        ]);
    }

    /**
     * Set different initial and remaining balances.
     */
    public function partiallyRedeemed(
        int|float|string $initialBalance = 100000,
        int|float|string $remainingBalance = 50000
    ): static {
        return $this->state(fn (): array => [
            'initial_balance' => $initialBalance,
            'remaining_balance' => $remainingBalance,
            'status' => GiftCard::STATUS_ACTIVE,
            'fully_redeemed_at' => null,
            'cancelled_at' => null,
        ]);
    }

    /**
     * Mark the Gift Card as fully redeemed.
     */
    public function fullyRedeemed(
        int|float|string $initialBalance = 100000
    ): static {
        return $this->state(fn (): array => [
            'initial_balance' => $initialBalance,
            'remaining_balance' => 0,
            'status' => GiftCard::STATUS_FULLY_REDEEMED,
            'fully_redeemed_at' => now(),
            'cancelled_at' => null,
        ]);
    }

    /**
     * Mark the Gift Card as expired.
     */
    public function expired(): static
    {
        return $this->state(fn (): array => [
            'status' => GiftCard::STATUS_EXPIRED,
            'issued_at' => now()->subYear()->subDay(),
            'expires_at' => now()->subDay(),
            'fully_redeemed_at' => null,
            'cancelled_at' => null,
        ]);
    }

    /**
     * Mark the Gift Card as cancelled.
     */
    public function cancelled(): static
    {
        return $this->state(fn (): array => [
            'status' => GiftCard::STATUS_CANCELLED,
            'cancelled_at' => now(),
            'fully_redeemed_at' => null,
        ]);
    }
}
