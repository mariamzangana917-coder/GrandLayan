<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Admin\StoreCategoryRequest;
use App\Http\Requests\Api\Admin\UpdateCategoryRequest;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Throwable;

class CategoryController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $categories = Category::query()
            ->with('department')
            ->withCount('catalogItems')
            ->when(
                $request->filled('department'),
                function ($query) use ($request): void {
                    $query->whereHas(
                        'department',
                        fn ($departmentQuery) => $departmentQuery
                            ->where(
                                'code',
                                $request->string('department')
                            )
                    );
                }
            )
            ->when(
                $request->has('is_active'),
                function ($query) use ($request): void {
                    $query->where(
                        'is_active',
                        filter_var(
                            $request->input('is_active'),
                            FILTER_VALIDATE_BOOLEAN
                        )
                    );
                }
            )
            ->orderBy('id')
            ->get();

        return CategoryResource::collection($categories);
    }

    public function store(
        StoreCategoryRequest $request
    ): JsonResponse {
        $validated = $request->safe()->except('image');

        $imagePath = null;

        try {
            if ($request->hasFile('image')) {
                $imagePath = $request
                    ->file('image')
                    ->store('categories', 'public');

                $validated['image_path'] = $imagePath;
            }

            $category = DB::transaction(
                fn () => Category::query()->create(
                    $validated
                )
            );

            $category
                ->load('department')
                ->loadCount('catalogItems');

            return response()->json([
                'message' => 'تم إنشاء التصنيف بنجاح.',
                'data' => new CategoryResource($category),
            ], 201);
        } catch (Throwable $error) {
            if ($imagePath !== null) {
                Storage::disk('public')->delete(
                    $imagePath
                );
            }

            throw $error;
        }
    }

    public function show(
        Category $category
    ): CategoryResource {
        $category
            ->load('department')
            ->loadCount('catalogItems');

        return new CategoryResource($category);
    }

    public function update(
        UpdateCategoryRequest $request,
        Category $category
    ): JsonResponse {
        $validated = $request->safe()->except('image');

        $oldImagePath = $category->image_path;
        $newImagePath = null;

        try {
            if ($request->hasFile('image')) {
                $newImagePath = $request
                    ->file('image')
                    ->store('categories', 'public');

                $validated['image_path'] =
                    $newImagePath;
            }

            DB::transaction(
                fn () => $category->update(
                    $validated
                )
            );

            if (
                $newImagePath !== null
                && $oldImagePath !== null
            ) {
                Storage::disk('public')->delete(
                    $oldImagePath
                );
            }

            $category
                ->refresh()
                ->load('department')
                ->loadCount('catalogItems');

            return response()->json([
                'message' => 'تم تحديث التصنيف بنجاح.',
                'data' => new CategoryResource($category),
            ]);
        } catch (Throwable $error) {
            if ($newImagePath !== null) {
                Storage::disk('public')->delete(
                    $newImagePath
                );
            }

            throw $error;
        }
    }

    public function destroyImage(
        Category $category
    ): JsonResponse {
        if ($category->image_path === null) {
            return response()->json([
                'message' => 'لا توجد صورة مرتبطة بهذا التصنيف.',
            ], 422);
        }

        $imagePath = $category->image_path;

        DB::transaction(function () use ($category): void {
            $category->update([
                'image_path' => null,
            ]);
        });

        Storage::disk('public')->delete(
            $imagePath
        );

        $category
            ->refresh()
            ->load('department')
            ->loadCount('catalogItems');

        return response()->json([
            'message' => 'تم حذف صورة التصنيف بنجاح.',
            'data' => new CategoryResource($category),
        ]);
    }

    public function destroy(
        Category $category
    ): JsonResponse {
        if ($category->catalogItems()->exists()) {
            return response()->json([
                'message' =>
                    'لا يمكن حذف التصنيف لأنه مرتبط بخدمات أو باكجات.',
            ], 422);
        }

        $imagePath = $category->image_path;

        DB::transaction(
            fn () => $category->delete()
        );

        if ($imagePath !== null) {
            Storage::disk('public')->delete(
                $imagePath
            );
        }

        return response()->json([
            'message' => 'تم حذف التصنيف بنجاح.',
        ]);
    }
}