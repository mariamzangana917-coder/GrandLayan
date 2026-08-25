<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('banners', function (Blueprint $table): void {
            $table->string('placement', 20)->default('home')->after('image_path');
            $table->index(['placement', 'is_active', 'sort_order'], 'banners_placement_visibility_index');
        });
    }

    public function down(): void
    {
        Schema::table('banners', function (Blueprint $table): void {
            $table->dropIndex('banners_placement_visibility_index');
            $table->dropColumn('placement');
        });
    }
};
