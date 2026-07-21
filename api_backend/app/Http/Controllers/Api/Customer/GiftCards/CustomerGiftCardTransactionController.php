<?php

namespace App\Http\Controllers\Api\Customer\GiftCards;

use App\Http\Controllers\Controller;
use App\Http\Resources\GiftCardTransactionResource;
use App\Models\GiftCard;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CustomerGiftCardTransactionController extends Controller
{
    /**
     * Display the complete transaction history of a Gift Card owned by
     * the authenticated customer.
     */
    public function index(
        Request $request,
        GiftCard $giftCard
    ): AnonymousResourceCollection {
        $this->ensureCustomerOwnsGiftCard(
            $request,
            $giftCard
        );

        /*
         * GiftCard::transactions() applies an ascending order by default.
         *
         * reorder() removes that existing order so the API returns the
         * newest transaction first.
         */
        $transactions = $giftCard
            ->transactions()
            ->reorder('id', 'desc')
            ->with([
                'appointment',
            ])
            ->paginate(20);

        return GiftCardTransactionResource::collection($transactions);
    }

    /**
     * Ensure the authenticated customer owns the Gift Card.
     *
     * Return 404 to prevent exposing the existence of another
     * customer's Gift Card.
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
