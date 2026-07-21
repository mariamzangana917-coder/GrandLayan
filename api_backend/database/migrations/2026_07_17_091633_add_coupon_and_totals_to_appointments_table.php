<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('appointments', function (Blueprint $table): void {
            $table->foreignId('coupon_id')
                ->nullable()
                ->after('department_id')
                ->constrained('coupons')
                ->nullOnDelete();

            $table->decimal('subtotal_amount', 12, 2)
                ->nullable()
                ->after('coupon_id');

            $table->decimal('discount_amount', 12, 2)
                ->default(0)
                ->after('subtotal_amount');

            $table->decimal('final_amount', 12, 2)
                ->nullable()
                ->after('discount_amount');

            $table->index('coupon_id');
        });

        DB::statement(
            'ALTER TABLE appointments
             ADD CONSTRAINT appointments_subtotal_amount_check
             CHECK (
                 subtotal_amount IS NULL
                 OR subtotal_amount >= 0
             )'
        );

        DB::statement(
            'ALTER TABLE appointments
             ADD CONSTRAINT appointments_discount_amount_check
             CHECK (discount_amount >= 0)'
        );

        DB::statement(
            'ALTER TABLE appointments
             ADD CONSTRAINT appointments_final_amount_check
             CHECK (
                 final_amount IS NULL
                 OR final_amount >= 0
             )'
        );

        DB::statement(
            'ALTER TABLE appointments
             ADD CONSTRAINT appointments_discount_not_above_subtotal_check
             CHECK (
                 subtotal_amount IS NULL
                 OR discount_amount <= subtotal_amount
             )'
        );

        DB::statement(
            'ALTER TABLE appointments
             ADD CONSTRAINT appointments_final_amount_consistency_check
             CHECK (
                 subtotal_amount IS NULL
                 OR final_amount IS NULL
                 OR final_amount = subtotal_amount - discount_amount
             )'
        );
    }

    public function down(): void
    {
        DB::statement(
            'ALTER TABLE appointments
             DROP CONSTRAINT IF EXISTS
             appointments_final_amount_consistency_check'
        );

        DB::statement(
            'ALTER TABLE appointments
             DROP CONSTRAINT IF EXISTS
             appointments_discount_not_above_subtotal_check'
        );

        DB::statement(
            'ALTER TABLE appointments
             DROP CONSTRAINT IF EXISTS
             appointments_final_amount_check'
        );

        DB::statement(
            'ALTER TABLE appointments
             DROP CONSTRAINT IF EXISTS
             appointments_discount_amount_check'
        );

        DB::statement(
            'ALTER TABLE appointments
             DROP CONSTRAINT IF EXISTS
             appointments_subtotal_amount_check'
        );

        Schema::table('appointments', function (Blueprint $table): void {
            $table->dropForeign(['coupon_id']);
            $table->dropIndex(['coupon_id']);

            $table->dropColumn([
                'coupon_id',
                'subtotal_amount',
                'discount_amount',
                'final_amount',
            ]);
        });
    }
};
