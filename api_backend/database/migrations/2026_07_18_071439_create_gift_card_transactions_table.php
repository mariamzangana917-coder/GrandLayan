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
        Schema::create('gift_card_transactions', function (Blueprint $table): void {
            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Gift card
            |--------------------------------------------------------------------------
            */

            $table->foreignId('gift_card_id')
                ->constrained('gift_cards')
                ->restrictOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Related appointment
            |--------------------------------------------------------------------------
            |
            | يكون موجودًا عند استخدام البطاقة لدفع حجز،
            | أو عند إعادة مبلغ حجز ملغي إلى البطاقة.
            |
            */

            $table->foreignId('appointment_id')
                ->nullable()
                ->constrained('appointments')
                ->restrictOnDelete();

            /*
            |--------------------------------------------------------------------------
            | User who performed the transaction
            |--------------------------------------------------------------------------
            |
            | يكون null في العمليات التلقائية التي ينفذها النظام،
            | مثل إصدار البطاقة بعد نجاح الدفع.
            |
            */

            $table->foreignId('performed_by_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Transaction type
            |--------------------------------------------------------------------------
            |
            | issuance:
            | إصدار البطاقة وإضافة الرصيد الأول.
            |
            | redemption:
            | استخدام البطاقة وخصم مبلغ منها.
            |
            | refund:
            | إعادة مبلغ حجز ملغي إلى البطاقة.
            |
            | adjustment_credit:
            | إضافة رصيد يدويًا بواسطة المديرة.
            |
            | adjustment_debit:
            | خصم رصيد يدويًا بواسطة المديرة.
            |
            | cancellation:
            | تصفير الرصيد المتبقي عند إلغاء البطاقة.
            |
            */

            $table->string('type', 30);

            $table->decimal('amount', 12, 2);
            $table->decimal('balance_before', 12, 2);
            $table->decimal('balance_after', 12, 2);

            /*
            |--------------------------------------------------------------------------
            | Administrative details
            |--------------------------------------------------------------------------
            */

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(
                ['gift_card_id', 'created_at'],
                'gift_card_transactions_card_created_index'
            );

            $table->index(
                ['appointment_id', 'type'],
                'gift_card_transactions_appointment_type_index'
            );

            $table->index(
                ['performed_by_user_id', 'created_at'],
                'gift_card_transactions_user_created_index'
            );
        });

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_transactions
            ADD CONSTRAINT gift_card_transactions_type_check
            CHECK (
                type IN (
                    'issuance',
                    'redemption',
                    'refund',
                    'adjustment_credit',
                    'adjustment_debit',
                    'cancellation'
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_transactions
            ADD CONSTRAINT gift_card_transactions_amount_check
            CHECK (amount > 0)
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_transactions
            ADD CONSTRAINT gift_card_transactions_balances_check
            CHECK (
                balance_before >= 0
                AND balance_after >= 0
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_transactions
            ADD CONSTRAINT gift_card_transactions_balance_math_check
            CHECK (
                (
                    type IN (
                        'issuance',
                        'refund',
                        'adjustment_credit'
                    )
                    AND balance_after = balance_before + amount
                )
                OR
                (
                    type IN (
                        'redemption',
                        'adjustment_debit',
                        'cancellation'
                    )
                    AND balance_after = balance_before - amount
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_transactions
            ADD CONSTRAINT gift_card_transactions_appointment_check
            CHECK (
                (
                    type IN ('redemption', 'refund')
                    AND appointment_id IS NOT NULL
                )
                OR
                (
                    type NOT IN ('redemption', 'refund')
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_transactions
            ADD CONSTRAINT gift_card_transactions_issuance_check
            CHECK (
                type <> 'issuance'
                OR (
                    balance_before = 0
                    AND appointment_id IS NULL
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_transactions
            ADD CONSTRAINT gift_card_transactions_cancellation_check
            CHECK (
                type <> 'cancellation'
                OR (
                    balance_after = 0
                    AND amount = balance_before
                    AND appointment_id IS NULL
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_transactions
            ADD CONSTRAINT gift_card_transactions_adjustment_check
            CHECK (
                type NOT IN ('adjustment_credit', 'adjustment_debit')
                OR performed_by_user_id IS NOT NULL
            )
            SQL
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('gift_card_transactions');
    }
};
