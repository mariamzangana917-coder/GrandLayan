<?php

use App\Http\Controllers\Api\Admin\BannerController as AdminBannerController;
use App\Http\Controllers\Api\Customer\BannerController as CustomerBannerController;

use App\Http\Controllers\Api\Customer\Chat\CustomerChatController;
use App\Http\Controllers\Api\Admin\AdminAppointmentController;
use App\Http\Controllers\Api\Admin\AdminGiftCardOrderController;
use App\Http\Controllers\Api\Admin\CatalogItemController;
use App\Http\Controllers\Api\Admin\CatalogItemImageController;
use App\Http\Controllers\Api\Admin\CategoryController;
use App\Http\Controllers\Api\Admin\CouponController;
use App\Http\Controllers\Api\Admin\CustomerController;
use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\PackageItemController;
use App\Http\Controllers\Api\Appointments\AppointmentController;
use App\Http\Controllers\Api\Customer\GiftCards\CustomerGiftCardDesignController;
use App\Http\Controllers\Api\Admin\AdminGiftCardTransactionController;
use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\Customer\Auth\CustomerAuthController;
use App\Http\Controllers\Api\Customer\Catalog\CustomerCatalogController;
use App\Http\Controllers\Api\Customer\Favorite\CustomerFavoriteController;
use App\Http\Controllers\Api\Customer\GiftCards\CustomerGiftCardController;
use App\Http\Controllers\Api\Customer\GiftCards\CustomerGiftCardOrderController;
use App\Http\Controllers\Api\Customer\GiftCards\CustomerGiftCardTransactionController;
use App\Http\Controllers\Api\Customer\Profile\CustomerProfileController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Admin\GiftCardDesignController;
use App\Http\Controllers\Api\Admin\AdminGiftCardController;



/*
|--------------------------------------------------------------------------
| Admin Authentication Routes
|--------------------------------------------------------------------------
|
| هذه المسارات خاصة بتطبيق الإدارة.
| لا تسمح بتسجيل الدخول إلا لحساب manager.
|
*/

Route::prefix('auth')
    ->group(function (): void {
        Route::post(
            'login',
            [AuthController::class, 'login']
        )
            ->middleware('throttle:5,1')
            ->name('auth.login');

        Route::middleware('auth:sanctum')
            ->group(function (): void {
                Route::get(
                    'me',
                    [AuthController::class, 'me']
                )->name('auth.me');

                Route::post(
                    'logout',
                    [AuthController::class, 'logout']
                )->name('auth.logout');
            });


            
    });

/*
|--------------------------------------------------------------------------
| Customer Authentication Routes
|--------------------------------------------------------------------------
|
| هذه المسارات خاصة بتطبيق الزبونة.
| إنشاء الحساب يفرض دور customer من الـ Backend.
|
*/

Route::prefix('customer/auth')
    ->group(function (): void {
        Route::post(
            'register',
            [CustomerAuthController::class, 'register']
        )
            ->middleware('throttle:3,1')
            ->name('customer.auth.register');

        Route::post(
            'login',
            [CustomerAuthController::class, 'login']
        )
            ->middleware('throttle:5,1')
            ->name('customer.auth.login');

        Route::middleware([
            'auth:sanctum',
            'role:customer',
        ])->group(function (): void {
            Route::get(
                'me',
                [CustomerAuthController::class, 'me']
            )->name('customer.auth.me');

            Route::post(
                'logout',
                [CustomerAuthController::class, 'logout']
            )->name('customer.auth.logout');

            Route::prefix('chat')->group(function (): void {
    Route::get('/conversations', [CustomerChatController::class, 'index']);
    Route::get('/conversations/{conversation}', [CustomerChatController::class, 'show']);
    Route::post('/messages', [CustomerChatController::class, 'send']);
});
        });
    });

