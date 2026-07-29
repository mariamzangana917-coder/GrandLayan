<?php

namespace App\Http\Controllers\Api\Customer\GiftCards;

use App\Http\Controllers\Controller;
use App\Http\Resources\GiftCardDesignResource;
use App\Models\GiftCardDesign;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CustomerGiftCardDesignController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $designs = GiftCardDesign::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return GiftCardDesignResource::collection($designs);
    }
}