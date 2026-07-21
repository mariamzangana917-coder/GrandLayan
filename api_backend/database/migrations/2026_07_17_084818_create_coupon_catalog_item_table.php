<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create(
            'coupon_catalog_item',
            function (Blueprint $table): void {
                $table->id();

                $table->foreignId('coupon_id')
                    ->constrained('coupons')
                    ->cascadeOnDelete();

                $table->foreignId('catalog_item_id')
                    ->constrained('catalog_items')
                    ->cascadeOnDelete();

                $table->timestamps();

                $table->unique([
                    'coupon_id',
                    'catalog_item_id',
                ]);
            }
        );
    }

    public function down(): void
    {
        Schema::dropIfExists(
            'coupon_catalog_item'
        );
    }
};
