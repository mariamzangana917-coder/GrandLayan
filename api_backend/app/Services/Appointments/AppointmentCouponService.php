<?php

namespace App\Services\Appointments;

use App\Models\Appointment;
use App\Models\CatalogItem;
use App\Models\Coupon;
use App\Models\CouponRedemption;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

class AppointmentCouponService
{
    /**
     * @param  Collection<int, CatalogItem>  $catalogItems
     * @param  array<int, array{catalog_item_id: int, quantity: int}>  $submittedItems
     * @return array{
     *     coupon: Coupon|null,
     *     subtotal_amount: string|null,
     *     discount_amount: string,
     *     final_amount: string|null
     * }
     */
    public function preparePricing(
        User $customer,
        int $departmentId,
        Collection $catalogItems,
        array $submittedItems,
        ?string $couponCode,
    ): array {
        [$subtotal, $lineTotals, $containsInspectionPrice] =
            $this->calculateSubtotal($catalogItems, $submittedItems);

        if ($couponCode === null || trim($couponCode) === '') {
            if ($containsInspectionPrice) {
                return [
                    'coupon' => null,
                    'subtotal_amount' => null,
                    'discount_amount' => $this->formatMoney(0),
                    'final_amount' => null,
                ];
            }

            return [
                'coupon' => null,
                'subtotal_amount' => $this->formatMoney($subtotal),
                'discount_amount' => $this->formatMoney(0),
                'final_amount' => $this->formatMoney($subtotal),
            ];
        }

        if ($containsInspectionPrice) {
            $this->couponError(
                'لا يمكن تطبيق كوبون على حجز يحتوي على خدمة سعرها يتحدد بعد المعاينة.'
            );
        }

        $normalizedCode = strtoupper(trim($couponCode));

        $coupon = Coupon::query()
            ->where('code', $normalizedCode)
            ->lockForUpdate()
            ->first();

        if (! $coupon instanceof Coupon) {
            $this->couponError('رمز الكوبون غير صحيح.');
        }

        $coupon->load('catalogItems:id');

        $this->validateAvailability($coupon);
        $this->validateDepartment($coupon, $departmentId);
        $this->synchronizeUsageCounter($coupon);
        $this->validateUsageLimits($coupon, $customer);

        $eligibleSubtotal = $this->calculateEligibleSubtotal(
            coupon: $coupon,
            lineTotals: $lineTotals,
            subtotal: $subtotal,
        );

        if ($eligibleSubtotal <= 0) {
            $this->couponError(
                'هذا الكوبون لا ينطبق على الخدمات أو البكجات المحددة في الحجز.'
            );
        }

        if (
            $coupon->minimum_order_amount !== null
            && $eligibleSubtotal < (float) $coupon->minimum_order_amount
        ) {
            $this->couponError(
                'قيمة الخدمات المشمولة بالكوبون أقل من الحد الأدنى المطلوب.'
            );
        }

        $discount = $this->calculateDiscount(
            coupon: $coupon,
            eligibleSubtotal: $eligibleSubtotal,
            subtotal: $subtotal,
        );

        $finalAmount = max(0, round($subtotal - $discount, 2));

        return [
            'coupon' => $coupon,
            'subtotal_amount' => $this->formatMoney($subtotal),
            'discount_amount' => $this->formatMoney($discount),
            'final_amount' => $this->formatMoney($finalAmount),
        ];
    }

    /**
     * @param  array{
     *     coupon: Coupon|null,
     *     subtotal_amount: string|null,
     *     discount_amount: string,
     *     final_amount: string|null
     * }  $pricing
     */
    public function recordRedemption(
        Coupon $coupon,
        User $customer,
        Appointment $appointment,
        array $pricing,
    ): void {
        $coupon->redemptions()->create([
            'customer_id' => $customer->id,
            'appointment_id' => $appointment->id,
            'subtotal_amount' => $pricing['subtotal_amount'],
            'discount_amount' => $pricing['discount_amount'],
            'final_amount' => $pricing['final_amount'],
            'redeemed_at' => now(),
            'status' => CouponRedemption::STATUS_APPLIED,
        ]);

        $coupon->forceFill([
            'used_count' => (int) $coupon->used_count + 1,
        ])->save();
    }

    public function releaseForAppointment(Appointment $appointment): void
    {
        $redemption = CouponRedemption::query()
            ->where('appointment_id', $appointment->id)
            ->lockForUpdate()
            ->first();

        if (
            ! $redemption instanceof CouponRedemption
            || $redemption->status !== CouponRedemption::STATUS_APPLIED
        ) {
            return;
        }

        $coupon = Coupon::query()
            ->whereKey($redemption->coupon_id)
            ->lockForUpdate()
            ->first();

        $redemption->update([
            'status' => CouponRedemption::STATUS_CANCELLED,
        ]);

        if ($coupon instanceof Coupon) {
            $coupon->forceFill([
                'used_count' => max(0, (int) $coupon->used_count - 1),
            ])->save();
        }
    }

