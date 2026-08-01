<?php

namespace Tests\Feature\Api\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class ManagerProfileTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        app(PermissionRegistrar::class)->forgetCachedPermissions();

        Role::findOrCreate('manager', 'web');
        Role::findOrCreate('customer', 'web');
    }

    public function test_guest_cannot_update_manager_profile(): void
    {
        $this->putJson('/api/auth/profile', $this->validPayload())
            ->assertUnauthorized();
    }

    public function test_customer_cannot_update_manager_profile(): void
    {
        $customer = $this->createUser('customer', [
            'phone' => '07700000001',
            'email' => 'customer@example.com',
        ]);

        Sanctum::actingAs($customer);

        $this->putJson('/api/auth/profile', $this->validPayload())
            ->assertForbidden();
    }

    public function test_inactive_manager_cannot_update_profile(): void
    {
        $manager = $this->createUser('manager', [
            'phone' => '07700000002',
            'email' => 'inactive-manager@example.com',
            'is_active' => false,
        ]);

        Sanctum::actingAs($manager);

        $this->putJson('/api/auth/profile', $this->validPayload())
            ->assertForbidden();
    }

    public function test_manager_can_update_only_own_profile_fields(): void
    {
        $manager = $this->createUser('manager', [
            'name' => 'مديرة قديمة',
            'phone' => '07700000003',
            'email' => 'old-manager@example.com',
            'password' => Hash::make('OriginalPassword123'),
        ]);

        $passwordHash = $manager->password;

        Sanctum::actingAs($manager);

        $response = $this->putJson('/api/auth/profile', [
            'name' => '  مديرة كراند ليان  ',
            'phone' => '0770 123 4567',
            'email' => 'MANAGER@EXAMPLE.COM',
            // These fields must be ignored by validation/mass assignment.
            'role' => 'customer',
            'is_active' => false,
            'password' => 'ChangedByProfileEndpoint',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.user.name', 'مديرة كراند ليان')
            ->assertJsonPath('data.user.phone', '07701234567')
            ->assertJsonPath('data.user.email', 'manager@example.com')
            ->assertJsonPath('data.user.role', 'manager')
            ->assertJsonStructure([
                'message',
                'data' => [
                    'user' => [
                        'id',
                        'name',
                        'email',
                        'phone',
                        'avatar',
                        'role',
                    ],
                ],
            ]);

        $manager->refresh();

        $this->assertSame('مديرة كراند ليان', $manager->name);
        $this->assertSame('07701234567', $manager->phone);
        $this->assertSame('manager@example.com', $manager->email);
        $this->assertTrue((bool) $manager->is_active);
        $this->assertSame($passwordHash, $manager->password);
        $this->assertTrue($manager->hasRole('manager'));
        $this->assertFalse($manager->hasRole('customer'));
    }

    public function test_profile_rejects_duplicate_phone_and_email(): void
    {
        $manager = $this->createUser('manager', [
            'phone' => '07700000004',
            'email' => 'manager-two@example.com',
        ]);

        $this->createUser('customer', [
            'phone' => '07800000000',
            'email' => 'used@example.com',
        ]);

        Sanctum::actingAs($manager);

        $this->putJson('/api/auth/profile', [
            'name' => 'مديرة كراند ليان',
            'phone' => '07800000000',
            'email' => 'used@example.com',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['phone', 'email']);
    }

    public function test_manager_can_upload_avatar_and_old_file_is_removed(): void
    {
        Storage::fake('public');

        Storage::disk('public')->put(
            'managers/avatars/old-avatar.jpg',
            'old-image'
        );

        $manager = $this->createUser('manager', [
            'phone' => '07700000005',
            'email' => 'avatar-manager@example.com',
            'avatar' => 'managers/avatars/old-avatar.jpg',
        ]);

        Sanctum::actingAs($manager);

        $response = $this->post(
            '/api/auth/profile/avatar',
            [
                'avatar' => UploadedFile::fake()->image(
                    'manager-avatar.jpg',
                    700,
                    700
                ),
            ],
            ['Accept' => 'application/json']
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.user.role', 'manager');

        $manager->refresh();

        $this->assertNotNull($manager->avatar);
        Storage::disk('public')->assertExists($manager->avatar);
        Storage::disk('public')->assertMissing(
            'managers/avatars/old-avatar.jpg'
        );
    }

    public function test_manager_can_delete_avatar_idempotently(): void
    {
        Storage::fake('public');

        Storage::disk('public')->put(
            'managers/avatars/current-avatar.jpg',
            'current-image'
        );

        $manager = $this->createUser('manager', [
            'phone' => '07700000006',
            'email' => 'delete-avatar@example.com',
            'avatar' => 'managers/avatars/current-avatar.jpg',
        ]);

        Sanctum::actingAs($manager);

        $this->deleteJson('/api/auth/profile/avatar')
            ->assertOk()
            ->assertJsonPath('data.user.avatar', null);

        $manager->refresh();

        $this->assertNull($manager->avatar);
        Storage::disk('public')->assertMissing(
            'managers/avatars/current-avatar.jpg'
        );

        // Repeating deletion must remain safe and successful.
        $this->deleteJson('/api/auth/profile/avatar')
            ->assertOk()
            ->assertJsonPath('data.user.avatar', null);
    }

    /**
     * @param array<string, mixed> $attributes
     */
    private function createUser(
        string $role,
        array $attributes = []
    ): User {
        $user = User::factory()->create(array_merge([
            'name' => 'مستخدمة اختبار',
            'phone' => fake()->unique()->numerify('07#########'),
            'email' => fake()->unique()->safeEmail(),
            'is_active' => true,
        ], $attributes));

        $user->assignRole($role);

        return $user;
    }

    /**
     * @return array<string, string>
     */
    private function validPayload(): array
    {
        return [
            'name' => 'مديرة كراند ليان',
            'phone' => '07701234567',
            'email' => 'manager@example.com',
        ];
    }
}
