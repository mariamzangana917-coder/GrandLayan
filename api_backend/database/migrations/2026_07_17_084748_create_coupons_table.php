<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coupons', function (Blueprint $table): void {
            $table->id();

            $table->string('name', 150);

            $table->string('code', 50)
                ->unique();

            $table->string('discount_type', 20);

            $table->decimal(
                'discount_value',
                12,
                2
            );

            $table->decimal(
                'minimum_order_amount',
                12,
                2
            )->nullable();

            $table->decimal(
                'maximum_discount_amount',
                12,
                2
            )->nullable();

            /*
             * null means the coupon applies to both departments.
             */
            $table->foreignId('department_id')
                ->nullable()
                ->constrained('departments')
                ->restrictOnDelete();

            $table->unsignedInteger(
                'maximum_total_uses'
            )->nullable();

            $table->unsignedInteger(
                'maximum_uses_per_customer'
            )->default(1);

            $table->unsignedInteger(
                'used_count'
            )->default(0);

            $table->timestampTz(
                'starts_at'
            )->nullable();

            $table->timestampTz(
                'expires_at'
            )->nullable();

            $table->boolean(
                'is_active'
            )->default(true);

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index([
                'is_active',
                'starts_at',
                'expires_at',
            ]);

            $table->index('department_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coupons');
    }
};
