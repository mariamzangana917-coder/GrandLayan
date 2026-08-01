<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('banners', function (Blueprint $table): void {
            $table->id();
            $table->string('title', 120)->nullable();
            $table->string('subtitle', 220)->nullable();
            $table->string('image_path', 500);
            $table->string('action_type', 32)->default('none');
            $table->unsignedBigInteger('action_target_id')->nullable();
            $table->string('external_url', 2048)->nullable();
            $table->timestampTz('starts_at')->nullable();
            $table->timestampTz('ends_at')->nullable();
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();

            $table->index(['is_active', 'starts_at', 'ends_at'], 'banners_visibility_index');
            $table->index(['sort_order', 'id'], 'banners_sort_index');
            $table->index(['action_type', 'action_target_id'], 'banners_action_index');
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement(<<<'SQL'
                ALTER TABLE banners
                ADD CONSTRAINT banners_action_type_check
                CHECK (action_type IN (
                    'none',
                    'department',
                    'category',
                    'catalog_item',
                    'offers',
                    'booking',
                    'gift_card',
                    'external_url'
                ))
            SQL);

            DB::statement(<<<'SQL'
                ALTER TABLE banners
                ADD CONSTRAINT banners_date_range_check
                CHECK (
                    ends_at IS NULL
                    OR starts_at IS NULL
                    OR ends_at >= starts_at
                )
            SQL);

            DB::statement(<<<'SQL'
                ALTER TABLE banners
                ADD CONSTRAINT banners_action_payload_check
                CHECK (
                    (
                        action_type IN ('none', 'offers', 'booking', 'gift_card')
                        AND action_target_id IS NULL
                        AND external_url IS NULL
                    )
                    OR
                    (
                        action_type IN ('department', 'category', 'catalog_item')
                        AND action_target_id IS NOT NULL
                        AND external_url IS NULL
                    )
                    OR
                    (
                        action_type = 'external_url'
                        AND action_target_id IS NULL
                        AND external_url IS NOT NULL
                    )
                )
            SQL);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('banners');
    }
};
