<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class ManagerUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $name = env('INITIAL_MANAGER_NAME');
        $email = env('INITIAL_MANAGER_EMAIL');
        $phone = env('INITIAL_MANAGER_PHONE');
        $password = env('INITIAL_MANAGER_PASSWORD');

        if (! $name || ! $email || ! $phone || ! $password) {
            throw new RuntimeException(
                'Initial manager credentials are missing from the .env file.'
            );
        }

        $manager = User::firstOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'phone' => $phone,
                'password' => Hash::make($password),
                'is_active' => true,
            ]
        );

        if (! $manager->hasRole('manager')) {
            $manager->assignRole('manager');
        }
    }
}
