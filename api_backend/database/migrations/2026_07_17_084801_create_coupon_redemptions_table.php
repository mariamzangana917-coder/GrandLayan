<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create(
            'coupon_redemptions',
            function (Blueprint $table): void {
                $table->id();

                $table->foreignId('coupon_id')
                    ->constrained('coupons')
                    ->restrictOnDelete();

                $table->foreignId('customer_id')
                    ->constrained('users')
                    ->restrictOnDelete();
                $table->foreignId('appointment_id')
                    ->constrained('appointments')
                    ->restrictOnDelete();

                $table->decimal(
                    'subtotal_amount',
                    12,
                    2
                );

                $table->decimal(
                    'discount_amount',
                    12,
                    2
                );

                $table->decimal(
                    'final_amount',
                    12,
                    2
                );

                $table->timestampTz(
                    'redeemed_at'
                )->useCurrent();

                $table->timestamps();

                $table->unique('appointment_id');

                $table->index([
                    'coupon_id',
                    'customer_id',
                ]);

                $table->index('redeemed_at');

                $table->string('status', 20)->default('applied');
            }
        );
    }

    public function down(): void
    {
        Schema::dropIfExists(
            'coupon_redemptions'
        );
    }
};
