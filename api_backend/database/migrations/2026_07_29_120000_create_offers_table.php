<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('offers', function (Blueprint $table): void {
            $table->id();

            $table->foreignId('department_id')
                ->constrained('departments')
                ->restrictOnDelete();

            $table->foreignId('catalog_item_id')
                ->nullable()
                ->constrained('catalog_items')
                ->nullOnDelete();

            $table->foreignId('created_by_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->string('title', 150);
            $table->text('description')->nullable();
            $table->string('badge_text', 50)->nullable();
            $table->string('value_text', 100)->nullable();
            $table->string('details_text', 150)->nullable();
            $table->string('image_path');

            $table->timestampTz('starts_at');
            $table->timestampTz('ends_at');

            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);

            $table->timestampsTz();
            $table->softDeletesTz();

            $table->index(
                ['is_active', 'starts_at', 'ends_at'],
                'offers_active_window_index',
            );

            $table->index(
                ['department_id', 'sort_order', 'id'],
                'offers_department_sort_index',
            );
        });

        DB::statement(
            'ALTER TABLE offers
             ADD CONSTRAINT offers_valid_date_range_check
             CHECK (ends_at > starts_at)',
        );

        DB::statement(
            'ALTER TABLE offers
             ADD CONSTRAINT offers_non_negative_sort_order_check
             CHECK (sort_order >= 0)',
        );
    }

    public function down(): void
    {
        Schema::dropIfExists('offers');
    }
};
