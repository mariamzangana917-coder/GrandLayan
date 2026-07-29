<?php

use App\Http\Controllers\Api\Admin\OfferController;
use App\Http\Controllers\Api\Customer\Offers\CustomerOfferController;
use Illuminate\Support\Facades\Route;

Route::prefix('admin')
    ->middleware(['auth:sanctum', 'role:manager'])
    ->name('admin.')
    ->group(function (): void {
        Route::get('offers', [OfferController::class, 'index'])
            ->name('offers.index');

        Route::post('offers', [OfferController::class, 'store'])
            ->name('offers.store');

        Route::get('offers/{offer}', [OfferController::class, 'show'])
            ->name('offers.show');

        Route::match(
            ['put', 'patch'],
            'offers/{offer}',
            [OfferController::class, 'update'],
        )->name('offers.update');

        Route::post(
            'offers/{offer}/image',
            [OfferController::class, 'replaceImage'],
        )->name('offers.image.update');

        Route::delete('offers/{offer}', [OfferController::class, 'destroy'])
            ->name('offers.destroy');
    });

Route::prefix('customer')
    ->middleware(['auth:sanctum', 'role:customer'])
    ->name('customer.')
    ->group(function (): void {
        Route::get('offers', [CustomerOfferController::class, 'index'])
            ->name('offers.index');

        Route::get(
            'offers/{offer}',
            [CustomerOfferController::class, 'show'],
        )->whereNumber('offer')
            ->name('offers.show');
    });
