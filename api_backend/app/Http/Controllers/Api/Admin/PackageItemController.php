<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Admin\StorePackageItemRequest;
use App\Http\Requests\Api\Admin\UpdatePackageItemRequest;
use App\Http\Resources\PackageItemResource;
use App\Models\CatalogItem;
use App\Models\PackageItem;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class PackageItemController extends Controller
{
    /**
     * عرض الخدمات الموجودة داخل الباكج.
     */
    public function index(
        CatalogItem $package
    ): AnonymousResourceCollection {
        $this->ensureCatalogItemIsPackage($package);

        $packageItems = PackageItem::query()
            ->where('package_id', $package->id)
            ->with('service')
            ->orderBy('id')
            ->get();

        return PackageItemResource::collection($packageItems);
    }

    /**
     * إضافة خدمة إلى الباكج.
     *
     * @throws ValidationException
     */
    public function store(
        StorePackageItemRequest $request,
        CatalogItem $package
    ): JsonResponse {
        $this->ensureCatalogItemIsPackage($package);

        try {
            $packageItem = DB::transaction(
                function () use (
                    $request,
                    $package
                ): PackageItem {
                    /*
                     * قفل محتويات الباكج يمنع طلبين متزامنين من
                     * إضافة الخدمة نفسها مرتين.
                     */
                    PackageItem::query()
                        ->where('package_id', $package->id)
                        ->lockForUpdate()
                        ->get();

                    $validated = $request->validated();

                    $alreadyExists = PackageItem::query()
                        ->where('package_id', $package->id)
                        ->where(
                            'service_id',
                            $validated['service_id']
                        )
                        ->exists();

                    if ($alreadyExists) {
                        throw ValidationException::withMessages([
                            'service_id' => 'هذه الخدمة مضافة مسبقًا إلى الباكج.',
                        ]);
                    }

                    return PackageItem::query()->create([
                        'package_id' => $package->id,
                        'service_id' => $validated['service_id'],
                        'quantity' => $validated['quantity'],
                        'notes' => $validated['notes'] ?? null,
                    ]);
                }
            );
        } catch (UniqueConstraintViolationException) {
            /*
             * حماية إضافية إذا حدث تعارض متزامن بعد اجتياز
             * التحقق وقبل تنفيذ الإدخال في قاعدة البيانات.
             */
            throw ValidationException::withMessages([
                'service_id' => 'هذه الخدمة مضافة مسبقًا إلى الباكج.',
            ]);
        }

        $packageItem->load('service');

        return response()->json([
            'message' => 'تمت إضافة الخدمة إلى الباكج بنجاح.',
            'data' => new PackageItemResource($packageItem),
        ], 201);
    }

    /**
     * تعديل الكمية أو الملاحظات.
     */
    public function update(
        UpdatePackageItemRequest $request,
        CatalogItem $package,
        PackageItem $packageItem
    ): JsonResponse {
        $this->ensureCatalogItemIsPackage($package);

        $this->ensurePackageItemBelongsToPackage(
            $package,
            $packageItem
        );

        $packageItem->update(
            $request->validated()
        );

        $packageItem->refresh()->load('service');

        return response()->json([
            'message' => 'تم تحديث محتوى الباكج بنجاح.',
            'data' => new PackageItemResource($packageItem),
        ]);
    }

    /**
     * حذف خدمة من الباكج.
     */
    public function destroy(
        CatalogItem $package,
        PackageItem $packageItem
    ): JsonResponse {
        $this->ensureCatalogItemIsPackage($package);

        $this->ensurePackageItemBelongsToPackage(
            $package,
            $packageItem
        );

        $packageItem->delete();

        return response()->json([
            'message' => 'تم حذف الخدمة من الباكج بنجاح.',
        ]);
    }

    /**
     * التأكد من أن العنصر المستخدم في مسار الباكج
     * هو فعلًا من نوع Package.
     */
    private function ensureCatalogItemIsPackage(
        CatalogItem $package
    ): void {
        abort_unless(
            $package->isPackage(),
            422,
            'العنصر المحدد ليس باكج.'
        );
    }

    /**
     * منع تعديل أو حذف محتوى تابع إلى باكج آخر.
     */
    private function ensurePackageItemBelongsToPackage(
        CatalogItem $package,
        PackageItem $packageItem
    ): void {
        abort_unless(
            $packageItem->package_id === $package->id,
            404
        );
    }
}
