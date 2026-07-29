<?php

namespace App\Http\Controllers\Api\Customer\Offers;

use App\Http\Controllers\Controller;
use App\Http\Resources\OfferResource;
use App\Models\Offer;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CustomerOfferController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = $this->visibleOffersQuery();

        $department = trim((string) $request->query('department', ''));

        if ($department !== '') {
            $query->whereHas(
                'department',
                fn (Builder $builder): Builder => $builder
                    ->where('code', $department),
            );
        }

        return OfferResource::collection(
            $query
                ->orderBy('sort_order')
                ->orderBy('id')
                ->get(),
        );
    }

    public function show(int $offer): OfferResource
    {
        $model = $this->visibleOffersQuery()->findOrFail($offer);

        return new OfferResource($model);
    }

    private function visibleOffersQuery(): Builder
    {
        return Offer::query()
            ->with(['department', 'catalogItem'])
            ->current()
            ->whereHas(
                'department',
                fn (Builder $builder): Builder => $builder
                    ->where('is_active', true),
            )
            ->where(function (Builder $builder): void {
                $builder
                    ->whereNull('catalog_item_id')
                    ->orWhereHas(
                        'catalogItem',
                        fn (Builder $itemQuery): Builder => $itemQuery
                            ->where('is_active', true),
                    );
            });
    }
}