    /**
     * @param  Collection<int, CatalogItem>  $catalogItems
     * @param  array<int, array{catalog_item_id: int, quantity: int}>  $submittedItems
     * @return array{0: float, 1: array<int, float>, 2: bool}
     */
    private function calculateSubtotal(
        Collection $catalogItems,
        array $submittedItems,
    ): array {
        $subtotal = 0.0;
        $lineTotals = [];
        $containsInspectionPrice = false;

        foreach ($submittedItems as $submittedItem) {
            $catalogItemId = (int) $submittedItem['catalog_item_id'];
            $quantity = (int) $submittedItem['quantity'];
            $catalogItem = $catalogItems->get($catalogItemId);

            if (! $catalogItem instanceof CatalogItem) {
                continue;
            }

            if (
                $catalogItem->price_type !== CatalogItem::PRICE_TYPE_FIXED
                || $catalogItem->price === null
            ) {
                $containsInspectionPrice = true;
                continue;
            }

            $lineTotal = round((float) $catalogItem->price * $quantity, 2);
            $lineTotals[$catalogItemId] = $lineTotal;
            $subtotal = round($subtotal + $lineTotal, 2);
        }

        return [$subtotal, $lineTotals, $containsInspectionPrice];
    }

    private function validateAvailability(Coupon $coupon): void
    {
        if (! $coupon->is_active) {
            $this->couponError('هذا الكوبون غير فعال.');
        }

        if ($coupon->starts_at !== null && now()->lt($coupon->starts_at)) {
            $this->couponError('هذا الكوبون لم يبدأ بعد.');
        }

        if ($coupon->expires_at !== null && now()->gte($coupon->expires_at)) {
            $this->couponError('انتهت صلاحية هذا الكوبون.');
        }
    }

    private function validateDepartment(
        Coupon $coupon,
        int $departmentId,
    ): void {
        if (
            $coupon->department_id !== null
            && (int) $coupon->department_id !== $departmentId
        ) {
            $this->couponError('هذا الكوبون غير صالح للقسم المحدد.');
        }
    }

    private function synchronizeUsageCounter(Coupon $coupon): void
    {
        $appliedUses = $coupon->redemptions()
            ->where('status', CouponRedemption::STATUS_APPLIED)
            ->count();

        if ((int) $coupon->used_count !== $appliedUses) {
            $coupon->forceFill([
                'used_count' => $appliedUses,
            ])->save();
        }
    }

    private function validateUsageLimits(
        Coupon $coupon,
        User $customer,
    ): void {
        if (
            $coupon->maximum_total_uses !== null
            && (int) $coupon->used_count >= (int) $coupon->maximum_total_uses
        ) {
            $this->couponError('تم استنفاد العدد الكلي لاستخدامات هذا الكوبون.');
        }

        $customerUses = $coupon->redemptions()
            ->where('customer_id', $customer->id)
            ->where('status', CouponRedemption::STATUS_APPLIED)
            ->count();

        if (
            $customerUses >= (int) $coupon->maximum_uses_per_customer
        ) {
            $this->couponError('تم استخدام هذا الكوبون بالعدد المسموح لهذه الزبونة.');
        }
    }

    /**
     * @param  array<int, float>  $lineTotals
     */
    private function calculateEligibleSubtotal(
        Coupon $coupon,
        array $lineTotals,
        float $subtotal,
    ): float {
        $restrictedItemIds = $coupon->catalogItems
            ->pluck('id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        if ($restrictedItemIds === []) {
            return $subtotal;
        }

        $eligibleSubtotal = 0.0;

        foreach ($restrictedItemIds as $catalogItemId) {
            $eligibleSubtotal = round(
                $eligibleSubtotal + ($lineTotals[$catalogItemId] ?? 0),
                2,
            );
        }

        return $eligibleSubtotal;
    }

    private function calculateDiscount(
        Coupon $coupon,
        float $eligibleSubtotal,
        float $subtotal,
    ): float {
        if ($coupon->isPercentage()) {
            $discount = round(
                $eligibleSubtotal * ((float) $coupon->discount_value / 100),
                2,
            );

            if ($coupon->maximum_discount_amount !== null) {
                $discount = min(
                    $discount,
                    (float) $coupon->maximum_discount_amount,
                );
            }
        } else {
            $discount = (float) $coupon->discount_value;
        }

        return round(min($discount, $eligibleSubtotal, $subtotal), 2);
    }

    private function formatMoney(float|int|string $amount): string
    {
        return number_format((float) $amount, 2, '.', '');
    }

    private function couponError(string $message): never
    {
        throw ValidationException::withMessages([
            'coupon_code' => [$message],
        ]);
    }
}
