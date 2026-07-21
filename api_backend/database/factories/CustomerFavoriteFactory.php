<?php

namespace Database\Factories;

use App\Models\CatalogItem;
use App\Models\CustomerFavorite;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CustomerFavorite>
 */
class CustomerFavoriteFactory extends Factory
{
    /**
     * الموديل المرتبط بهذا الـ Factory.
     *
     * @var class-string<CustomerFavorite>
     */
    protected $model = CustomerFavorite::class;

    /**
     * القيم الافتراضية لسجل المفضلة.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'customer_id' => User::factory(),
            'catalog_item_id' => CatalogItem::factory(),
        ];
    }

    /**
     * ربط المفضلة بزبونة محددة.
     */
    public function forCustomer(User $customer): static
    {
        return $this->state(
            fn (): array => [
                'customer_id' => $customer->id,
            ],
        );
    }

    /**
     * ربط المفضلة بخدمة أو بكج محدد.
     */
    public function forCatalogItem(CatalogItem $catalogItem): static
    {
        return $this->state(
            fn (): array => [
                'catalog_item_id' => $catalogItem->id,
            ],
        );
    }
}
