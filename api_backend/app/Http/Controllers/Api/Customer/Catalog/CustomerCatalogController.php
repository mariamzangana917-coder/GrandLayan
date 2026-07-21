<?php

namespace App\Http\Controllers\Api\Customer\Catalog;

use App\Http\Controllers\Controller;
use App\Http\Resources\CatalogItemResource;
use App\Models\CatalogItem;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

class CustomerCatalogController extends Controller
{
    /**
     * Display active catalog items for customers.
     */
    public function index(
        Request $request
    ): AnonymousResourceCollection {
        /** @var User $customer */
        $customer = $request->user();

        $items = CatalogItem::query()
            ->with([
                'category.department',
                'images',
                'favorites' => fn ($query) => $query->where(
                    'customer_id',
                    $customer->id
                ),
            ])
            ->where('is_active', true)
            ->whereHas(
                'category',
                fn ($query) => $query->where('is_active', true)
            )
            ->whereHas(
                'category.department',
                fn ($query) => $query->where('is_active', true)
            )
            ->when(
                $request->filled('department'),
                function ($query) use ($request): void {
                    $query->whereHas(
                        'category.department',
                        fn ($departmentQuery) => $departmentQuery->where(
                            'code',
                            (string) $request->input('department')
                        )
                    );
                }
            )
            ->when(
                $request->filled('category_id'),
                fn ($query) => $query->where(
                    'category_id',
                    $request->integer('category_id')
                )
            )
            ->when(
                $request->filled('type'),
                fn ($query) => $query->where(
                    'type',
                    (string) $request->input('type')
                )
            )
            ->orderBy('id')
            ->get();

        return CatalogItemResource::collection($items);
    }

    /**
     * Display a single catalog item.
     */
    public function show(
        Request $request,
        CatalogItem $catalogItem
    ): CatalogItemResource {
        /** @var User $customer */
        $customer = $request->user();

        $catalogItem->load([
            'category.department',
            'images',
            'favorites' => fn ($query) => $query->where(
                'customer_id',
                $customer->id
            ),
        ]);

        if (
            ! $catalogItem->is_active
            || ! $catalogItem->category->is_active
            || ! $catalogItem->category->department->is_active
        ) {
            throw new NotFoundHttpException;
        }

        return new CatalogItemResource($catalogItem);
    }
}
