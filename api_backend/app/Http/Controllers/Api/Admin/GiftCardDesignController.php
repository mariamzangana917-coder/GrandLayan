<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Admin\StoreGiftCardDesignRequest;
use App\Http\Requests\Api\Admin\UpdateGiftCardDesignRequest;
use App\Http\Resources\GiftCardDesignResource;
use App\Models\GiftCardDesign;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Throwable;

class GiftCardDesignController extends Controller
{
    /**
     * Display all Gift Card designs.
     */
    public function index(
        Request $request
    ): AnonymousResourceCollection {
        $designs = GiftCardDesign::query()
            ->withCount('orders')
            ->when(
                $request->has('is_active'),
                function ($query) use ($request): void {
                    $query->where(
                        'is_active',
                        filter_var(
                            $request->input('is_active'),
                            FILTER_VALIDATE_BOOLEAN
                        )
                    );
                }
            )
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return GiftCardDesignResource::collection($designs);
    }

    /**
     * Store a new Gift Card design.
     */
    public function store(
        StoreGiftCardDesignRequest $request
    ): JsonResponse {

        $validated = $request->safe()->except('image');

        $imagePath = null;

        try {

            if ($request->hasFile('image')) {
                $imagePath = $request
                    ->file('image')
                    ->store('gift-card-designs', 'public');

                $validated['image_path'] = $imagePath;
            }

            $design = DB::transaction(
                fn () => GiftCardDesign::query()->create(
                    $validated
                )
            );

            $design->loadCount('orders');

            return response()->json([
                'message' => 'تم إنشاء تصميم بطاقة الهدية بنجاح.',
                'data' => new GiftCardDesignResource($design),
            ], 201);

        } catch (Throwable $exception) {

            if ($imagePath !== null) {
                Storage::disk('public')->delete($imagePath);
            }

            throw $exception;
        }
    }

    /**
     * Display one Gift Card design.
     */
    public function show(
        GiftCardDesign $giftCardDesign
    ): GiftCardDesignResource {

        $giftCardDesign->loadCount('orders');

        return new GiftCardDesignResource(
            $giftCardDesign
        );
    }
        /**
     * Update a Gift Card design.
     */
    public function update(
        UpdateGiftCardDesignRequest $request,
        GiftCardDesign $giftCardDesign
    ): JsonResponse {

        $validated = $request->safe()->except('image');

        $oldImagePath = $giftCardDesign->image_path;
        $newImagePath = null;

        try {

            if ($request->hasFile('image')) {

                $newImagePath = $request
                    ->file('image')
                    ->store('gift-card-designs', 'public');

                $validated['image_path'] = $newImagePath;
            }

            DB::transaction(
                fn () => $giftCardDesign->update(
                    $validated
                )
            );

            if (
                $newImagePath !== null
                && $oldImagePath !== null
            ) {
                Storage::disk('public')->delete(
                    $oldImagePath
                );
            }

            $giftCardDesign
                ->refresh()
                ->loadCount('orders');

            return response()->json([
                'message' => 'تم تحديث تصميم بطاقة الهدية بنجاح.',
                'data' => new GiftCardDesignResource(
                    $giftCardDesign
                ),
            ]);

        } catch (Throwable $exception) {

            if ($newImagePath !== null) {
                Storage::disk('public')->delete(
                    $newImagePath
                );
            }

            throw $exception;
        }
    }

    /**
     * Delete only the image.
     */
    public function destroyImage(
        GiftCardDesign $giftCardDesign
    ): JsonResponse {

        if ($giftCardDesign->image_path === null) {
            return response()->json([
                'message' => 'لا توجد صورة مرتبطة بهذا التصميم.',
            ], 422);
        }

        $imagePath = $giftCardDesign->image_path;

        DB::transaction(function () use ($giftCardDesign): void {
            $giftCardDesign->update([
                'image_path' => null,
            ]);
        });

        Storage::disk('public')->delete(
            $imagePath
        );

        $giftCardDesign
            ->refresh()
            ->loadCount('orders');

        return response()->json([
            'message' => 'تم حذف صورة التصميم بنجاح.',
            'data' => new GiftCardDesignResource(
                $giftCardDesign
            ),
        ]);
    }

    /**
     * Delete a Gift Card design.
     */
    public function destroy(
        GiftCardDesign $giftCardDesign
    ): JsonResponse {

        if ($giftCardDesign->orders()->exists()) {
            return response()->json([
                'message' => 'لا يمكن حذف التصميم لأنه مستخدم في طلبات بطاقات هدايا.',
            ], 422);
        }

        $imagePath = $giftCardDesign->image_path;

        DB::transaction(
            fn () => $giftCardDesign->delete()
        );

        if ($imagePath !== null) {
            Storage::disk('public')->delete(
                $imagePath
            );
        }

        return response()->json([
            'message' => 'تم حذف تصميم بطاقة الهدية بنجاح.',
        ]);
    }
}
