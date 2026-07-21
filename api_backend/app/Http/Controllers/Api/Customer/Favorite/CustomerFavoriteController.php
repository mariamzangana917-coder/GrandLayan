<?php

namespace App\Http\Controllers\Api\Customer\Favorite;

use App\Http\Controllers\Controller;
use App\Http\Resources\CustomerFavoriteResource;
use App\Models\CatalogItem;
use App\Models\CustomerFavorite;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\ValidationException;

class CustomerFavoriteController extends Controller
{
    public function index(
        Request $request
    ): AnonymousResourceCollection {
        /** @var User $customer */
        $customer = $request->user();

        $favorites = CustomerFavorite::query()
            ->where('customer_id', $customer->id)
            ->with([
                'catalogItem.category.department',
                'catalogItem.images',
                'catalogItem.favorites' => fn ($query) => $query->where(
                    'customer_id',
                    $customer->id
                ),
            ])
            ->latest('id')
            ->paginate(20);

        return CustomerFavoriteResource::collection($favorites);
    }

    public function store(
        Request $request,
        CatalogItem $catalogItem
    ): JsonResponse {
        /** @var User $customer */
        $customer = $request->user();

        $catalogItem->loadMissing([
            'category.department',
        ]);

        if (
            ! $catalogItem->is_active
            || ! $catalogItem->category->is_active
            || ! $catalogItem->category->department->is_active
        ) {
            throw ValidationException::withMessages([
                'catalog_item' => [
                    'لا يمكن إضافة هذه الخدمة إلى المفضلة لأنها غير متاحة حاليًا.',
                ],
            ]);
        }

        $favorite = CustomerFavorite::query()->firstOrCreate([
            'customer_id' => $customer->id,
            'catalog_item_id' => $catalogItem->id,
        ]);

        $favorite->load([
            'catalogItem.category.department',
            'catalogItem.images',
            'catalogItem.favorites' => fn ($query) => $query->where(
                'customer_id',
                $customer->id
            ),
        ]);

        return response()->json([
            'message' => $favorite->wasRecentlyCreated
                ? 'تمت إضافة الخدمة إلى المفضلة.'
                : 'الخدمة موجودة في المفضلة مسبقًا.',
            'data' => new CustomerFavoriteResource($favorite),
        ], $favorite->wasRecentlyCreated ? 201 : 200);
    }

    public function destroy(
        Request $request,
        CatalogItem $catalogItem
    ): JsonResponse {
        /** @var User $customer */
        $customer = $request->user();

        CustomerFavorite::query()
            ->where('customer_id', $customer->id)
            ->where('catalog_item_id', $catalogItem->id)
            ->delete();

        return response()->json([
            'message' => 'تمت إزالة الخدمة من المفضلة.',
        ]);
    }
}
