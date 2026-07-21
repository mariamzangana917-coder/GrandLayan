<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('appointment_services', function (Blueprint $table) {
            $table->id();

            $table->foreignId('appointment_item_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->foreignId('service_id')
                ->constrained('catalog_items')
                ->restrictOnDelete();

            /*
             * Snapshot of service information at booking time.
             */
            $table->string('service_name', 150);

            $table->unsignedSmallInteger('quantity')
                ->default(1);

            $table->unsignedSmallInteger('duration_minutes');

            /*
             * Null for package components when the commercial price belongs
             * to the package, or for inspection-priced services.
             */
            $table->decimal('unit_price', 12, 2)->nullable();

            /*
             * Employee assignment will be added later when the internal
             * employee records are implemented.
             */
            $table->timestampTz('scheduled_start_at')->nullable();
            $table->timestampTz('scheduled_end_at')->nullable();

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique([
                'appointment_item_id',
                'service_id',
            ]);

            $table->index('service_id');

            $table->index([
                'scheduled_start_at',
                'scheduled_end_at',
            ]);
        });

        DB::statement(
            'ALTER TABLE appointment_services
             ADD CONSTRAINT appointment_services_quantity_check
             CHECK (quantity > 0)'
        );

        DB::statement(
            'ALTER TABLE appointment_services
             ADD CONSTRAINT appointment_services_duration_check
             CHECK (duration_minutes > 0)'
        );

        DB::statement(
            'ALTER TABLE appointment_services
             ADD CONSTRAINT appointment_services_price_check
             CHECK (
                 unit_price IS NULL
                 OR unit_price >= 0
             )'
        );

        DB::statement(
            'ALTER TABLE appointment_services
             ADD CONSTRAINT appointment_services_time_check
             CHECK (
                 scheduled_start_at IS NULL
                 OR scheduled_end_at IS NULL
                 OR scheduled_end_at > scheduled_start_at
             )'
        );
    }

    public function down(): void
    {
        Schema::dropIfExists('appointment_services');
    }
};
