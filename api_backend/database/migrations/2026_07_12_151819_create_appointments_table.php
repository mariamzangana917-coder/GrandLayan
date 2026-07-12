<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('appointments', function (Blueprint $table) {
            $table->id();

            $table->string('reference', 30)->unique();

            $table->foreignId('customer_id')
                ->constrained('users')
                ->restrictOnDelete();

            $table->foreignId('department_id')
                ->constrained()
                ->restrictOnDelete();

            $table->string('status', 30)
                ->default('pending')
                ->index();

            /*
             * الوقت الذي اختارته الزبونة عند إرسال الطلب.
             */
            $table->timestampTz('requested_start_at')->index();

            /*
             * الوقت النهائي بعد اعتماد الموعد من المديرة.
             */
            $table->timestampTz('confirmed_start_at')
                ->nullable()
                ->index();

            $table->text('customer_notes')->nullable();
            $table->text('admin_notes')->nullable();

            $table->string('cancelled_by', 20)->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->timestampTz('cancelled_at')->nullable();

            $table->timestampTz('completed_at')->nullable();
            $table->timestampTz('no_show_at')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->index([
                'customer_id',
                'status',
                'requested_start_at',
            ]);

            $table->index([
                'department_id',
                'status',
                'requested_start_at',
            ]);
        });

        DB::statement(
            "ALTER TABLE appointments
             ADD CONSTRAINT appointments_status_check
             CHECK (
                 status IN (
                     'pending',
                     'confirmed',
                     'in_progress',
                     'completed',
                     'cancelled',
                     'no_show'
                 )
             )"
        );

        DB::statement(
            "ALTER TABLE appointments
             ADD CONSTRAINT appointments_cancelled_by_check
             CHECK (
                 cancelled_by IS NULL
                 OR cancelled_by IN (
                     'customer',
                     'manager',
                     'system'
                 )
             )"
        );
    }

    public function down(): void
    {
        Schema::dropIfExists('appointments');
    }
};