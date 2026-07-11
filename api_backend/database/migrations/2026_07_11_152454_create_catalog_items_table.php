<?php

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
        Schema::create('catalog_items', function (Blueprint $table) {
            $table->id();

            $table->foreignId('category_id')
                ->constrained()
                ->restrictOnDelete();

            /*
             * service: regular bookable service.
             * package: a package composed of one or more services.
             */
            $table->string('type', 20);

            $table->string('name', 150);

            $table->text('description')->nullable();

            $table->text('instructions')->nullable();

            /*
             * fixed: item has a known price.
             * inspection: price is determined after examination.
             */
            $table->string('price_type', 20)
                ->default('fixed');

            /*
             * Iraqi dinar amounts are normally whole numbers, but decimal
             * storage preserves compatibility with future payment gateways.
             */
            $table->decimal('price', 12, 2)->nullable();

            /*
             * Estimated duration used later when calculating appointment time.
             */
            $table->unsignedSmallInteger('duration_minutes')->nullable();

            /*
             * Disabling hides the item from new bookings while preserving
             * previous appointments, invoices and reports.
             */
            $table->boolean('is_active')
                ->default(true)
                ->index();

            $table->timestamps();
            $table->softDeletes();

            $table->index([
                'category_id',
                'type',
                'is_active',
            ]);

            $table->index('price_type');
        });

        /*
         * Only the officially supported catalog item types are accepted.
         */
        DB::statement(
            "ALTER TABLE catalog_items
             ADD CONSTRAINT catalog_items_type_check
             CHECK (type IN ('service', 'package'))"
        );

        /*
         * A fixed-price item must have a non-negative price.
         * An inspection item must not store a price before examination.
         */
        DB::statement(
            "ALTER TABLE catalog_items
             ADD CONSTRAINT catalog_items_price_check
             CHECK (
                 (price_type = 'fixed' AND price IS NOT NULL AND price >= 0)
                 OR
                 (price_type = 'inspection' AND price IS NULL)
             )"
        );

        /*
         * Prevent unsupported price types.
         */
        DB::statement(
            "ALTER TABLE catalog_items
             ADD CONSTRAINT catalog_items_price_type_check
             CHECK (price_type IN ('fixed', 'inspection'))"
        );

        /*
         * Duration, when provided, must be greater than zero.
         */
        DB::statement(
            'ALTER TABLE catalog_items
             ADD CONSTRAINT catalog_items_duration_check
             CHECK (
                 duration_minutes IS NULL
                 OR duration_minutes > 0
             )'
        );

        /*
         * Prevent duplicate active names inside the same category.
         * A deleted item may later be recreated with the same name.
         */
        DB::statement(
            'CREATE UNIQUE INDEX catalog_items_category_name_unique_active
             ON catalog_items (category_id, LOWER(name))
             WHERE deleted_at IS NULL'
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('catalog_items');
    }
};