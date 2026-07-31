<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_campaigns', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('created_by_user_id')
                ->constrained('users')
                ->cascadeOnDelete();
            $table->string('title', 160);
            $table->text('body');
            $table->string('audience', 40);
            $table->json('audience_filters')->nullable();
            $table->string('target_type', 80)->nullable();
            $table->unsignedBigInteger('target_id')->nullable();
            $table->string('route', 180)->nullable();
            $table->string('status', 30)->default('draft');
            $table->timestampTz('scheduled_at')->nullable();
            $table->timestampTz('started_at')->nullable();
            $table->timestampTz('completed_at')->nullable();
            $table->timestampTz('cancelled_at')->nullable();
            $table->unsignedInteger('total_recipients')->default(0);
            $table->unsignedInteger('sent_count')->default(0);
            $table->unsignedInteger('failed_count')->default(0);
            $table->timestampsTz();

            $table->index(['status', 'scheduled_at']);
            $table->index(['created_by_user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_campaigns');
    }
};
