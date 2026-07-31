<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_deliveries', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('campaign_id')
                ->nullable()
                ->constrained('notification_campaigns')
                ->nullOnDelete();
            $table->uuid('app_notification_id')->nullable();
            $table->foreign('app_notification_id')
                ->references('id')
                ->on('app_notifications')
                ->cascadeOnDelete();
            $table->foreignId('device_token_id')
                ->nullable()
                ->constrained('device_tokens')
                ->nullOnDelete();
            $table->string('status', 30)->default('pending');
            $table->unsignedSmallInteger('attempt_count')->default(0);
            $table->string('provider_message_id')->nullable();
            $table->string('error_code')->nullable();
            $table->text('error_message')->nullable();
            $table->timestampTz('sent_at')->nullable();
            $table->timestampTz('failed_at')->nullable();
            $table->timestampsTz();

            $table->index(['status', 'created_at']);
            $table->index(['campaign_id', 'status']);
            $table->index(['app_notification_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_deliveries');
    }
};
