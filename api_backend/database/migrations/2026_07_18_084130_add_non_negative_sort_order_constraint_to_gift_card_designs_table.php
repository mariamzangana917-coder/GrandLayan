<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement(
            'ALTER TABLE gift_card_designs
             ADD CONSTRAINT gift_card_designs_sort_order_non_negative
             CHECK (sort_order >= 0)'
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement(
            'ALTER TABLE gift_card_designs
             DROP CONSTRAINT IF EXISTS gift_card_designs_sort_order_non_negative'
        );
    }
};
