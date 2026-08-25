<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePostRequest;
use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class PostController extends Controller
{
    /**
     * List posts for administration.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Post::query()
            ->latest();

        if ($request->filled('department')) {
            $query->where(
                'department',
                $request->string('department')->toString()
            );
        }

        return response()->json([
            'data' => PostResource::collection(
                $query->get()
            ),
        ]);
    }

    /**
     * Create a new post.
     */
   public function store(StorePostRequest $request): PostResource
{
    $imagePath = $request->file('image')->store(
        'posts',
        'public'
    );

    try {
        $post = DB::transaction(function () use (
            $request,
            $imagePath,
        ): Post {
            return Post::query()->create([
                'department' => $request->string('department')->toString(),
                'image_path' => $imagePath,
                'description' => $request->input('description'),
                'is_active' => true,
                'created_by' => $request->user()?->id,
            ]);
        });

        return new PostResource($post);
    } catch (\Throwable $exception) {
        Storage::disk('public')->delete($imagePath);

        throw $exception;
    }
}

    /**
     * Show a post.
     */
    public function show(Post $post): PostResource
    {
        return new PostResource($post);
    }

    /**
     * Update post description/status.
     *
     * Image replacement can be added separately without
     * affecting the current create flow.
     */
   public function update(Request $request, Post $post): PostResource
{
    $validated = $request->validate([
        'description' => [
            'nullable',
            'string',
            'max:500',
        ],
        'is_active' => [
            'sometimes',
            'boolean',
        ],
    ]);

    $post->update($validated);

    return new PostResource($post->refresh());
}

    /**
     * Delete a post and its image.
     */
    public function destroy(Post $post): JsonResponse
    {
        $imagePath = $post->image_path;

        DB::transaction(function () use ($post): void {
            $post->delete();
        });

        if ($imagePath) {
            Storage::disk('public')->delete($imagePath);
        }

        return response()->json([
            'message' => 'تم حذف المنشور بنجاح.',
        ]);
    }
}