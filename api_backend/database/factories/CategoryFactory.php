<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Department;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Category>
 */
class CategoryFactory extends Factory
{
    protected $model = Category::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'department_id' => function (): int {
                $department = Department::query()->firstOrCreate(
                    [
                        'code' => Department::SALON,
                    ],
                    [
                        'name' => 'الصالون',
                        'is_active' => true,
                        'sort_order' => 1,
                    ],
                );

                return $department->id;
            },

            'name' => fake()->unique()->words(2, true),
            'description' => fake()->optional()->sentence(),
            'is_active' => true,
        ];
    }

    /**
     * ربط التصنيف بقسم محدد.
     */
    public function forDepartment(Department $department): static
    {
        return $this->state(
            fn (): array => [
                'department_id' => $department->id,
            ],
        );
    }

    /**
     * جعل التصنيف غير فعال.
     */
    public function inactive(): static
    {
        return $this->state(
            fn (): array => [
                'is_active' => false,
            ],
        );
    }
}
