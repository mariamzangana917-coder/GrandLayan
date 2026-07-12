<?php

namespace Database\Factories;

use App\Models\Department;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Department>
 */
class DepartmentFactory extends Factory
{
    protected $model = Department::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'code' => Department::SALON,
            'name' => 'الصالون',
            'is_active' => true,
            'sort_order' => 1,
        ];
    }

    public function salon(): static
    {
        return $this->state(fn (): array => [
            'code' => Department::SALON,
            'name' => 'الصالون',
            'sort_order' => 1,
        ]);
    }

    public function clinic(): static
    {
        return $this->state(fn (): array => [
            'code' => Department::CLINIC,
            'name' => 'العيادة',
            'sort_order' => 2,
        ]);
    }

    public function inactive(): static
    {
        return $this->state(fn (): array => [
            'is_active' => false,
        ]);
    }
}