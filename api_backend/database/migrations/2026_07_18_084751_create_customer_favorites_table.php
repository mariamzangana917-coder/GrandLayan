<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_favorites', function (Blueprint $table) {
            $table->id();

            $table->foreignId('customer_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->foreignId('catalog_item_id')
                ->constrained('catalog_items')
                ->cascadeOnDelete();

            $table->timestamps();

            $table->unique(
                ['customer_id', 'catalog_item_id'],
                'customer_favorites_unique'
            );

            $table->index('customer_id');
            $table->index('catalog_item_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_favorites');
    }
};
