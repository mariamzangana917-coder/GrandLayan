<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('appointment_items', function (Blueprint $table) {
            $table->id();

            $table->foreignId('appointment_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->foreignId('catalog_item_id')
                ->constrained()
                ->restrictOnDelete();

            /*
             * Snapshots protect old bookings from later catalog changes.
             */
            $table->string('item_type', 20);
            $table->string('item_name', 150);
            $table->string('price_type', 20);

            $table->decimal('unit_price', 12, 2)->nullable();

            $table->unsignedSmallInteger('quantity')
                ->default(1);

            $table->unsignedSmallInteger('duration_minutes')
                ->nullable();

            $table->timestamps();

            $table->unique([
                'appointment_id',
                'catalog_item_id',
            ]);

            $table->index([
                'appointment_id',
                'item_type',
            ]);
        });

        DB::statement(
            "ALTER TABLE appointment_items
             ADD CONSTRAINT appointment_items_type_check
             CHECK (item_type IN ('service', 'package'))"
        );

        DB::statement(
            "ALTER TABLE appointment_items
             ADD CONSTRAINT appointment_items_price_type_check
             CHECK (price_type IN ('fixed', 'inspection'))"
        );

        DB::statement(
            "ALTER TABLE appointment_items
             ADD CONSTRAINT appointment_items_price_check
             CHECK (
                 (price_type = 'fixed' AND unit_price IS NOT NULL AND unit_price >= 0)
                 OR
                 (price_type = 'inspection' AND unit_price IS NULL)
             )"
        );

        DB::statement(
            'ALTER TABLE appointment_items
             ADD CONSTRAINT appointment_items_quantity_check
             CHECK (quantity > 0)'
        );

        DB::statement(
            'ALTER TABLE appointment_items
             ADD CONSTRAINT appointment_items_duration_check
             CHECK (
                 duration_minutes IS NULL
                 OR duration_minutes > 0
             )'
        );
    }

    public function down(): void
    {
        Schema::dropIfExists('appointment_items');
    }
};