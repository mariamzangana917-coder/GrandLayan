<?php

namespace Tests\Feature\Customer;

use App\Models\Banner;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class CustomerBannerListTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer', 'web');
    }

    public function test_customer_receives_only_current_active_banners_in_order(): void
    {
        $customer = User::factory()->create();
        $customer->assignRole('customer');
        Sanctum::actingAs($customer);

        $second = Banner::factory()->activeNow()->create(['sort_order' => 20]);
        $first = Banner::factory()->activeNow()->create(['sort_order' => 10]);

        Banner::factory()->scheduled()->create(['sort_order' => 1]);
        Banner::factory()->expired()->create(['sort_order' => 2]);
        Banner::factory()->inactive()->create(['sort_order' => 3]);

        $this->getJson('/api/customer/banners')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $first->id)
            ->assertJsonPath('data.1.id', $second->id);
    }

    public function test_customer_banner_endpoint_returns_at_most_five_items(): void
    {
        $customer = User::factory()->create();
        $customer->assignRole('customer');
        Sanctum::actingAs($customer);

        Banner::factory()->count(8)->activeNow()->create();

        $this->getJson('/api/customer/banners')
            ->assertOk()
            ->assertJsonCount(5, 'data');
    }
}
