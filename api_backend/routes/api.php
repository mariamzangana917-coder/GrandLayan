<?php

use App\Http\Controllers\Api\Admin\CatalogItemController;
use App\Http\Controllers\Api\Admin\CatalogItemImageController;
use App\Http\Controllers\Api\Admin\CategoryController;
use App\Http\Controllers\Api\Admin\CustomerController;
use App\Http\Controllers\Api\Admin\PackageItemController;
use App\Http\Controllers\Api\Appointments\AppointmentController;
use App\Http\Controllers\Api\Auth\AuthController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Authentication Routes
|--------------------------------------------------------------------------
*/

Route::prefix('auth')->group(function (): void {
    Route::post(
        '/login',
        [AuthController::class, 'login']
    );

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get(
            '/me',
            [AuthController::class, 'me']
        );

        Route::post(
            '/logout',
            [AuthController::class, 'logout']
        );
    });
});

/*
|--------------------------------------------------------------------------
| Customer Appointment Routes
|--------------------------------------------------------------------------
|
| هذه المسارات خاصة بالزبونة فقط.
| لا يجب وضعها داخل مجموعة admin.
|
*/

Route::prefix('appointments')
    ->middleware([
        'auth:sanctum',
        'role:customer',
    ])
    ->group(function (): void {
        Route::post(
            '/',
            [AppointmentController::class, 'store']
        )->name('appointments.store');
    });

/*
|--------------------------------------------------------------------------
| Admin Routes
|--------------------------------------------------------------------------
|
| جميع المسارات هنا خاصة بالمديرة فقط.
|
*/

Route::prefix('admin')
    ->middleware([
        'auth:sanctum',
        'role:manager',
    ])
    ->group(function (): void {
        /*
        |--------------------------------------------------------------------------
        | Customer Management
        |--------------------------------------------------------------------------
        */

        Route::get(
            'customers',
            [CustomerController::class, 'index']
        )->name('customers.index');

        /*
        |--------------------------------------------------------------------------
        | Categories
        |--------------------------------------------------------------------------
        */

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

        /*
        |--------------------------------------------------------------------------
        | Catalog Items
        |--------------------------------------------------------------------------
        */

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

        /*
        |--------------------------------------------------------------------------
        | Catalog Item Images
        |--------------------------------------------------------------------------
        */

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

        /*
        |--------------------------------------------------------------------------
        | Package Contents
        |--------------------------------------------------------------------------
        */

        Route::get(
            'packages/{package}/items',
            [PackageItemController::class, 'index']
        )->name('packages.items.index');

        Route::post(
            'packages/{package}/items',
            [PackageItemController::class, 'store']
        )->name('packages.items.store');

        Route::patch(
            'packages/{package}/items/{packageItem}',
            [PackageItemController::class, 'update']
        )->name('packages.items.update');

        Route::delete(
            'packages/{package}/items/{packageItem}',
            [PackageItemController::class, 'destroy']
        )->name('packages.items.destroy');
    });