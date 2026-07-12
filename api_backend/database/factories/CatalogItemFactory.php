<?php

namespace Database\Factories;

use App\Models\CatalogItem;
use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CatalogItem>
 */
class CatalogItemFactory extends Factory
{
    protected $model = CatalogItem::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'category_id' => Category::factory(),
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => fake()->unique()->words(2, true),
            'description' => fake()->optional()->sentence(),
            'instructions' => fake()->optional()->sentence(),
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => fake()->numberBetween(10, 500) * 1000,
            'duration_minutes' => fake()->randomElement([
                30,
                45,
                60,
                90,
                120,
            ]),
            'is_active' => true,
        ];
    }

    public function service(): static
    {
        return $this->state(fn (): array => [
            'type' => CatalogItem::TYPE_SERVICE,
        ]);
    }

    public function package(): static
    {
        return $this->state(fn (): array => [
            'type' => CatalogItem::TYPE_PACKAGE,
            'duration_minutes' => null,
        ]);
    }

    public function fixedPrice(?float $price = null): static
    {
        return $this->state(fn (): array => [
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => $price ?? 25000,
        ]);
    }

    public function inspectionPrice(): static
    {
        return $this->state(fn (): array => [
            'price_type' => CatalogItem::PRICE_TYPE_INSPECTION,
            'price' => null,
        ]);
    }

    public function inactive(): static
    {
        return $this->state(fn (): array => [
            'is_active' => false,
        ]);
    }
}