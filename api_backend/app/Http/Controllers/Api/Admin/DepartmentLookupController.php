<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Department;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class DepartmentLookupController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $onlyActive = $request->boolean('is_active', true);

        $departments = Department::query()
            ->orderBy('id')
            ->get()
            ->filter(function (Department $department) use ($onlyActive): bool {
                if (! $onlyActive) {
                    return true;
                }

                $attributes = $department->getAttributes();

                return ! array_key_exists('is_active', $attributes)
                    || (bool) $department->getAttribute('is_active');
            })
            ->values()
            ->map(function (Department $department): array {
                $name = $department->getAttribute('name')
                    ?? $department->getAttribute('name_ar')
                    ?? $department->getAttribute('title')
                    ?? $department->getAttribute('code');

                return [
                    'id' => (int) $department->getKey(),
                    'code' => (string) $department->getAttribute('code'),
                    'name' => (string) $name,
                    'name_ar' => (string) $name,
                    'is_active' => (bool) (
                        $department->getAttribute('is_active') ?? true
                    ),
                ];
            });

        return response()->json([
            'data' => $departments,
        ]);
    }
}
