<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Coupon\StoreCouponRequest;
use App\Http\Requests\Admin\Coupon\UpdateCouponRequest;
use App\Http\Resources\CouponResource;
use App\Models\Coupon;
use App\Services\CouponService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

class CouponController extends Controller
{
    public function __construct(
        private readonly CouponService $couponService,
    ) {}

    /**
     * عرض قائمة الكوبونات مع البحث والتصفية والترقيم.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'search' => [
                'nullable',
                'string',
                'max:150',
            ],

            'department_id' => [
                'nullable',
                'integer',
                'exists:departments,id',
            ],

            'discount_type' => [
                'nullable',
                'in:percentage,fixed',
            ],

            'is_active' => [
                'nullable',
                'boolean',
            ],

            'availability' => [
                'nullable',
                'in:available,upcoming,expired,exhausted',
            ],

            'sort_by' => [
                'nullable',
                'in:created_at,name,code,starts_at,expires_at,used_count',
            ],

            'sort_direction' => [
                'nullable',
                'in:asc,desc',
            ],

            'per_page' => [
                'nullable',
                'integer',
                'min:1',
                'max:100',
            ],
        ]);

        $query = Coupon::query()
            ->with([
                'department',
                'catalogItems',
            ]);

        if (! empty($validated['search'])) {
            $search = trim($validated['search']);

            $query->where(function ($builder) use ($search): void {
                $builder
                    ->where('name', 'ilike', "%{$search}%")
                    ->orWhere('code', 'ilike', "%{$search}%");
            });
        }

        if (isset($validated['department_id'])) {
            $query->where(
                'department_id',
                $validated['department_id']
            );
        }

        if (isset($validated['discount_type'])) {
            $query->where(
                'discount_type',
                $validated['discount_type']
            );
        }

        if (array_key_exists('is_active', $validated)) {
            $query->where(
                'is_active',
                $validated['is_active']
            );
        }

        $this->applyAvailabilityFilter(
            query: $query,
            availability: $validated['availability'] ?? null,
        );

        $sortBy = $validated['sort_by'] ?? 'created_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';
        $perPage = $validated['per_page'] ?? 15;

        $coupons = $query
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage)
            ->withQueryString();

        return CouponResource::collection($coupons);
    }

    /**
     * إنشاء كوبون جديد.
     */
    public function store(
        StoreCouponRequest $request,
    ): CouponResource {
        $coupon = $this->couponService->create(
            $request->validated()
        );

        return new CouponResource($coupon);
    }

    /**
     * عرض تفاصيل كوبون واحد.
     */
    public function show(Coupon $coupon): CouponResource
    {
        $coupon->load([
            'department',
            'catalogItems',
        ]);

        return new CouponResource($coupon);
    }

    /**
     * تعديل كوبون.
     */
    public function update(
        UpdateCouponRequest $request,
        Coupon $coupon,
    ): CouponResource {
        $coupon = $this->couponService->update(
            coupon: $coupon,
            data: $request->validated(),
        );

        return new CouponResource($coupon);
    }

    /**
     * حذف الكوبون أو تعطيله إذا كان مستخدمًا سابقًا.
     */
    public function destroy(Coupon $coupon): Response
    {
        $deleted = $this->couponService->delete($coupon);

        if (! $deleted) {
            return response([
                'message' => 'تم تعطيل الكوبون بدل حذفه لأنه مستخدم في سجلات سابقة.',
                'deleted' => false,
                'deactivated' => true,
            ]);
        }

        return response([
            'message' => 'تم حذف الكوبون بنجاح.',
            'deleted' => true,
            'deactivated' => false,
        ]);
    }

    /**
     * تطبيق فلتر حالة توفر الكوبون.
     */
    private function applyAvailabilityFilter(
        $query,
        ?string $availability,
    ): void {
        if ($availability === null) {
            return;
        }

        $now = now();

        match ($availability) {
            'available' => $query
                ->where('is_active', true)
                ->where(function ($builder) use ($now): void {
                    $builder
                        ->whereNull('starts_at')
                        ->orWhere('starts_at', '<=', $now);
                })
                ->where(function ($builder) use ($now): void {
                    $builder
                        ->whereNull('expires_at')
                        ->orWhere('expires_at', '>', $now);
                })
                ->where(function ($builder): void {
                    $builder
                        ->whereNull('maximum_total_uses')
                        ->orWhereColumn(
                            'used_count',
                            '<',
                            'maximum_total_uses'
                        );
                }),

            'upcoming' => $query
                ->where('is_active', true)
                ->whereNotNull('starts_at')
                ->where('starts_at', '>', $now),

            'expired' => $query
                ->whereNotNull('expires_at')
                ->where('expires_at', '<=', $now),

            'exhausted' => $query
                ->whereNotNull('maximum_total_uses')
                ->whereColumn(
                    'used_count',
                    '>=',
                    'maximum_total_uses'
                ),
        };
    }
}
