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
        Schema::create('gift_cards', function (Blueprint $table): void {
            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Source order
            |--------------------------------------------------------------------------
            |
            | كل طلب شراء مكتمل يصدر بطاقة واحدة فقط.
            |
            */

            $table->foreignId('gift_card_order_id')
                ->unique()
                ->constrained('gift_card_orders')
                ->restrictOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Verification data
            |--------------------------------------------------------------------------
            |
            | code:
            | كود البطاقة الذي يمكن إدخاله يدويًا.
            |
            | qr_token:
            | رمز عشوائي طويل وآمن يوضع داخل QR.
            |
            */

            $table->string('code', 32)->unique();
            $table->string('qr_token', 64)->unique();

            /*
            |--------------------------------------------------------------------------
            | Balance
            |--------------------------------------------------------------------------
            */

            $table->decimal('initial_balance', 12, 2);
            $table->decimal('remaining_balance', 12, 2);

            /*
            |--------------------------------------------------------------------------
            | Status
            |--------------------------------------------------------------------------
            |
            | active         = صالحة للاستخدام
            | fully_redeemed = تم استهلاك الرصيد بالكامل
            | expired        = انتهت الصلاحية
            | cancelled      = ألغتها المديرة
            |
            */

            $table->string('status', 30)->default('active');

            /*
            |--------------------------------------------------------------------------
            | Dates
            |--------------------------------------------------------------------------
            */

            $table->timestampTz('issued_at');
            $table->timestampTz('expires_at');

            $table->timestampTz('fully_redeemed_at')->nullable();
            $table->timestampTz('cancelled_at')->nullable();

            $table->timestamps();

            $table->index(
                ['status', 'expires_at'],
                'gift_cards_status_expiry_index'
            );

            $table->index(
                'remaining_balance',
                'gift_cards_remaining_balance_index'
            );
        });

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_cards
            ADD CONSTRAINT gift_cards_initial_balance_check
            CHECK (initial_balance > 0)
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_cards
            ADD CONSTRAINT gift_cards_remaining_balance_check
            CHECK (
                remaining_balance >= 0
                AND remaining_balance <= initial_balance
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_cards
            ADD CONSTRAINT gift_cards_status_check
            CHECK (
                status IN (
                    'active',
                    'fully_redeemed',
                    'expired',
                    'cancelled'
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_cards
            ADD CONSTRAINT gift_cards_expiry_check
            CHECK (expires_at > issued_at)
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_cards
            ADD CONSTRAINT gift_cards_active_state_check
            CHECK (
                status <> 'active'
                OR (
                    remaining_balance > 0
                    AND fully_redeemed_at IS NULL
                    AND cancelled_at IS NULL
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_cards
            ADD CONSTRAINT gift_cards_redeemed_state_check
            CHECK (
                (
                    status = 'fully_redeemed'
                    AND remaining_balance = 0
                    AND fully_redeemed_at IS NOT NULL
                    AND cancelled_at IS NULL
                )
                OR
                (
                    status <> 'fully_redeemed'
                    AND fully_redeemed_at IS NULL
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_cards
            ADD CONSTRAINT gift_cards_cancelled_state_check
            CHECK (
                (
                    status = 'cancelled'
                    AND cancelled_at IS NOT NULL
                    AND fully_redeemed_at IS NULL
                )
                OR
                (
                    status <> 'cancelled'
                    AND cancelled_at IS NULL
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_cards
            ADD CONSTRAINT gift_cards_expired_state_check
            CHECK (
                status <> 'expired'
                OR (
                    fully_redeemed_at IS NULL
                    AND cancelled_at IS NULL
                )
            )
            SQL
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('gift_cards');
    }
};
