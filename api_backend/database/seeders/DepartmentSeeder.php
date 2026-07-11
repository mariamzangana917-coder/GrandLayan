<?php

namespace Database\Seeders;

use App\Models\Department;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DepartmentSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::transaction(function (): void {
            Department::query()->updateOrCreate(
                ['code' => Department::SALON],
                [
                    'name' => 'الصالون',
                    'is_active' => true,
                    'sort_order' => 1,
                ]
            );

            Department::query()->updateOrCreate(
                ['code' => Department::CLINIC],
                [
                    'name' => 'العيادة',
                    'is_active' => true,
                    'sort_order' => 2,
                ]
            );
        });
    }
}