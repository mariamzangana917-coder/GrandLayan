<?php
use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\CatalogItemController;
use App\Http\Controllers\Api\Admin\CatalogItemImageController;
use App\Http\Controllers\Api\Admin\CategoryController;
use App\Http\Controllers\Api\Admin\CustomerController;
use App\Http\Controllers\Api\Admin\PackageItemController;
use App\Http\Controllers\Api\Appointments\AppointmentController;
use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\Customer\Auth\CustomerAuthController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Admin\AdminAppointmentController;

/*
|--------------------------------------------------------------------------
| Admin Authentication Routes
|--------------------------------------------------------------------------
|
| هذه المسارات خاصة بتطبيق الإدارة.
| لا تسمح إلا بدخول حساب manager.
|
*/

Route::prefix('auth')->group(function (): void {
    Route::post(
        '/login',
        [AuthController::class, 'login']
    )->name('auth.login');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get(
            '/me',
            [AuthController::class, 'me']
        )->name('auth.me');

        Route::post(
            '/logout',
            [AuthController::class, 'logout']
        )->name('auth.logout');
    });
});

/*
|--------------------------------------------------------------------------
| Customer Authentication Routes
|--------------------------------------------------------------------------
|
| هذه المسارات خاصة بتطبيق الزبونة فقط.
| إنشاء الحساب يفرض دور customer من الـ Backend.
|
*/

Route::prefix('customer/auth')->group(function (): void {
    Route::post(
        '/register',
        [CustomerAuthController::class, 'register']
    )->name('customer.auth.register');

    Route::post(
        '/login',
        [CustomerAuthController::class, 'login']
    )->name('customer.auth.login');

    Route::middleware([
        'auth:sanctum',
        'role:customer',
    ])->group(function (): void {
        Route::get(
            '/me',
            [CustomerAuthController::class, 'me']
        )->name('customer.auth.me');

        Route::post(
            '/logout',
            [CustomerAuthController::class, 'logout']
        )->name('customer.auth.logout');
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
    'customers/{customer}',
    [CustomerController::class, 'show']
)->name('customers.show');

Route::get(
    'appointments',
    [AdminAppointmentController::class, 'index']
)->name('admin.appointments.index');

        Route::get(
            'dashboard',
            DashboardController::class
        )->name('admin.dashboard');

        Route::get(
            'customers',
            [CustomerController::class, 'index']
        )->name('customers.index');

        Route::get(
    'appointments/{appointment}',
    [AdminAppointmentController::class, 'show']
)->name('admin.appointments.show');

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