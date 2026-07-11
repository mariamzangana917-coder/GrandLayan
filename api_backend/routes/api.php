<?php

use App\Http\Controllers\Api\Admin\CatalogItemController;
use App\Http\Controllers\Api\Admin\CatalogItemImageController;
use App\Http\Controllers\Api\Admin\CategoryController;
use App\Http\Controllers\Api\Auth\AuthController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function (): void {
    Route::post('/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::prefix('admin')
    ->middleware([
        'auth:sanctum',
        'role:manager',
    ])
    ->group(function (): void {
        Route::apiResource(
            'categories',
            CategoryController::class
        )->only([
            'index',
            'store',
            'show',
            'update',
            'destroy',
        ]);

        Route::apiResource(
            'catalog-items',
            CatalogItemController::class
        )->only([
            'index',
            'store',
            'show',
            'update',
            'destroy',
        ]);

        Route::get(
            'catalog-items/{catalogItem}/images',
            [CatalogItemImageController::class, 'index']
        )->name('catalog-items.images.index');

        Route::post(
            'catalog-items/{catalogItem}/images',
            [CatalogItemImageController::class, 'store']
        )->name('catalog-items.images.store');

        Route::patch(
            'catalog-items/{catalogItem}/images/{catalogItemImage}',
            [CatalogItemImageController::class, 'update']
        )->name('catalog-items.images.update');

        Route::delete(
            'catalog-items/{catalogItem}/images/{catalogItemImage}',
            [CatalogItemImageController::class, 'destroy']
        )->name('catalog-items.images.destroy');
    });