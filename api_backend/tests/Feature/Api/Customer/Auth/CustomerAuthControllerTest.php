<?php

namespace Tests\Feature\Api\Customer\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class CustomerAuthControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        app(PermissionRegistrar::class)
            ->forgetCachedPermissions();

        Role::findOrCreate('manager', 'web');
        Role::findOrCreate('customer', 'web');
    }

    public function test_customer_can_register(): void
    {
        $response = $this->postJson(
            '/api/customer/auth/register',
            [
                'name' => 'مريم زنگنة',
                'phone' => '07701234567',
                'email' => 'mariam@example.com',
                'password' => 'Password123',
                'password_confirmation' => 'Password123',
                'device_name' => 'Customer Android Phone',
            ]
        );

        $response
            ->assertCreated()
            ->assertJsonPath(
                'message',
                'تم إنشاء الحساب بنجاح.'
            )
            ->assertJsonPath(
                'data.user.name',
                'مريم زنگنة'
            )
            ->assertJsonPath(
                'data.user.phone',
                '07701234567'
            )
            ->assertJsonPath(
                'data.user.email',
                'mariam@example.com'
            )
            ->assertJsonPath(
                'data.user.role',
                'customer'
            )
            ->assertJsonPath(
                'data.token_type',
                'Bearer'
            )
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

        $customer = User::query()
            ->where('email', 'mariam@example.com')
            ->firstOrFail();

        $this->assertTrue(
            $customer->hasRole('customer')
        );

        $this->assertFalse(
            $customer->hasRole('manager')
        );

        $this->assertDatabaseHas('users', [
            'id' => $customer->id,
            'phone' => '07701234567',
            'email' => 'mariam@example.com',
            'is_active' => true,
        ]);

        $this->assertDatabaseHas(
            'personal_access_tokens',
            [
                'tokenable_id' => $customer->id,
                'name' => 'Customer Android Phone',
            ]
        );
    }

    public function test_registration_rejects_duplicate_phone(): void
    {
        $this->createCustomer([
            'phone' => '07701234567',
        ]);

        $response = $this->postJson(
            '/api/customer/auth/register',
            [
                'name' => 'زبونة ثانية',
                'phone' => '07701234567',
                'email' => 'second@example.com',
                'password' => 'Password123',
                'password_confirmation' => 'Password123',
                'device_name' => 'Customer Phone',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'phone',
            ]);
    }

    public function test_registration_rejects_duplicate_email(): void
    {
        $this->createCustomer([
            'email' => 'customer@example.com',
        ]);

        $response = $this->postJson(
            '/api/customer/auth/register',
            [
                'name' => 'زبونة ثانية',
                'phone' => '07801234567',
                'email' => 'customer@example.com',
                'password' => 'Password123',
                'password_confirmation' => 'Password123',
                'device_name' => 'Customer Phone',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'email',
            ]);
    }

    public function test_customer_can_login_using_email(): void
    {
        $customer = $this->createCustomer();

        $response = $this->postJson(
            '/api/customer/auth/login',
            [
                'login' => $customer->email,
                'password' => 'Password123',
                'device_name' => 'Customer iPhone',
            ]
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم تسجيل الدخول بنجاح.'
            )
            ->assertJsonPath(
                'data.user.id',
                $customer->id
            )
            ->assertJsonPath(
                'data.user.role',
                'customer'
            )
            ->assertJsonPath(
                'data.token_type',
                'Bearer'
            );

        $this->assertDatabaseHas(
            'personal_access_tokens',
            [
                'tokenable_id' => $customer->id,
                'name' => 'Customer iPhone',
            ]
        );
    }

    public function test_customer_can_login_using_phone(): void
    {
        $customer = $this->createCustomer();

        $response = $this->postJson(
            '/api/customer/auth/login',
            [
                'login' => $customer->phone,
                'password' => 'Password123',
                'device_name' => 'Customer Android',
            ]
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.user.id',
                $customer->id
            )
            ->assertJsonPath(
                'data.user.role',
                'customer'
            );
    }

    public function test_manager_cannot_login_to_customer_api(): void
    {
        $manager = User::query()->create([
            'name' => 'Grand Layan Manager',
            'phone' => '07501234567',
            'email' => 'manager@example.com',
            'password' => 'Password123',
            'is_active' => true,
        ]);

        $manager->assignRole('manager');

        $response = $this->postJson(
            '/api/customer/auth/login',
            [
                'login' => $manager->email,
                'password' => 'Password123',
                'device_name' => 'Manager Phone',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'login',
            ])
            ->assertJsonPath(
                'errors.login.0',
                'بيانات تسجيل الدخول غير صحيحة.'
            );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            0
        );
    }

    public function test_inactive_customer_cannot_login(): void
    {
        $customer = $this->createCustomer([
            'is_active' => false,
        ]);

        $response = $this->postJson(
            '/api/customer/auth/login',
            [
                'login' => $customer->email,
                'password' => 'Password123',
                'device_name' => 'Customer Phone',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'login',
            ]);

        $this->assertDatabaseCount(
            'personal_access_tokens',
            0
        );
    }

    public function test_authenticated_customer_can_get_profile(): void
    {
        $customer = $this->createCustomer();

        $token = $customer->createToken(
            'Customer Phone',
            ['customer']
        );

        $response = $this
            ->withToken($token->plainTextToken)
            ->getJson('/api/customer/auth/me');

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.user.id',
                $customer->id
            )
            ->assertJsonPath(
                'data.user.email',
                $customer->email
            )
            ->assertJsonPath(
                'data.user.phone',
                $customer->phone
            )
            ->assertJsonPath(
                'data.user.role',
                'customer'
            );
    }

    public function test_guest_cannot_access_customer_me_or_logout(): void
    {
        $this
            ->getJson('/api/customer/auth/me')
            ->assertUnauthorized();

        $this
            ->postJson('/api/customer/auth/logout')
            ->assertUnauthorized();
    }

    public function test_logout_deletes_only_current_customer_token(): void
    {
        $customer = $this->createCustomer();

        $firstTokenResult = $customer->createToken(
            'Customer Android',
            ['customer']
        );

        $secondTokenResult = $customer->createToken(
            'Customer iPhone',
            ['customer']
        );

        $firstToken = $firstTokenResult->plainTextToken;
        $secondToken = $secondTokenResult->plainTextToken;

        $firstTokenId = $firstTokenResult
            ->accessToken
            ->id;

        $secondTokenId = $secondTokenResult
            ->accessToken
            ->id;

        $response = $this
            ->withToken($firstToken)
            ->postJson('/api/customer/auth/logout');

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'تم تسجيل الخروج بنجاح.'
            );

        $this->assertDatabaseMissing(
            'personal_access_tokens',
            [
                'id' => $firstTokenId,
            ]
        );

        $this->assertDatabaseHas(
            'personal_access_tokens',
            [
                'id' => $secondTokenId,
                'tokenable_id' => $customer->id,
                'name' => 'Customer iPhone',
            ]
        );

        $this->app['auth']->forgetGuards();

        $this
            ->withToken($firstToken)
            ->getJson('/api/customer/auth/me')
            ->assertUnauthorized();

        $this->app['auth']->forgetGuards();

        $this
            ->withToken($secondToken)
            ->getJson('/api/customer/auth/me')
            ->assertOk()
            ->assertJsonPath(
                'data.user.id',
                $customer->id
            );
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function createCustomer(
        array $attributes = []
    ): User {
        $customer = User::query()->create(
            array_merge([
                'name' => 'Grand Layan Customer',
                'phone' => '07701234567',
                'email' => 'customer@example.com',
                'password' => 'Password123',
                'is_active' => true,
            ], $attributes)
        );

        $customer->assignRole('customer');

        return $customer;
    }
}
