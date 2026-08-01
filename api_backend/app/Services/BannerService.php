<?php

namespace App\Services;

use App\Enums\BannerActionType;
use App\Models\Banner;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Throwable;

class BannerService
{
    public function create(array $data, UploadedFile $image): Banner
    {
        $path = $this->storeImage($image);

        try {
            return DB::transaction(function () use ($data, $path): Banner {
                $payload = $this->normalizePayload($data);
                $payload['image_path'] = $path;
                $payload['sort_order'] ??= 0;
                $payload['is_active'] ??= true;

                return Banner::query()->create($payload);
            });
        } catch (Throwable $exception) {
            Storage::disk('public')->delete($path);
            throw $exception;
        }
    }

    public function update(Banner $banner, array $data, ?UploadedFile $image): Banner
    {
        $newPath = $image !== null ? $this->storeImage($image) : null;
        $oldPath = $banner->image_path;

        try {
            DB::transaction(function () use ($banner, $data, $newPath): void {
                $payload = $this->normalizePayload($data, $banner);

                if ($newPath !== null) {
                    $payload['image_path'] = $newPath;
                }

                $banner->update($payload);
            });
        } catch (Throwable $exception) {
            if ($newPath !== null) {
                Storage::disk('public')->delete($newPath);
            }

            throw $exception;
        }

        if ($newPath !== null && $oldPath !== $newPath) {
            Storage::disk('public')->delete($oldPath);
        }

        return $banner->refresh();
    }

    public function delete(Banner $banner): void
    {
        $path = $banner->image_path;

        DB::transaction(function () use ($banner): void {
            $banner->delete();
        });

        Storage::disk('public')->delete($path);
    }

    /**
     * @param array<int, array{id:int, sort_order:int}> $items
     */
    public function reorder(array $items): void
    {
        DB::transaction(function () use ($items): void {
            foreach ($items as $item) {
                Banner::query()
                    ->whereKey($item['id'])
                    ->update(['sort_order' => $item['sort_order']]);
            }
        });
    }

    private function storeImage(UploadedFile $image): string
    {
        return $image->storePublicly('banners', 'public');
    }

    private function normalizePayload(array $data, ?Banner $currentBanner = null): array
    {
        $payload = Arr::except($data, ['image']);

        $actionType = array_key_exists('action_type', $payload)
            ? BannerActionType::from($payload['action_type'])
            : $currentBanner?->action_type;

        if ($actionType === null) {
            return $payload;
        }

        $payload['action_type'] = $actionType;

        if ($actionType->requiresTarget()) {
            $payload['external_url'] = null;
        } elseif ($actionType->requiresExternalUrl()) {
            $payload['action_target_id'] = null;
            $payload['external_url'] = trim((string) ($payload['external_url'] ?? $currentBanner?->external_url));
        } else {
            $payload['action_target_id'] = null;
            $payload['external_url'] = null;
        }

        return $payload;
    }
}
