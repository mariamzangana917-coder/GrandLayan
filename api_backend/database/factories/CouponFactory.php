<?php

namespace Database\Factories;

use App\Models\Coupon;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Coupon>
 */
class CouponFactory extends Factory
{
    /**
     * The model associated with the factory.
     *
     * @var class-string<Coupon>
     */
    protected $model = Coupon::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $discountType = fake()->randomElement([
            'fixed',
            'percentage',
        ]);

        return [
            'name' => 'كوبون '.fake()->unique()->words(2, true),

            'code' => Str::upper(
                fake()->unique()->bothify('GL-####-????')
            ),

            'discount_type' => $discountType,

            'discount_value' => $discountType === 'percentage'
                ? fake()->randomFloat(2, 5, 50)
                : fake()->randomFloat(2, 5000, 50000),

            'minimum_order_amount' => fake()->optional()->randomFloat(
                2,
                25000,
                150000
            ),

            'maximum_discount_amount' => $discountType === 'percentage'
                ? fake()->optional()->randomFloat(2, 10000, 50000)
                : null,

            'department_id' => null,

            'maximum_total_uses' => fake()->optional()->numberBetween(
                10,
                500
            ),

            'maximum_uses_per_customer' => fake()->numberBetween(
                1,
                5
            ),

            'used_count' => 0,

            'starts_at' => now()->subDay(),

            'expires_at' => now()->addMonth(),

            'is_active' => true,

            'notes' => fake()->optional()->sentence(),
        ];
    }

    /**
     * Create an inactive coupon.
     */
    public function inactive(): static
    {
        return $this->state(fn (): array => [
            'is_active' => false,
        ]);
    }

    /**
     * Create an expired coupon.
     */
    public function expired(): static
    {
        return $this->state(fn (): array => [
            'starts_at' => now()->subMonths(2),
            'expires_at' => now()->subDay(),
        ]);
    }

    /**
     * Create an upcoming coupon.
     */
    public function upcoming(): static
    {
        return $this->state(fn (): array => [
            'starts_at' => now()->addDay(),
            'expires_at' => now()->addMonth(),
        ]);
    }

    /**
     * Create a percentage coupon.
     */
    public function percentage(): static
    {
        return $this->state(fn (): array => [
            'discount_type' => 'percentage',
            'discount_value' => 20,
            'maximum_discount_amount' => 25000,
        ]);
    }

    /**
     * Create a fixed-value coupon.
     */
    public function fixed(): static
    {
        return $this->state(fn (): array => [
            'discount_type' => 'fixed',
            'discount_value' => 10000,
            'maximum_discount_amount' => null,
        ]);
    }
}
