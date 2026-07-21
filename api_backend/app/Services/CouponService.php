<?php

namespace App\Services;

use App\Models\CatalogItem;
use App\Models\Coupon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CouponService
{
    /**
     * إنشاء كوبون جديد وربطه بالخدمات أو البكجات المحددة.
     *
     * @param  array<string, mixed>  $data
     */
    public function create(array $data): Coupon
    {
        return DB::transaction(function () use ($data): Coupon {
            $catalogItemIds = $this->extractCatalogItemIds($data);

            $this->validateCatalogItems(
                departmentId: $data['department_id'] ?? null,
                catalogItemIds: $catalogItemIds,
            );

            $coupon = Coupon::query()->create($data);

            if ($catalogItemIds !== []) {
                $coupon->catalogItems()->sync($catalogItemIds);
            }

            return $this->loadRelations($coupon);
        });
    }

    /**
     * تعديل الكوبون ومزامنة الخدمات أو البكجات المرتبطة به.
     *
     * @param  array<string, mixed>  $data
     */
    public function update(Coupon $coupon, array $data): Coupon
    {
        return DB::transaction(function () use ($coupon, $data): Coupon {
            $catalogItemIdsWereProvided = array_key_exists(
                'catalog_item_ids',
                $data
            );

            $catalogItemIds = $catalogItemIdsWereProvided
                ? $this->extractCatalogItemIds($data)
                : $coupon->catalogItems()
                    ->pluck('catalog_items.id')
                    ->map(fn ($id): int => (int) $id)
                    ->all();

            $departmentId = array_key_exists('department_id', $data)
                ? $data['department_id']
                : $coupon->department_id;

            $this->validateCatalogItems(
                departmentId: $departmentId,
                catalogItemIds: $catalogItemIds,
            );

            $coupon->update($data);

            if ($catalogItemIdsWereProvided) {
                $coupon->catalogItems()->sync($catalogItemIds);
            }

            return $this->loadRelations($coupon->fresh());
        });
    }

    /**
     * حذف الكوبون إذا لم يُستخدم سابقًا.
     *
     * إذا كان للكوبون سجل استخدام، يتم إيقافه بدل حذفه
     * للمحافظة على صحة التقارير والسجلات المالية.
     */
    public function delete(Coupon $coupon): bool
    {
        return DB::transaction(function () use ($coupon): bool {
            $hasRedemptions = $coupon->redemptions()->exists();

            if ($hasRedemptions) {
                $coupon->update([
                    'is_active' => false,
                ]);

                return false;
            }

            $coupon->catalogItems()->detach();

            return (bool) $coupon->delete();
        });
    }

    /**
     * فصل catalog_item_ids عن بيانات الكوبون الأساسية.
     *
     * @param  array<string, mixed>  $data
     * @return array<int>
     */
    private function extractCatalogItemIds(array &$data): array
    {
        $catalogItemIds = collect(
            $data['catalog_item_ids'] ?? []
        )
            ->map(fn ($id): int => (int) $id)
            ->unique()
            ->values()
            ->all();

        unset($data['catalog_item_ids']);

        return $catalogItemIds;
    }

    /**
     * التأكد من أن الخدمات والبكجات المحددة صالحة
     * وتنتمي إلى القسم المحدد في الكوبون.
     *
     * @param  array<int>  $catalogItemIds
     */
    private function validateCatalogItems(
        ?int $departmentId,
        array $catalogItemIds,
    ): void {
        if ($catalogItemIds === []) {
            return;
        }

        $items = CatalogItem::query()
            ->with('category:id,department_id')
            ->whereIn('id', $catalogItemIds)
            ->get();

        if ($items->count() !== count($catalogItemIds)) {
            throw ValidationException::withMessages([
                'catalog_item_ids' => [
                    'إحدى الخدمات أو البكجات المحددة غير موجودة.',
                ],
            ]);
        }

        if ($departmentId === null) {
            return;
        }

        $containsDifferentDepartment = $items->contains(
            fn (CatalogItem $item): bool => (int) $item->category->department_id !== $departmentId
        );

        if ($containsDifferentDepartment) {
            throw ValidationException::withMessages([
                'catalog_item_ids' => [
                    'جميع الخدمات والبكجات يجب أن تنتمي إلى القسم المحدد للكوبون.',
                ],
            ]);
        }
    }

    private function loadRelations(Coupon $coupon): Coupon
    {
        return $coupon->load([
            'department',
            'catalogItems',
        ]);
    }
}
