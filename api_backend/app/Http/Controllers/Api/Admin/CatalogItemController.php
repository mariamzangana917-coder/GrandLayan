<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Admin\StoreCatalogItemRequest;
use App\Http\Requests\Api\Admin\UpdateCatalogItemRequest;
use App\Http\Resources\CatalogItemResource;
use App\Models\CatalogItem;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CatalogItemController extends Controller
{
    /**
     * Display a listing of catalog items.
     */
    public function index(
        Request $request
    ): AnonymousResourceCollection {
        $items = CatalogItem::query()
            ->with([
                'category.department',
                'images',
            ])
            ->when(
                $request->filled('department'),
                function (Builder $query) use ($request): void {
                    $query->whereHas(
                        'category.department',
                        function (Builder $departmentQuery) use ($request): void {
                            $departmentQuery->where(
                                'code',
                                (string) $request->input('department')
                            );
                        }
                    );
                }
            )
            ->when(
                $request->filled('category_id'),
                function (Builder $query) use ($request): void {
                    $query->where(
                        'category_id',
                        $request->integer('category_id')
                    );
                }
            )
            ->when(
                $request->filled('type'),
                function (Builder $query) use ($request): void {
                    $query->where(
                        'type',
                        (string) $request->input('type')
                    );
                }
            )
            ->when(
                $request->has('is_active'),
                function (Builder $query) use ($request): void {
                    $query->where(
                        'is_active',
                        $request->boolean('is_active')
                    );
                }
            )
            ->orderBy('id')
            ->get();

        return CatalogItemResource::collection($items);
    }

    /**
     * Store a newly created catalog item.
     */
    public function store(
        StoreCatalogItemRequest $request
    ): JsonResponse {
        $item = CatalogItem::query()->create(
            $request->validated()
        );

        $item->load([
            'category.department',
            'images',
        ]);

        $message = $item->isPackage()
            ? 'تم إنشاء الباكج بنجاح.'
            : 'تم إنشاء الخدمة بنجاح.';

        return response()->json([
            'message' => $message,
            'data' => new CatalogItemResource($item),
        ], 201);
    }

    /**
     * Display the specified catalog item.
     */
    public function show(
        CatalogItem $catalogItem
    ): CatalogItemResource {
        $catalogItem->load([
            'category.department',
            'images',
        ]);

        return new CatalogItemResource($catalogItem);
    }

    /**
     * Update the specified catalog item.
     */
    public function update(
        UpdateCatalogItemRequest $request,
        CatalogItem $catalogItem
    ): JsonResponse {
        $catalogItem->update(
            $request->validated()
        );

        $catalogItem->refresh()->load([
            'category.department',
            'images',
        ]);

        return response()->json([
            'message' => 'تم تحديث العنصر بنجاح.',
            'data' => new CatalogItemResource($catalogItem),
        ]);
    }

    /**
     * Remove the specified catalog item.
     */
    public function destroy(
        CatalogItem $catalogItem
    ): JsonResponse {
        if (
            $catalogItem->isService()
            && $catalogItem->containingPackages()->exists()
        ) {
            return response()->json([
                'message' => 'لا يمكن حذف الخدمة لأنها مستخدمة داخل باكج.',
            ], 422);
        }

        $catalogItem->delete();

        return response()->json([
            'message' => 'تم حذف العنصر بنجاح.',
        ]);
    }
}
