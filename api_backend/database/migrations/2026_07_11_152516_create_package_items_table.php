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
        Schema::create('package_items', function (Blueprint $table) {
            $table->id();

            /*
             * Must reference a catalog item of type "package".
             */
            $table->foreignId('package_id')
                ->constrained('catalog_items')
                ->cascadeOnDelete();

            /*
             * Must reference a catalog item of type "service".
             */
            $table->foreignId('service_id')
                ->constrained('catalog_items')
                ->restrictOnDelete();

            /*
             * Quantity supports repeated inclusions when needed.
             * Example: two sessions of the same service.
             */
            $table->unsignedSmallInteger('quantity')
                ->default(1);

            /*
             * Optional note for package-specific details.
             */
            $table->string('notes', 500)->nullable();

            $table->timestamps();

            $table->unique([
                'package_id',
                'service_id',
            ]);

            $table->index('service_id');
        });

        /*
         * Quantity must always be greater than zero.
         */
        DB::statement(
            'ALTER TABLE package_items
             ADD CONSTRAINT package_items_quantity_check
             CHECK (quantity > 0)'
        );

        /*
         * A package cannot contain itself.
         */
        DB::statement(
            'ALTER TABLE package_items
             ADD CONSTRAINT package_items_not_self_reference_check
             CHECK (package_id <> service_id)'
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('package_items');
    }
};
