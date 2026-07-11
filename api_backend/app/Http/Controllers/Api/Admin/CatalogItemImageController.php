<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Admin\StoreCatalogItemImageRequest;
use App\Http\Requests\Api\Admin\UpdateCatalogItemImageRequest;
use App\Http\Resources\CatalogItemImageResource;
use App\Models\CatalogItem;
use App\Models\CatalogItemImage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Throwable;

class CatalogItemImageController extends Controller
{
    /**
     * Display the images belonging to a catalog item.
     */
    public function index(
        CatalogItem $catalogItem
    ): AnonymousResourceCollection {
        $images = $catalogItem->images()
            ->orderByDesc('is_primary')
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return CatalogItemImageResource::collection($images);
    }

    /**
     * Upload one or multiple images for a catalog item.
     */
    public function store(
        StoreCatalogItemImageRequest $request,
        CatalogItem $catalogItem
    ): JsonResponse {
        $uploadedPaths = [];

        try {
            $createdImages = DB::transaction(
                function () use (
                    $request,
                    $catalogItem,
                    &$uploadedPaths
                ) {
                    /*
                     * Lock the item's current images to prevent two concurrent
                     * requests from assigning conflicting primary images or
                     * sort-order values.
                     */
                    $existingImages = CatalogItemImage::query()
                        ->where('catalog_item_id', $catalogItem->id)
                        ->lockForUpdate()
                        ->get();

                    $hasPrimaryImage = $existingImages
                        ->contains(
                            fn (CatalogItemImage $image): bool =>
                                $image->is_primary
                        );

                    $nextSortOrder = ((int) $existingImages
                        ->max('sort_order')) + 1;

                    $createdImages = collect();

                    foreach ($request->file('images', []) as $index => $file) {
                        $path = $file->store(
                            "catalog/items/{$catalogItem->id}",
                            'public'
                        );

                        $uploadedPaths[] = $path;

                        $isPrimary = ! $hasPrimaryImage && $index === 0;

                        $image = CatalogItemImage::query()->create([
                            'catalog_item_id' => $catalogItem->id,
                            'path' => $path,
                            'url' => null,
                            'alt_text' => null,
                            'is_primary' => $isPrimary,
                            'sort_order' => $nextSortOrder + $index,
                        ]);

                        $createdImages->push($image);
                    }

                    return $createdImages;
                }
            );
        } catch (Throwable $exception) {
            /*
             * Database rollback does not remove physical files, so any files
             * already stored before the failure must be cleaned up manually.
             */
            foreach ($uploadedPaths as $path) {
                Storage::disk('public')->delete($path);
            }

            throw $exception;
        }

        return response()->json([
            'message' => 'تم رفع الصور بنجاح.',
            'data' => CatalogItemImageResource::collection(
                $createdImages
            )->resolve(),
        ], 201);
    }

    /**
     * Update image metadata or make it the primary image.
     */
    public function update(
        UpdateCatalogItemImageRequest $request,
        CatalogItem $catalogItem,
        CatalogItemImage $catalogItemImage
    ): JsonResponse {
        $this->ensureImageBelongsToCatalogItem(
            $catalogItem,
            $catalogItemImage
        );

        DB::transaction(
            function () use (
                $request,
                $catalogItem,
                $catalogItemImage
            ): void {
                /*
                 * Lock all images for this catalog item because changing the
                 * primary image affects more than one database row.
                 */
                CatalogItemImage::query()
                    ->where('catalog_item_id', $catalogItem->id)
                    ->lockForUpdate()
                    ->get();

                $validated = $request->validated();

                if (
                    array_key_exists('is_primary', $validated)
                    && $validated['is_primary'] === true
                ) {
                    /*
                     * Clear the old primary first to satisfy PostgreSQL's
                     * partial unique index allowing one primary image only.
                     */
                    CatalogItemImage::query()
                        ->where('catalog_item_id', $catalogItem->id)
                        ->where('id', '<>', $catalogItemImage->id)
                        ->where('is_primary', true)
                        ->update([
                            'is_primary' => false,
                            'updated_at' => now(),
                        ]);

                    $validated['is_primary'] = true;
                }

                /*
                 * Do not allow manually leaving an existing image collection
                 * without any primary image. A primary can be changed by
                 * setting another image to true instead.
                 */
                if (
                    array_key_exists('is_primary', $validated)
                    && $validated['is_primary'] === false
                    && $catalogItemImage->is_primary
                ) {
                    unset($validated['is_primary']);
                }

                $catalogItemImage->update($validated);
            }
        );

        $catalogItemImage->refresh();

        return response()->json([
            'message' => 'تم تحديث الصورة بنجاح.',
            'data' => new CatalogItemImageResource(
                $catalogItemImage
            ),
        ]);
    }

    /**
     * Delete an image and promote another image when necessary.
     */
    public function destroy(
        CatalogItem $catalogItem,
        CatalogItemImage $catalogItemImage
    ): JsonResponse {
        $this->ensureImageBelongsToCatalogItem(
            $catalogItem,
            $catalogItemImage
        );

        $path = $catalogItemImage->path;

        DB::transaction(
            function () use (
                $catalogItem,
                $catalogItemImage
            ): void {
                $images = CatalogItemImage::query()
                    ->where('catalog_item_id', $catalogItem->id)
                    ->lockForUpdate()
                    ->orderBy('sort_order')
                    ->orderBy('id')
                    ->get();

                $wasPrimary = $catalogItemImage->is_primary;

                $catalogItemImage->delete();

                if (! $wasPrimary) {
                    return;
                }

                $replacement = $images
                    ->first(
                        fn (CatalogItemImage $image): bool =>
                            $image->id !== $catalogItemImage->id
                    );

                if ($replacement !== null) {
                    $replacement->update([
                        'is_primary' => true,
                    ]);
                }
            }
        );

        /*
         * Delete the physical file only after the database transaction
         * succeeds, so a database rollback does not leave a missing file.
         */
        Storage::disk('public')->delete($path);

        return response()->json([
            'message' => 'تم حذف الصورة بنجاح.',
        ]);
    }

    /**
     * Ensure a nested image belongs to the catalog item in the route.
     */
    private function ensureImageBelongsToCatalogItem(
        CatalogItem $catalogItem,
        CatalogItemImage $catalogItemImage
    ): void {
        abort_unless(
            $catalogItemImage->catalog_item_id === $catalogItem->id,
            404
        );
    }
}