<?php

namespace Tests\Feature\Catalog;

use App\Models\CatalogItem;
use App\Models\CatalogItemImage;
use App\Models\Category;
use App\Models\Department;
use App\Models\PackageItem;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CatalogDatabaseConstraintsTest extends TestCase
{
    use RefreshDatabase;

    public function test_category_name_must_be_unique_inside_same_department(): void
    {
        $salon = $this->createDepartment(
            Department::SALON,
            'الصالون',
            1
        );

        Category::query()->create([
            'department_id' => $salon->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);

        $this->expectException(QueryException::class);

        Category::query()->create([
            'department_id' => $salon->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);
    }

    public function test_category_name_uniqueness_is_case_insensitive(): void
    {
        $salon = $this->createDepartment(
            Department::SALON,
            'الصالون',
            1
        );

        Category::query()->create([
            'department_id' => $salon->id,
            'name' => 'Hair',
            'is_active' => true,
        ]);

        $this->expectException(QueryException::class);

        Category::query()->create([
            'department_id' => $salon->id,
            'name' => 'HAIR',
            'is_active' => true,
        ]);
    }

    public function test_same_category_name_is_allowed_in_different_departments(): void
    {
        $salon = $this->createDepartment(
            Department::SALON,
            'الصالون',
            1
        );

        $clinic = $this->createDepartment(
            Department::CLINIC,
            'العيادة',
            2
        );

        $salonCategory = Category::query()->create([
            'department_id' => $salon->id,
            'name' => 'العناية',
            'is_active' => true,
        ]);

        $clinicCategory = Category::query()->create([
            'department_id' => $clinic->id,
            'name' => 'العناية',
            'is_active' => true,
        ]);

        $this->assertNotSame(
            $salonCategory->id,
            $clinicCategory->id
        );

        $this->assertDatabaseCount('categories', 2);
    }

    public function test_fixed_price_item_requires_a_price(): void
    {
        $category = $this->createCategory();

        $this->expectException(QueryException::class);

        CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => null,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);
    }

    public function test_fixed_price_item_rejects_negative_price(): void
    {
        $category = $this->createCategory();

        $this->expectException(QueryException::class);

        CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'قص',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => -1000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);
    }

    public function test_inspection_item_must_not_store_a_price(): void
    {
        $category = $this->createCategory();

        $this->expectException(QueryException::class);

        CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'صبغ',
            'price_type' => CatalogItem::PRICE_TYPE_INSPECTION,
            'price' => 50000,
            'duration_minutes' => 120,
            'is_active' => true,
        ]);
    }

    public function test_inspection_item_is_valid_when_price_is_null(): void
    {
        $category = $this->createCategory();

        $item = CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'صبغ',
            'price_type' => CatalogItem::PRICE_TYPE_INSPECTION,
            'price' => null,
            'duration_minutes' => 120,
            'is_active' => true,
        ]);

        $this->assertDatabaseHas('catalog_items', [
            'id' => $item->id,
            'price_type' => CatalogItem::PRICE_TYPE_INSPECTION,
            'price' => null,
        ]);
    }

    public function test_catalog_item_rejects_unsupported_type(): void
    {
        $category = $this->createCategory();

        $this->expectException(QueryException::class);

        CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => 'product',
            'name' => 'منتج غير مسموح',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 10000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);
    }

    public function test_duration_must_be_greater_than_zero_when_provided(): void
    {
        $category = $this->createCategory();

        $this->expectException(QueryException::class);

        CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => 'سشوار',
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 0,
            'is_active' => true,
        ]);
    }

    public function test_only_one_primary_image_is_allowed_per_catalog_item(): void
    {
        $service = $this->createService();

        CatalogItemImage::query()->create([
            'catalog_item_id' => $service->id,
            'path' => 'catalog/services/first.webp',
            'is_primary' => true,
            'sort_order' => 1,
        ]);

        $this->expectException(QueryException::class);

        CatalogItemImage::query()->create([
            'catalog_item_id' => $service->id,
            'path' => 'catalog/services/second.webp',
            'is_primary' => true,
            'sort_order' => 2,
        ]);
    }

    public function test_multiple_non_primary_images_are_allowed(): void
    {
        $service = $this->createService();

        CatalogItemImage::query()->create([
            'catalog_item_id' => $service->id,
            'path' => 'catalog/services/first.webp',
            'is_primary' => false,
            'sort_order' => 1,
        ]);

        CatalogItemImage::query()->create([
            'catalog_item_id' => $service->id,
            'path' => 'catalog/services/second.webp',
            'is_primary' => false,
            'sort_order' => 2,
        ]);

        $this->assertDatabaseCount('catalog_item_images', 2);
    }

    public function test_package_can_contain_service_from_same_department(): void
    {
        $category = $this->createCategory();

        $package = $this->createPackage($category);
        $service = $this->createService($category);

        $packageItem = PackageItem::query()->create([
            'package_id' => $package->id,
            'service_id' => $service->id,
            'quantity' => 1,
            'notes' => 'ضمن الباكج',
        ]);

        $this->assertDatabaseHas('package_items', [
            'id' => $packageItem->id,
            'package_id' => $package->id,
            'service_id' => $service->id,
            'quantity' => 1,
        ]);
    }

    public function test_package_cannot_contain_service_from_another_department(): void
    {
        $salon = $this->createDepartment(
            Department::SALON,
            'الصالون',
            1
        );

        $clinic = $this->createDepartment(
            Department::CLINIC,
            'العيادة',
            2
        );

        $salonCategory = Category::query()->create([
            'department_id' => $salon->id,
            'name' => 'بكجات العرايس',
            'is_active' => true,
        ]);

        $clinicCategory = Category::query()->create([
            'department_id' => $clinic->id,
            'name' => 'الفيلر',
            'is_active' => true,
        ]);

        $package = $this->createPackage($salonCategory);
        $clinicService = $this->createService(
            $clinicCategory,
            'الفيلر الكوري'
        );

        $this->expectException(QueryException::class);

        PackageItem::query()->create([
            'package_id' => $package->id,
            'service_id' => $clinicService->id,
            'quantity' => 1,
        ]);
    }

    public function test_package_id_must_reference_package_type(): void
    {
        $category = $this->createCategory();

        $firstService = $this->createService(
            $category,
            'مكياج'
        );

        $secondService = $this->createService(
            $category,
            'تسريحة'
        );

        $this->expectException(QueryException::class);

        PackageItem::query()->create([
            'package_id' => $firstService->id,
            'service_id' => $secondService->id,
            'quantity' => 1,
        ]);
    }

    public function test_service_id_must_reference_service_type(): void
    {
        $category = $this->createCategory();

        $firstPackage = $this->createPackage(
            $category,
            'باكج 350'
        );

        $secondPackage = $this->createPackage(
            $category,
            'باكج 450'
        );

        $this->expectException(QueryException::class);

        PackageItem::query()->create([
            'package_id' => $firstPackage->id,
            'service_id' => $secondPackage->id,
            'quantity' => 1,
        ]);
    }

    public function test_package_item_quantity_must_be_greater_than_zero(): void
    {
        $category = $this->createCategory();

        $package = $this->createPackage($category);
        $service = $this->createService($category);

        $this->expectException(QueryException::class);

        PackageItem::query()->create([
            'package_id' => $package->id,
            'service_id' => $service->id,
            'quantity' => 0,
        ]);
    }

    private function createDepartment(
        string $code,
        string $name,
        int $sortOrder
    ): Department {
        return Department::query()->create([
            'code' => $code,
            'name' => $name,
            'is_active' => true,
            'sort_order' => $sortOrder,
        ]);
    }

    private function createCategory(): Category
    {
        $salon = $this->createDepartment(
            Department::SALON,
            'الصالون',
            1
        );

        return Category::query()->create([
            'department_id' => $salon->id,
            'name' => 'الشعر',
            'is_active' => true,
        ]);
    }

    private function createService(
        ?Category $category = null,
        string $name = 'قص'
    ): CatalogItem {
        $category ??= $this->createCategory();

        return CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_SERVICE,
            'name' => $name,
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 25000,
            'duration_minutes' => 30,
            'is_active' => true,
        ]);
    }

    private function createPackage(
        ?Category $category = null,
        string $name = 'باكج 350'
    ): CatalogItem {
        $category ??= $this->createCategory();

        return CatalogItem::query()->create([
            'category_id' => $category->id,
            'type' => CatalogItem::TYPE_PACKAGE,
            'name' => $name,
            'price_type' => CatalogItem::PRICE_TYPE_FIXED,
            'price' => 350000,
            'duration_minutes' => 180,
            'is_active' => true,
        ]);
    }
}
