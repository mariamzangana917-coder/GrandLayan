<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\RedeemGiftCardRequest;
use App\Http\Requests\RefundGiftCardRequest;
use App\Http\Resources\GiftCardTransactionResource;
use App\Models\GiftCard;
use App\Services\GiftCards\RedeemGiftCardService;
use App\Services\GiftCards\RefundGiftCardService;

class AdminGiftCardTransactionController extends Controller
{
    /**
     * Redeem an amount from a Gift Card for an appointment.
     */
    public function redeem(
        RedeemGiftCardRequest $request,
        GiftCard $giftCard,
        RedeemGiftCardService $service
    ): GiftCardTransactionResource {
        $transaction = $service->execute(
            identifier: $giftCard->code,
            appointment: $request->validated('appointment_id'),
            amount: $request->validated('amount'),
            performedBy: $request->user(),
           notes: $request->input('notes')
        );

        return new GiftCardTransactionResource($transaction);
    }

    /**
     * Refund a previously redeemed amount to a Gift Card.
     */
    public function refund(
        RefundGiftCardRequest $request,
        GiftCard $giftCard,
        RefundGiftCardService $service
    ): GiftCardTransactionResource {
        $transaction = $service->execute(
            giftCard: $giftCard,
            appointment: $request->validated('appointment_id'),
            amount: $request->validated('amount'),
            performedBy: $request->user(),
          notes: $request->input('notes')
        );

        return new GiftCardTransactionResource($transaction);
    }
}