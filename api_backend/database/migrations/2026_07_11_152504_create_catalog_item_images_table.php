php artisan tinker --execute="dump(\Illuminate\Support\Facades\Schema::getColumnListing('catalog_item_images'));"<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('catalog_item_images', function (Blueprint $table) {
            $table->id();

            $table->foreignId('catalog_item_id')
                ->constrained()
                ->cascadeOnDelete();

            /*
             * The database stores the file path or storage key,
             * not the image binary itself.
             */
            $table->string('path', 500);

            /*
             * Optional accessible URL when external/cloud storage is used.
             */
            $table->string('url', 1000)->nullable();

            $table->string('alt_text', 255)->nullable();

            /*
             * Only one image should be the primary image for each item.
             */
            $table->boolean('is_primary')
                ->default(false);

            /*
             * Used to control image display order.
             */
            $table->unsignedSmallInteger('sort_order')
                ->default(0);

            $table->timestamps();

            $table->index([
                'catalog_item_id',
                'sort_order',
            ]);
        });

        /*
         * PostgreSQL partial unique index:
         * each catalog item may have only one primary image.
         */
        DB::statement(
            'CREATE UNIQUE INDEX catalog_item_images_one_primary_per_item
             ON catalog_item_images (catalog_item_id)
             WHERE is_primary = true'
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('catalog_item_images');
    }
};
