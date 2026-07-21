<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\GiftCardResource;
use App\Models\GiftCard;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AdminGiftCardController extends Controller
{
    /**
     * Display all issued Gift Cards for the manager.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $giftCards = GiftCard::query()
            ->with([
                'order.customer',
                'order.design',
            ])
            ->withCount('transactions')
            ->when(
                $request->filled('search'),
                function (Builder $query) use ($request): void {
                    $search = trim((string) $request->input('search'));

                    $query->where(function (Builder $query) use ($search): void {
                        $query
                            ->where('code', 'ilike', "%{$search}%")
                            ->orWhereHas(
                                'order.customer',
                                function (Builder $query) use ($search): void {
                                    $query
                                        ->where('name', 'ilike', "%{$search}%")
                                        ->orWhere(
                                            'phone',
                                            'ilike',
                                            "%{$search}%"
                                        );
                                }
                            );
                    });
                }
            )
            ->when(
                $request->filled('status'),
                fn (Builder $query): Builder => $query->where(
                    'status',
                    $request->input('status')
                )
            )
            ->when(
                $request->boolean('expired'),
                fn (Builder $query): Builder => $query->where(
                    'expires_at',
                    '<=',
                    now()
                )
            )
            ->when(
                $request->boolean('not_expired'),
                fn (Builder $query): Builder => $query->where(
                    'expires_at',
                    '>',
                    now()
                )
            )
            ->when(
                $request->boolean('with_balance'),
                fn (Builder $query): Builder => $query->where(
                    'remaining_balance',
                    '>',
                    0
                )
            )
            ->when(
                $request->boolean('without_balance'),
                fn (Builder $query): Builder => $query->where(
                    'remaining_balance',
                    '=',
                    0
                )
            )
            ->latest('id')
            ->paginate(
                perPage: min(
                    max((int) $request->input('per_page', 15), 1),
                    100
                )
            );

        return GiftCardResource::collection($giftCards);
    }

    /**
     * Display one issued Gift Card.
     */
    public function show(GiftCard $giftCard): GiftCardResource
    {
        $giftCard->load([
            'order.customer',
            'order.design',
            'transactions.appointment',
            'transactions.performedBy',
        ]);

        $giftCard->loadCount('transactions');

        /*
         * The manager is authorized to see the QR token.
         */
        $giftCard->makeVisible('qr_token');

        return new GiftCardResource($giftCard);
    }
}