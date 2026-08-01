<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Banners\ReorderBannersRequest;
use App\Http\Requests\Admin\Banners\StoreBannerRequest;
use App\Http\Requests\Admin\Banners\UpdateBannerRequest;
use App\Http\Resources\BannerResource;
use App\Models\Banner;
use App\Services\BannerService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Symfony\Component\HttpFoundation\Response;

class BannerController extends Controller
{
    public function __construct(
        private readonly BannerService $bannerService,
    ) {
    }

    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Banner::query()
            ->orderBy('sort_order')
            ->orderByDesc('id');

        if ($request->has('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        return BannerResource::collection($query->get());
    }

    public function store(StoreBannerRequest $request): JsonResponse
    {
        $data = $request->validated();
        $banner = $this->bannerService->create(
            data: $data,
            image: $request->file('image'),
        );

        return (new BannerResource($banner))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    public function show(Banner $banner): BannerResource
    {
        return new BannerResource($banner);
    }

    public function update(UpdateBannerRequest $request, Banner $banner): BannerResource
    {
        $banner = $this->bannerService->update(
            banner: $banner,
            data: $request->validated(),
            image: $request->file('image'),
        );

        return new BannerResource($banner);
    }

    public function destroy(Banner $banner): JsonResponse
    {
        $this->bannerService->delete($banner);

        return response()->json(null, Response::HTTP_NO_CONTENT);
    }

    public function reorder(ReorderBannersRequest $request): JsonResponse
    {
        $this->bannerService->reorder($request->validated('items'));

        return response()->json([
            'message' => 'تم تحديث ترتيب البانرات بنجاح.',
        ]);
    }
}