/*
      me('customer.catalog-items.show');

/*
|--------------------------------------------------------------------------
| Customer Profile And Favorites Routes
|--------------------------------------------------------------------------
|
| هذه المسارات خاصة ببيانات الزبونة ومفضلاتها.
|
*/
Route::prefix('customer')
    ->middleware([
        'auth:sanctum',
        'role:customer',
    ])
    ->group(function (): void {

                Route::get(
            'banners',
            [CustomerBannerController::class, 'index']
        )->name('customer.banners.index');
/*
        |--------------------------------------------------------------------------
        | Customer Catalog
        |--------------------------------------------------------------------------
        */

        Route::get(
            'catalog-items',
            [CustomerCatalogController::class, 'index']
        )->name('customer.catalog-items.index');

        Route::get(
            'catalog-items/{catalogItem}',
            [CustomerCatalogController::class, 'show']
        )->name('customer.catalog-items.show');

        /*
        |--------------------------------------------------------------------------
        | Customer Profile
        |--------------------------------------------------------------------------
        */

        Route::put(
            'profile',
            [CustomerProfileController::class, 'update']
        )->name('customer.profile.update');

        Route::post(
            'profile/avatar',
            [CustomerProfileController::class, 'updateAvatar']
        )->name('customer.profile.avatar.update');

        Route::delete(
            'profile/avatar',
            [CustomerProfileController::class, 'destroyAvatar']
        )->name('customer.profile.avatar.destroy');

        /*
        |--------------------------------------------------------------------------
        | Customer Favorites
        |--------------------------------------------------------------------------
        */

        Route::get(
            'favorites',
            [CustomerFavoriteController::class, 'index']
        )->name('customer.favorites.index');

        Route::post(
            'favorites/{catalogItem}',
            [CustomerFavoriteController::class, 'store']
        )->name('customer.favorites.store');

        Route::delete(
            'favorites/{catalogItem}',
            [CustomerFavoriteController::class, 'destroy']
        )->name('customer.favorites.destroy');

        /*
        |--------------------------------------------------------------------------
        | Customer Gift Card Designs
        |--------------------------------------------------------------------------
        */

        Route::get(
            'gift-card-designs',
            [CustomerGiftCardDesignController::class, 'index']
        )->name('customer.gift-card-designs.index');

        /*
        |--------------------------------------------------------------------------
        | Customer Gift Card Orders
        |--------------------------------------------------------------------------
        */

        Route::get(
            'gift-card-orders',
            [CustomerGiftCardOrderController::class, 'index']
        )->name('customer.gift-card-orders.index');

        Route::post(
            'gift-card-orders',
            [CustomerGiftCardOrderController::class, 'store']
        )->name('customer.gift-card-orders.store');

        Route::get(
            'gift-card-orders/{giftCardOrder}',
            [CustomerGiftCardOrderController::class, 'show']
        )->name('customer.gift-card-orders.show');

        /*
        |--------------------------------------------------------------------------
        | Customer Gift Cards
        |--------------------------------------------------------------------------
        |
        | تعرض البطاقات الصادرة والمملوكة للزبونة المسجلة فقط.
        |
        */

        Route::get(
            'gift-cards',
            [CustomerGiftCardController::class, 'index']
        )->name('customer.gift-cards.index');

        Route::get(
            'gift-cards/{giftCard}',
            [CustomerGiftCardController::class, 'show']
        )->name('customer.gift-cards.show');

        Route::get(
            'gift-cards/{giftCard}/transactions',
            [CustomerGiftCardTransactionController::class, 'index']
        )->name('customer.gift-cards.transactions.index');
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
        Route::get(
            '/',
            [AppointmentController::class, 'index']
        )->name('appointments.index');

        Route::post(
            '/',
            [AppointmentController::class, 'store']
        )->name('appointments.store');

        Route::get(
            '{appointment}',
            [AppointmentController::class, 'show']
        )
            ->whereNumber('appointment')
            ->name('appointments.show');

        Route::post(
            '{appointment}/cancel',
            [AppointmentController::class, 'cancel']
        )
            ->whereNumber('appointment')
            ->name('appointments.cancel');



            
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
                Route::post(
            'banners/reorder',
            [AdminBannerController::class, 'reorder']
        )->name('admin.banners.reorder');

        Route::apiResource(
            'banners',
            AdminBannerController::class
        );
/*
        |--------------------------------------------------------------------------
        | Dashboard
        |--------------------------------------------------------------------------
        */

        Route::get(
            'dashboard',
            DashboardController::class
        )->name('admin.dashboard');

/*
|--------------------------------------------------------------------------
| Gift Card Designs
|--------------------------------------------------------------------------
*/

Route::delete(
    'gift-card-designs/{giftCardDesign}/image',
    [GiftCardDesignController::class, 'destroyImage']
)->name('admin.gift-card-designs.image.destroy');

Route::apiResource(
    'gift-card-designs',
    GiftCardDesignController::class
)->parameters([
    'gift-card-designs' => 'giftCardDesign',
]);




        /*
|--------------------------------------------------------------------------
| Gift Card Orders
|--------------------------------------------------------------------------
*/

        Route::get(
            'gift-card-orders',
            [AdminGiftCardOrderController::class, 'index']
        )->name('admin.gift-card-orders.index');

        Route::get(
            'gift-card-orders/{giftCardOrder}',
            [AdminGiftCardOrderController::class, 'show']
        )->name('admin.gift-card-orders.show');

        Route::post(
            'gift-card-orders/{giftCardOrder}/issue',
            [AdminGiftCardOrderController::class, 'issue']
        )->name('admin.gift-card-orders.issue');



Route::get(
    'gift-cards',
    [AdminGiftCardController::class, 'index']
)->name('admin.gift-cards.index');

Route::get(
    'gift-cards/{giftCard}',
    [AdminGiftCardController::class, 'show']
)->name('admin.gift-cards.show');


Route::post(
    'gift-cards/{giftCard}/redeem',
    [AdminGiftCardTransactionController::class, 'redeem']
)->name('admin.gift-cards.redeem');

Route::post(
    'gift-cards/{giftCard}/refund',
    [AdminGiftCardTransactionController::class, 'refund']
)->name('admin.gift-cards.refund');

        /*
        |--------------------------------------------------------------------------
        | Coupons
        |--------------------------------------------------------------------------
        */

        Route::apiResource(
            'coupons',
            CouponController::class
        );

        /*
        |--------------------------------------------------------------------------
        | Customer Management
        |--------------------------------------------------------------------------
        */

        Route::get(
            'customers',
            [CustomerController::class, 'index']
        )->name('customers.index');

        Route::get(
            'customers/{customer}',
            [CustomerController::class, 'show']
        )->name('customers.show');

        /*
        |--------------------------------------------------------------------------
        | Appointment Management
        |--------------------------------------------------------------------------
        */

        Route::get(
            'appointments',
            [AdminAppointmentController::class, 'index']
        )->name('admin.appointments.index');

        Route::get(
            'appointments/{appointment}',
            [AdminAppointmentController::class, 'show']
        )->name('admin.appointments.show');

        Route::patch(
            'appointments/{appointment}',
            [AdminAppointmentController::class, 'update']
        )->name('admin.appointments.update');

        Route::post(
            'appointments/{appointment}/confirm',
            [AdminAppointmentController::class, 'confirm']
        )->name('admin.appointments.confirm');

        Route::post(
            'appointments/{appointment}/start',
            [AdminAppointmentController::class, 'start']
        )->name('admin.appointments.start');

        Route::post(
            'appointments/{appointment}/complete',
            [AdminAppointmentController::class, 'complete']
        )->name('admin.appointments.complete');

        Route::post(
            'appointments/{appointment}/cancel',
            [AdminAppointmentController::class, 'cancel']
        )->name('admin.appointments.cancel');

        Route::post(
            'appointments/{appointment}/no-show',
            [AdminAppointmentController::class, 'noShow']
        )->name('admin.appointments.no-show');

        /*
        |--------------------------------------------------------------------------
        | Categories
        |--------------------------------------------------------------------------
        */

        Route::delete(
            'categories/{category}/image',
            [CategoryController::class, 'destroyImage']
        )->name('categories.image.destroy');

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

require __DIR__.'/offers.php';

/*
|--------------------------------------------------------------------------
| Admin Department Lookup
|--------------------------------------------------------------------------
*/

Route::prefix('admin')
    ->middleware([
        'auth:sanctum',
        'role:manager',
    ])
    ->get(
        'departments',
        [
            \App\Http\Controllers\Api\Admin\DepartmentLookupController::class,
            'index',
        ]
    )
    ->name('admin.departments.index');


require __DIR__.'/notifications.php';
