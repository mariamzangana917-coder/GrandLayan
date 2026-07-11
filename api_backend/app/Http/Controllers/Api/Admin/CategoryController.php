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

class CategoryController extends Controller
{
    /**
     * Display a listing of categories.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $categories = Category::query()
            ->with('department')
            ->when(
                $request->filled('department'),
                function ($query) use ($request): void {
                    $query->whereHas(
                        'department',
                        fn ($departmentQuery) => $departmentQuery
                            ->where('code', $request->string('department'))
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

    /**
     * Store a newly created category.
     */
    public function store(
        StoreCategoryRequest $request
    ): JsonResponse {
        $category = Category::query()->create(
            $request->validated()
        );

        $category->load('department');

        return response()->json([
            'message' => 'تم إنشاء التصنيف بنجاح.',
            'data' => new CategoryResource($category),
        ], 201);
    }

    /**
     * Display the specified category.
     */
    public function show(Category $category): CategoryResource
    {
        $category->load('department');

        return new CategoryResource($category);
    }

    /**
     * Update the specified category.
     */
    public function update(
        UpdateCategoryRequest $request,
        Category $category
    ): JsonResponse {
        $category->update(
            $request->validated()
        );

        $category->refresh()->load('department');

        return response()->json([
            'message' => 'تم تحديث التصنيف بنجاح.',
            'data' => new CategoryResource($category),
        ]);
    }

    /**
     * Soft delete the specified category.
     */
    public function destroy(Category $category): JsonResponse
    {
        if ($category->catalogItems()->exists()) {
            return response()->json([
                'message' => 'لا يمكن حذف التصنيف لأنه مرتبط بخدمات أو باكجات.',
            ], 422);
        }

        $category->delete();

        return response()->json([
            'message' => 'تم حذف التصنيف بنجاح.',
        ]);
    }
}