<?php

use App\Http\Controllers\Api\Notifications\DeviceTokenController;
use App\Http\Controllers\Api\Notifications\NotificationController;
use App\Http\Controllers\Api\Notifications\NotificationPreferenceController;
use Illuminate\Support\Facades\Route;

$registerNotificationRoutes = static function (): void {
    Route::get('notifications', [NotificationController::class, 'index'])
        ->name('notifications.index');

    Route::get(
        'notifications/unread-count',
        [NotificationController::class, 'unreadCount'],
    )->name('notifications.unread-count');

    Route::patch(
        'notifications/{notification}/read',
        [NotificationController::class, 'markRead'],
    )->name('notifications.read');

    Route::post(
        'notifications/read-all',
        [NotificationController::class, 'markAllRead'],
    )->name('notifications.read-all');

    Route::post('device-tokens', [DeviceTokenController::class, 'store'])
        ->name('device-tokens.store');

    Route::delete(
        'device-tokens/{deviceToken}',
        [DeviceTokenController::class, 'destroy'],
    )->name('device-tokens.destroy');

    Route::get(
        'notification-preferences',
        [NotificationPreferenceController::class, 'show'],
    )->name('notification-preferences.show');

    Route::put(
        'notification-preferences',
        [NotificationPreferenceController::class, 'update'],
    )->name('notification-preferences.update');
};

Route::prefix('customer')
    ->middleware(['auth:sanctum', 'role:customer'])
    ->name('customer.')
    ->group($registerNotificationRoutes);

Route::prefix('admin')
    ->middleware(['auth:sanctum', 'role:manager'])
    ->name('admin.')
    ->group($registerNotificationRoutes);
