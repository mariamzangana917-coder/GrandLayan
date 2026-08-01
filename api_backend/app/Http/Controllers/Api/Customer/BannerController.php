<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\BannerResource;
use App\Models\Banner;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BannerController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $banners = Banner::query()
            ->visibleNow()
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->limit(5)
            ->get();

        return BannerResource::collection($banners);
    }
}
