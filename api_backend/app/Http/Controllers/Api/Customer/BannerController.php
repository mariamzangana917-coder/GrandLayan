<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\BannerResource;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BannerController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $placement = $request->string('placement', 'home')->toString();

        abort_unless(in_array($placement, ['home', 'salon', 'clinic'], true), 422);

        $banners = Banner::query()
            ->visibleNow()
            ->where('placement', $placement)
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->limit(5)
            ->get();

        return BannerResource::collection($banners);
    }
}
