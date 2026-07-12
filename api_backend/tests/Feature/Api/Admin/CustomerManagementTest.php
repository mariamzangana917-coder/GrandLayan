<?php

namespace Tests\Feature\Api\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class CustomerManagementTest extends TestCase
{
    use RefreshDatabase;

    private Role $managerRole;

    private Role $customerRole;

    protected function setUp(): void
    {
        parent::setUp();

        $this->managerRole = Role::create([
            'name' => 'manager',
            'guard_name' => 'web',
        ]);

        $this->customerRole = Role::create([
            'name' => 'customer',
            'guard_name' => 'web',
        ]);
    }

    public function test_guest_cannot_view_customers(): void
    {
        $response = $this->getJson('/api/admin/customers');

        $response->assertUnauthorized();
    }

    public function test_customer_cannot_view_customer_management_list(): void
    {
        $customer = User::factory()->create([
            'is_active' => true,
        ]);

        $customer->assignRole($this->customerRole);

        $response = $this
            ->actingAs($customer, 'sanctum')
            ->getJson('/api/admin/customers');

        $response->assertForbidden();
    }

    public function test_manager_can_view_only_customers(): void
    {
        $manager = User::factory()->create([
            'name' => 'مديرة كراند ليان',
            'is_active' => true,
        ]);

        $manager->assignRole($this->managerRole);

        $firstCustomer = User::factory()->create([
            'name' => 'مريم أحمد',
            'phone' => '07700000001',
            'email' => 'mariam@example.com',
            'is_active' => true,
        ]);

        $firstCustomer->assignRole($this->customerRole);

        $secondCustomer = User::factory()->create([
            'name' => 'سارة علي',
            'phone' => '07700000002',
            'email' => 'sara@example.com',
            'is_active' => false,
        ]);

        $secondCustomer->assignRole($this->customerRole);

        $response = $this
            ->actingAs($manager, 'sanctum')
            ->getJson('/api/admin/customers');

        $response
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonFragment([
                'id' => $firstCustomer->id,
                'name' => 'مريم أحمد',
                'phone' => '07700000001',
                'email' => 'mariam@example.com',
                'is_active' => true,
            ])
            ->assertJsonFragment([
                'id' => $secondCustomer->id,
                'name' => 'سارة علي',
                'phone' => '07700000002',
                'email' => 'sara@example.com',
                'is_active' => false,
            ])
            ->assertJsonMissing([
                'id' => $manager->id,
                'name' => 'مديرة كراند ليان',
            ]);
    }

    public function test_manager_can_search_customers_by_name(): void
    {
        $manager = User::factory()->create([
            'is_active' => true,
        ]);

        $manager->assignRole($this->managerRole);

        $matchingCustomer = User::factory()->create([
            'name' => 'مريم أحمد',
            'phone' => '07700000001',
            'email' => 'mariam@example.com',
            'is_active' => true,
        ]);

        $matchingCustomer->assignRole($this->customerRole);

        $otherCustomer = User::factory()->create([
            'name' => 'سارة علي',
            'phone' => '07700000002',
            'email' => 'sara@example.com',
            'is_active' => true,
        ]);

        $otherCustomer->assignRole($this->customerRole);

        $response = $this
            ->actingAs($manager, 'sanctum')
            ->getJson('/api/admin/customers?search=مريم');

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonFragment([
                'id' => $matchingCustomer->id,
                'name' => 'مريم أحمد',
            ])
            ->assertJsonMissing([
                'id' => $otherCustomer->id,
                'name' => 'سارة علي',
            ]);
    }

    public function test_manager_can_filter_customers_by_active_status(): void
    {
        $manager = User::factory()->create([
            'is_active' => true,
        ]);

        $manager->assignRole($this->managerRole);

        $activeCustomer = User::factory()->create([
            'name' => 'عميلة نشطة',
            'is_active' => true,
        ]);

        $activeCustomer->assignRole($this->customerRole);

        $inactiveCustomer = User::factory()->create([
            'name' => 'عميلة غير نشطة',
            'is_active' => false,
        ]);

        $inactiveCustomer->assignRole($this->customerRole);

        $response = $this
            ->actingAs($manager, 'sanctum')
            ->getJson('/api/admin/customers?is_active=1');

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonFragment([
                'id' => $activeCustomer->id,
                'name' => 'عميلة نشطة',
                'is_active' => true,
            ])
            ->assertJsonMissing([
                'id' => $inactiveCustomer->id,
                'name' => 'عميلة غير نشطة',
            ]);
    }
}