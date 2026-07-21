<?php

namespace App\Http\Controllers\Api\Customer\GiftCards;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreGiftCardOrderRequest;
use App\Http\Resources\GiftCardOrderResource;
use App\Models\GiftCardOrder;
use App\Services\GiftCards\StoreGiftCardOrderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Symfony\Component\HttpFoundation\Response;

class CustomerGiftCardOrderController extends Controller
{
    /**
     * Display the authenticated customer's Gift Card orders.
     */
    public function index(
        Request $request
    ): AnonymousResourceCollection {
        $orders = GiftCardOrder::query()
            ->where('customer_id', $request->user()->id)
            ->with([
                'design',
                'giftCard',
            ])
            ->latest('id')
            ->paginate(15);

        return GiftCardOrderResource::collection($orders);
    }

    /**
     * Create a new pending Gift Card order.
     */
    public function store(
        StoreGiftCardOrderRequest $request,
        StoreGiftCardOrderService $service
    ): JsonResponse {
        $order = $service->execute(
            customer: $request->user(),
            data: $request->validated()
        );

        $order->loadMissing([
            'design',
            'giftCard',
        ]);

        return (new GiftCardOrderResource($order))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    /**
     * Display one Gift Card order belonging to the authenticated customer.
     */
    public function show(
        Request $request,
        int $giftCardOrder
    ): GiftCardOrderResource {
        $order = GiftCardOrder::query()
            ->whereKey($giftCardOrder)
            ->where('customer_id', $request->user()->id)
            ->with([
                'design',
                'giftCard',
            ])
            ->firstOrFail();

        return new GiftCardOrderResource($order);
    }
}
