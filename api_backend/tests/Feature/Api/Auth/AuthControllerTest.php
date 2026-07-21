<?php

namespace Tests\Feature\Api\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class AuthControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        app(PermissionRegistrar::class)->forgetCachedPermissions();

        Role::findOrCreate('manager', 'web');
        Role::findOrCreate('customer', 'web');
    }

    public function test_manager_can_login_using_email(): void
    {
        $manager = $this->createUser('manager');

        $response = $this->postJson('/api/auth/login', [
            'login' => $manager->email,
            'password' => 'Password123!',
            'device_name' => 'Manager Android Phone',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('message', 'تم تسجيل الدخول بنجاح.')
            ->assertJsonPath('data.user.id', $manager->id)
            ->assertJsonPath('data.user.role', 'manager')
            ->assertJsonPath('data.token_type', 'Bearer')
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
                    'token',
                    'token_type',
                ],
            ]);

        $this->assertDatabaseCount('personal_access_tokens', 1);
    }

    public function test_manager_can_login_using_phone(): void
    {
        $manager = $this->createUser('manager');

        $response = $this->postJson('/api/auth/login', [
            'login' => $manager->phone,
            'password' => 'Password123!',
            'device_name' => 'Manager iPhone',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.user.id', $manager->id)
            ->assertJsonPath('data.user.role', 'manager');

        $this->assertDatabaseCount('personal_access_tokens', 1);
    }

    public function test_login_rejects_incorrect_password(): void
    {
        $manager = $this->createUser('manager');

        $response = $this->postJson('/api/auth/login', [
            'login' => $manager->email,
            'password' => 'WrongPassword',
            'device_name' => 'Unknown Device',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['login'])
            ->assertJsonPath(
                'errors.login.0',
                'بيانات تسجيل الدخول غير صحيحة.'
            );

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_customer_cannot_login_to_admin_api(): void
    {
        $customer = $this->createUser('customer', [
            'email' => 'customer@example.com',
            'phone' => '07700000002',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'login' => $customer->email,
            'password' => 'Password123!',
            'device_name' => 'Customer Phone',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['login'])
            ->assertJsonPath(
                'errors.login.0',
                'بيانات تسجيل الدخول غير صحيحة.'
            );

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_inactive_manager_cannot_login(): void
    {
        $manager = $this->createUser('manager', [
            'email' => 'inactive.manager@example.com',
            'phone' => '07700000003',
            'is_active' => false,
        ]);

        $response = $this->postJson('/api/auth/login', [
            'login' => $manager->email,
            'password' => 'Password123!',
            'device_name' => 'Manager Phone',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['login']);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_authenticated_manager_can_get_own_profile(): void
    {
        $manager = $this->createUser('manager');
        $token = $manager->createToken('Manager Phone', ['admin']);

        $response = $this
            ->withToken($token->plainTextToken)
            ->getJson('/api/auth/me');

        $response
            ->assertOk()
            ->assertJsonPath('data.user.id', $manager->id)
            ->assertJsonPath('data.user.email', $manager->email)
            ->assertJsonPath('data.user.phone', $manager->phone)
            ->assertJsonPath('data.user.role', 'manager');
    }

    public function test_unauthenticated_user_cannot_access_me_or_logout(): void
    {
        $this->getJson('/api/auth/me')->assertUnauthorized();

        $this->postJson('/api/auth/logout')->assertUnauthorized();
    }

    public function test_manager_can_have_separate_tokens_for_multiple_devices(): void
    {
        $manager = $this->createUser('manager');

        $firstLogin = $this->postJson('/api/auth/login', [
            'login' => $manager->email,
            'password' => 'Password123!',
            'device_name' => 'Manager Android Phone',
        ]);

        $secondLogin = $this->postJson('/api/auth/login', [
            'login' => $manager->email,
            'password' => 'Password123!',
            'device_name' => 'Manager iPhone',
        ]);

        $firstLogin->assertOk();
        $secondLogin->assertOk();

        $this->assertNotSame(
            $firstLogin->json('data.token'),
            $secondLogin->json('data.token')
        );

        $this->assertDatabaseCount('personal_access_tokens', 2);

        $this->assertDatabaseHas('personal_access_tokens', [
            'tokenable_id' => $manager->id,
            'name' => 'Manager Android Phone',
        ]);

        $this->assertDatabaseHas('personal_access_tokens', [
            'tokenable_id' => $manager->id,
            'name' => 'Manager iPhone',
        ]);
    }

    public function test_logout_deletes_only_current_device_token(): void
    {
        $manager = $this->createUser('manager');

        $firstTokenResult = $manager->createToken(
            'Manager Android Phone',
            ['admin']
        );

        $secondTokenResult = $manager->createToken(
            'Manager iPhone',
            ['admin']
        );

        $firstToken = $firstTokenResult->plainTextToken;
        $secondToken = $secondTokenResult->plainTextToken;

        $firstTokenId = $firstTokenResult->accessToken->id;
        $secondTokenId = $secondTokenResult->accessToken->id;

        $this->assertDatabaseCount('personal_access_tokens', 2);

        $response = $this
            ->withToken($firstToken)
            ->postJson('/api/auth/logout');

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم تسجيل الخروج بنجاح.'
            );

        /*
         * The current device token must be deleted.
         */
        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $firstTokenId,
        ]);

        /*
         * The other device token must remain active.
         */
        $this->assertDatabaseHas('personal_access_tokens', [
            'id' => $secondTokenId,
            'tokenable_id' => $manager->id,
            'name' => 'Manager iPhone',
        ]);

        $this->assertDatabaseCount('personal_access_tokens', 1);

        /*
         * Clear Laravel's cached authentication guards before making
         * another request inside the same test.
         */
        $this->app['auth']->forgetGuards();

        $this
            ->withToken($firstToken)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();

        $this->app['auth']->forgetGuards();

        $this
            ->withToken($secondToken)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('data.user.id', $manager->id);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function createUser(
        string $role,
        array $attributes = []
    ): User {
        $user = User::query()->create(array_merge([
            'name' => 'Grand Layan User',
            'email' => 'manager@example.com',
            'phone' => '07700000001',
            'password' => 'Password123!',
            'is_active' => true,
        ], $attributes));

        $user->assignRole($role);

        return $user;
    }
}
