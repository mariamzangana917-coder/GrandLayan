<?php

namespace Database\Factories;

use App\Models\GiftCardDesign;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<GiftCardDesign>
 */
class GiftCardDesignFactory extends Factory
{
    protected $model = GiftCardDesign::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->unique()->words(3, true),
            'description' => fake()->optional()->sentence(),
            'image_path' => 'gift-cards/designs/'.fake()->uuid().'.jpg',
            'amount' => fake()->randomElement([
                25000,
                50000,
                75000,
                100000,
                150000,
                200000,
            ]),
            'validity_days' => 365,
            'is_active' => true,
            'sort_order' => fake()->numberBetween(0, 100),
        ];
    }

    /**
     * Mark the design as inactive.
     */
    public function inactive(): static
    {
        return $this->state(fn (): array => [
            'is_active' => false,
        ]);
    }

    /**
     * Set a specific Gift Card amount.
     */
    public function withAmount(int|float|string $amount): static
    {
        return $this->state(fn (): array => [
            'amount' => $amount,
        ]);
    }

    /**
     * Set a specific validity period.
     */
    public function validFor(int $days): static
    {
        return $this->state(fn (): array => [
            'validity_days' => $days,
        ]);
    }
}
