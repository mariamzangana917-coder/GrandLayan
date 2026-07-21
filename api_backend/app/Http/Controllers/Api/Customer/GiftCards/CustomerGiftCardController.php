<?php

namespace App\Http\Controllers\Api\Customer\GiftCards;

use App\Http\Controllers\Controller;
use App\Http\Resources\GiftCardResource;
use App\Models\GiftCard;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CustomerGiftCardController extends Controller
{
    /**
     * Display the authenticated customer's Gift Cards.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $customerId = (int) $request->user()->id;

        $giftCards = GiftCard::query()
            ->whereHas(
                'order',
                function (Builder $query) use ($customerId): void {
                    $query->where('customer_id', $customerId);
                }
            )
            ->with([
                'order',
            ])
            ->withCount('transactions')
            ->latest('id')
            ->paginate(15);

        /*
         * qr_token remains hidden in the list response.
         *
         * This prevents returning all QR verification tokens when the
         * customer only needs a summary of their Gift Cards.
         */
        return GiftCardResource::collection($giftCards);
    }

    /**
     * Display one Gift Card owned by the authenticated customer.
     */
    public function show(
        Request $request,
        GiftCard $giftCard
    ): GiftCardResource {
        $this->ensureCustomerOwnsGiftCard(
            $request,
            $giftCard
        );

        $giftCard->loadMissing([
            'order',
        ]);

        $giftCard->loadCount('transactions');

        /*
         * The authenticated owner is allowed to receive the QR token on
         * the details endpoint so the customer application can generate
         * and display the Gift Card QR code.
         *
         * The QR token is not exposed in the index endpoint.
         */
        $giftCard->makeVisible('qr_token');

        return new GiftCardResource($giftCard);
    }

    /**
     * Ensure the authenticated customer owns the Gift Card.
     *
     * Return 404 instead of 403 so another customer cannot determine
     * whether a Gift Card exists.
     */
    private function ensureCustomerOwnsGiftCard(
        Request $request,
        GiftCard $giftCard
    ): void {
        $giftCard->loadMissing('order');

        $authenticatedCustomerId = (int) $request->user()->id;
        $giftCardCustomerId = (int) ($giftCard->order?->customer_id ?? 0);

        abort_unless(
            $giftCardCustomerId === $authenticatedCustomerId,
            404
        );
    }
}
