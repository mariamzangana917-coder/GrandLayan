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
        Schema::create('gift_card_orders', function (Blueprint $table): void {
            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Buyer and selected design
            |--------------------------------------------------------------------------
            */

            $table->foreignId('customer_id')
                ->constrained('users')
                ->restrictOnDelete();

            $table->foreignId('gift_card_design_id')
                ->constrained('gift_card_designs')
                ->restrictOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Recipient information
            |--------------------------------------------------------------------------
            */

            $table->string('recipient_name', 120);
            $table->string('recipient_phone', 30)->nullable();
            $table->text('gift_message')->nullable();

            /*
            |--------------------------------------------------------------------------
            | Financial snapshot
            |--------------------------------------------------------------------------
            |
            | نخزن قيمة البطاقة داخل الطلب حتى تبقى قيمة الشراء الأصلية
            | محفوظة، حتى لو عدلت المديرة قيمة التصميم مستقبلًا.
            |
            */

            $table->decimal('amount', 12, 2);

            /*
            |--------------------------------------------------------------------------
            | Payment information
            |--------------------------------------------------------------------------
            |
            | payment_method:
            | cash       = دفع داخل المركز
            | electronic = دفع إلكتروني
            |
            | payment_status:
            | pending  = بانتظار الدفع
            | paid     = مدفوع
            | failed   = فشل الدفع
            | refunded = تم إرجاع المبلغ
            |
            */

            $table->string('payment_method', 20);
            $table->string('payment_status', 20)->default('pending');

            /*
            |--------------------------------------------------------------------------
            | Payment reference
            |--------------------------------------------------------------------------
            |
            | مرجع عملية بوابة الدفع عند استخدام الدفع الإلكتروني.
            | يكون nullable للدفع النقدي والطلبات التي لم تُدفع بعد.
            |
            */

            $table->string('payment_reference', 150)
                ->nullable()
                ->unique();

            /*
            |--------------------------------------------------------------------------
            | Order status
            |--------------------------------------------------------------------------
            |
            | pending   = الطلب بانتظار إكمال الدفع
            | completed = تم الدفع وإصدار البطاقة
            | cancelled = تم إلغاء الطلب قبل الإصدار
            | refunded  = تم إرجاع قيمة الطلب
            |
            */

            $table->string('status', 20)->default('pending');

            /*
            |--------------------------------------------------------------------------
            | Important dates
            |--------------------------------------------------------------------------
            */

            $table->timestampTz('paid_at')->nullable();
            $table->timestampTz('completed_at')->nullable();
            $table->timestampTz('cancelled_at')->nullable();
            $table->timestampTz('refunded_at')->nullable();

            $table->timestamps();

            $table->index(
                ['customer_id', 'created_at'],
                'gift_card_orders_customer_created_index'
            );

            $table->index(
                ['payment_status', 'status'],
                'gift_card_orders_payment_status_index'
            );

            $table->index(
                'recipient_phone',
                'gift_card_orders_recipient_phone_index'
            );

            $table->index(
                'gift_card_design_id',
                'gift_card_orders_design_index'
            );
        });

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_orders
            ADD CONSTRAINT gift_card_orders_amount_check
            CHECK (amount > 0)
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_orders
            ADD CONSTRAINT gift_card_orders_payment_method_check
            CHECK (
                payment_method IN (
                    'cash',
                    'electronic'
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_orders
            ADD CONSTRAINT gift_card_orders_payment_status_check
            CHECK (
                payment_status IN (
                    'pending',
                    'paid',
                    'failed',
                    'refunded'
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_orders
            ADD CONSTRAINT gift_card_orders_status_check
            CHECK (
                status IN (
                    'pending',
                    'completed',
                    'cancelled',
                    'refunded'
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_orders
            ADD CONSTRAINT gift_card_orders_paid_state_check
            CHECK (
                (
                    payment_status IN ('paid', 'refunded')
                    AND paid_at IS NOT NULL
                )
                OR
                (
                    payment_status NOT IN ('paid', 'refunded')
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_orders
            ADD CONSTRAINT gift_card_orders_completed_state_check
            CHECK (
                (
                    status = 'completed'
                    AND payment_status = 'paid'
                    AND completed_at IS NOT NULL
                    AND cancelled_at IS NULL
                    AND refunded_at IS NULL
                )
                OR
                (
                    status <> 'completed'
                    AND completed_at IS NULL
                )
            )
            SQL
        );

        DB::statement(
            <<<'SQL'
            ALTER TABLE gift_card_orders
            ADD CONSTRAINT gift_card_orders_cancelled_state_check
            CHECK (
                (
                    status = 'cancelled'
                    AND cancelled_at IS NOT NULL
                    AND completed_at IS NULL
                    AND refunded_at IS NULL
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
            ALTER TABLE gift_card_orders
            ADD CONSTRAINT gift_card_orders_refunded_state_check
            CHECK (
                (
                    status = 'refunded'
                    AND payment_status = 'refunded'
                    AND paid_at IS NOT NULL
                    AND refunded_at IS NOT NULL
                    AND cancelled_at IS NULL
                )
                OR
                (
                    status <> 'refunded'
                    AND refunded_at IS NULL
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
        Schema::dropIfExists('gift_card_orders');
    }
};
