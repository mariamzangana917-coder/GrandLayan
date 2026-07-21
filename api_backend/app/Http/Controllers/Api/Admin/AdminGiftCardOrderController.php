<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\IssueGiftCardRequest;
use App\Http\Resources\GiftCardOrderResource;
use App\Http\Resources\GiftCardResource;
use App\Models\GiftCardOrder;
use App\Services\GiftCards\IssueGiftCardService;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AdminGiftCardOrderController extends Controller
{
    /**
     * Display all Gift Card orders for the manager.
     */
    public function index(): AnonymousResourceCollection
    {
        $orders = GiftCardOrder::query()
            ->with([
                'customer',
                'design',
                'giftCard',
            ])
            ->latest('id')
            ->paginate(15);

        return GiftCardOrderResource::collection($orders);
    }

    /**
     * Display one Gift Card order.
     */
    public function show(
        GiftCardOrder $giftCardOrder
    ): GiftCardOrderResource {
        $giftCardOrder->load([
            'customer',
            'design',
            'giftCard.transactions',
        ]);

        return new GiftCardOrderResource($giftCardOrder);
    }

    /**
     * Confirm payment and issue the Gift Card.
     */
    public function issue(
        IssueGiftCardRequest $request,
        GiftCardOrder $giftCardOrder,
        IssueGiftCardService $service
    ): GiftCardResource {
        $giftCard = $service->execute(
            order: $giftCardOrder,
            paymentReference: $request->validated('payment_reference')
        );

        $giftCard->load([
            'order.customer',
            'order.design',
            'transactions',
        ]);

        /*
         * The manager is authorized to see the QR token.
         */
        $giftCard->makeVisible('qr_token');

        return new GiftCardResource($giftCard);
    }
}
