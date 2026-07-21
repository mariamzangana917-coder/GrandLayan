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
        Schema::create('gift_card_designs', function (Blueprint $table): void {
            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Basic information
            |--------------------------------------------------------------------------
            */

            $table->string('name', 120);
            $table->text('description')->nullable();
            $table->string('image_path')->nullable();

            /*
            |--------------------------------------------------------------------------
            | Card value
            |--------------------------------------------------------------------------
            |
            | القيمة المالية التي يحصل عليها المشتري عند شراء هذا التصميم.
            |
            */

            $table->decimal('amount', 12, 2);

            /*
            |--------------------------------------------------------------------------
            | Validity
            |--------------------------------------------------------------------------
            |
            | عدد أيام صلاحية البطاقة من تاريخ إصدارها.
            | الافتراضي سنة واحدة.
            |
            */

            $table->unsignedInteger('validity_days')->default(365);

            /*
            |--------------------------------------------------------------------------
            | Visibility and ordering
            |--------------------------------------------------------------------------
            */

            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);

            $table->timestamps();

            $table->index(
                ['is_active', 'sort_order'],
                'gift_card_designs_active_sort_index'
            );
        });

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_designs
            ADD CONSTRAINT gift_card_designs_amount_check
            CHECK (amount > 0)
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_designs
            ADD CONSTRAINT gift_card_designs_validity_check
            CHECK (validity_days > 0)
            SQL
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('gift_card_designs');
    }
};
