<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement(
            "ALTER TABLE coupon_redemptions
             ADD CONSTRAINT coupon_redemptions_status_check
             CHECK (status IN ('applied', 'cancelled'))"
        );

        Schema::table('coupon_redemptions', function (Blueprint $table): void {
            $table->index(
                ['coupon_id', 'customer_id', 'status'],
                'coupon_redemptions_usage_lookup_index'
            );
        });
    }

    public function down(): void
    {
        Schema::table('coupon_redemptions', function (Blueprint $table): void {
            $table->dropIndex('coupon_redemptions_usage_lookup_index');
        });

        DB::statement(
            'ALTER TABLE coupon_redemptions
             DROP CONSTRAINT IF EXISTS coupon_redemptions_status_check'
        );
    }
};
