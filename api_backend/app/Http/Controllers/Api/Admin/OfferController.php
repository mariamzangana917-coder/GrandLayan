<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Offers\ReplaceOfferImageRequest;
use App\Http\Requests\Api\Offers\StoreOfferRequest;
use App\Http\Requests\Api\Offers\UpdateOfferRequest;
use App\Http\Resources\OfferResource;
use App\Models\Offer;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class OfferController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Offer::query()
            ->with(['department', 'catalogItem']);

        $department = trim((string) $request->query('department', ''));

        if ($department !== '') {
            $query->whereHas(
                'department',
                fn (Builder $builder): Builder => $builder
                    ->where('code', $department),
            );
        }

        $search = trim((string) $request->query('search', ''));

        if ($search !== '') {
            $query->where(function (Builder $builder) use ($search): void {
                $pattern = '%'.$search.'%';

                $builder
                    ->where('title', 'ilike', $pattern)
                    ->orWhere('description', 'ilike', $pattern)
                    ->orWhere('badge_text', 'ilike', $pattern)
                    ->orWhere('value_text', 'ilike', $pattern);
            });
        }

        if ($request->has('is_active')) {
            $isActive = filter_var(
                $request->query('is_active'),
                FILTER_VALIDATE_BOOLEAN,
                FILTER_NULL_ON_FAILURE,
            );

            if ($isActive !== null) {
                $query->where('is_active', $isActive);
            }
        }

        $this->applyAvailabilityFilter(
            $query,
            (string) $request->query('availability', ''),
        );

        $perPage = max(
            1,
            min(100, (int) $request->query('per_page', 20)),
        );

        return OfferResource::collection(
            $query
                ->orderBy('sort_order')
                ->orderBy('id')
                ->paginate($perPage)
                ->withQueryString(),
        );
    }

    public function store(StoreOfferRequest $request): OfferResource
    {
        $imagePath = $request->file('image')->store('offers', 'public');

        try {
            $offer = DB::transaction(function () use (
                $request,
                $imagePath,
            ): Offer {
                $data = $request->validated();

                unset($data['image']);

                return Offer::query()->create([
                    ...$data,
                    'image_path' => $imagePath,
                    'created_by_user_id' => $request->user()->id,
                ]);
            });
        } catch (\Throwable $exception) {
            Storage::disk('public')->delete($imagePath);

            throw $exception;
        }

        return new OfferResource(
            $offer->load(['department', 'catalogItem']),
        );
    }

    public function show(Offer $offer): OfferResource
    {
        return new OfferResource(
            $offer->load(['department', 'catalogItem']),
        );
    }

    public function update(
        UpdateOfferRequest $request,
        Offer $offer,
    ): OfferResource {
        $offer->update($request->validated());

        return new OfferResource(
            $offer->refresh()->load(['department', 'catalogItem']),
        );
    }

    public function replaceImage(
        ReplaceOfferImageRequest $request,
        Offer $offer,
    ): OfferResource {
        $newPath = $request->file('image')->store('offers', 'public');
        $oldPath = $offer->image_path;

        try {
            $offer->update([
                'image_path' => $newPath,
            ]);
        } catch (\Throwable $exception) {
            Storage::disk('public')->delete($newPath);

            throw $exception;
        }

        if ($oldPath !== null && $oldPath !== $newPath) {
            Storage::disk('public')->delete($oldPath);
        }

        return new OfferResource(
            $offer->refresh()->load(['department', 'catalogItem']),
        );
    }

    public function destroy(Offer $offer): JsonResponse
    {
        $imagePath = $offer->image_path;

        $offer->delete();

        if ($imagePath !== null) {
            Storage::disk('public')->delete($imagePath);
        }

        return response()->json([
            'message' => 'تم حذف العرض بنجاح.',
        ]);
    }

    private function applyAvailabilityFilter(
        Builder $query,
        string $availability,
    ): void {
        match ($availability) {
            'current' => $query
                ->where('is_active', true)
                ->where('starts_at', '<=', now())
                ->where('ends_at', '>=', now()),

            'upcoming' => $query
                ->where('is_active', true)
                ->where('starts_at', '>', now()),

            'expired' => $query
                ->where('ends_at', '<', now()),

            'inactive' => $query
                ->where('is_active', false),

            default => null,
        };
    }
}
