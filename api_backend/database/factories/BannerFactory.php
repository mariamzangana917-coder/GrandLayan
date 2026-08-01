<?php

namespace Database\Factories;

use App\Enums\BannerActionType;
use App\Models\Banner;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Banner>
 */
class BannerFactory extends Factory
{
    protected $model = Banner::class;

    public function definition(): array
    {
        return [
            'title' => fake()->sentence(3),
            'subtitle' => fake()->optional()->sentence(6),
            'image_path' => 'banners/'.fake()->uuid().'.webp',
            'action_type' => BannerActionType::None,
            'action_target_id' => null,
            'external_url' => null,
            'starts_at' => now()->subHour(),
            'ends_at' => now()->addWeek(),
            'sort_order' => fake()->numberBetween(0, 20),
            'is_active' => true,
        ];
    }

    public function activeNow(): static
    {
        return $this->state(fn (): array => [
            'is_active' => true,
            'starts_at' => now()->subMinute(),
            'ends_at' => now()->addDay(),
        ]);
    }

    public function scheduled(): static
    {
        return $this->state(fn (): array => [
            'is_active' => true,
            'starts_at' => now()->addDay(),
            'ends_at' => now()->addWeek(),
        ]);
    }

    public function expired(): static
    {
        return $this->state(fn (): array => [
            'is_active' => true,
            'starts_at' => now()->subWeek(),
            'ends_at' => now()->subMinute(),
        ]);
    }

    public function inactive(): static
    {
        return $this->state(fn (): array => [
            'is_active' => false,
        ]);
    }
}
