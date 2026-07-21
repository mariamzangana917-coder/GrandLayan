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
        Schema::create('categories', function (Blueprint $table) {
            $table->id();

            $table->foreignId('department_id')
                ->constrained()
                ->restrictOnDelete();

            $table->string('name', 100);

            $table->text('description')->nullable();

            /*
             * Disabled categories remain in the database so historical
             * services and bookings are never broken.
             */
            $table->boolean('is_active')
                ->default(true)
                ->index();

            $table->timestamps();
            $table->softDeletes();

            $table->index([
                'department_id',
                'is_active',
            ]);
        });

        /*
         * Category names must be unique inside the same department,
         * ignoring letter case and excluding soft-deleted records.
         *
         * PostgreSQL-specific partial unique index.
         */
        DB::statement(
            'CREATE UNIQUE INDEX categories_department_name_unique_active
             ON categories (department_id, LOWER(name))
             WHERE deleted_at IS NULL'
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
