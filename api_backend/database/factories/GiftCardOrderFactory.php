<?php

namespace Database\Factories;

use App\Models\GiftCardDesign;
use App\Models\GiftCardOrder;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<GiftCardOrder>
 */
class GiftCardOrderFactory extends Factory
{
    protected $model = GiftCardOrder::class;

    /**
     * Define the model's default state.
     *
     * The default order is pending and has not been paid yet.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'customer_id' => User::factory(),
            'gift_card_design_id' => GiftCardDesign::factory(),
            'recipient_name' => fake()->name(),
            'recipient_phone' => '07'.fake()->numerify('#########'),
            'gift_message' => fake()->optional()->sentence(),
            'amount' => fake()->randomElement([
                25000,
                50000,
                75000,
                100000,
                150000,
                200000,
            ]),
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_ELECTRONIC,
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'payment_reference' => null,
            'status' => GiftCardOrder::STATUS_PENDING,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => null,
            'refunded_at' => null,
        ];
    }

    /**
     * Mark the order as paid.
     */
    public function paid(): static
    {
        return $this->state(fn (): array => [
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PAID,
            'payment_reference' => 'PAY-'.strtoupper(fake()->unique()->bothify('########????')),
            'paid_at' => now(),
        ]);
    }

    /**
     * Mark the order as completed.
     */
    public function completed(): static
    {
        return $this->state(fn (): array => [
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PAID,
            'payment_reference' => 'PAY-'.strtoupper(fake()->unique()->bothify('########????')),
            'status' => GiftCardOrder::STATUS_COMPLETED,
            'paid_at' => now()->subMinute(),
            'completed_at' => now(),
            'cancelled_at' => null,
            'refunded_at' => null,
        ]);
    }

    /**
     * Mark the order as cancelled.
     */
    public function cancelled(): static
    {
        return $this->state(fn (): array => [
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_PENDING,
            'payment_reference' => null,
            'status' => GiftCardOrder::STATUS_CANCELLED,
            'paid_at' => null,
            'completed_at' => null,
            'cancelled_at' => now(),
            'refunded_at' => null,
        ]);
    }

    /**
     * Mark the order as refunded.
     */
    public function refunded(): static
    {
        return $this->state(fn (): array => [
            'payment_status' => GiftCardOrder::PAYMENT_STATUS_REFUNDED,
            'payment_reference' => 'PAY-'.strtoupper(fake()->unique()->bothify('########????')),
            'status' => GiftCardOrder::STATUS_REFUNDED,
            'paid_at' => now()->subDays(2),
            'completed_at' => now()->subDays(2)->addMinute(),
            'cancelled_at' => null,
            'refunded_at' => now(),
        ]);
    }

    /**
     * Use cash as the payment method.
     */
    public function cash(): static
    {
        return $this->state(fn (): array => [
            'payment_method' => GiftCardOrder::PAYMENT_METHOD_CASH,
            'payment_reference' => null,
        ]);
    }

    /**
     * Set a specific order amount.
     */
    public function withAmount(int|float|string $amount): static
    {
        return $this->state(fn (): array => [
            'amount' => $amount,
        ]);
    }
}
