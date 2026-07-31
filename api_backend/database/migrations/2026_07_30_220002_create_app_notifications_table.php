<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_notifications', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 80);
            $table->string('title', 160);
            $table->text('body');
            $table->json('data')->nullable();
            $table->string('deduplication_key', 191)->nullable();
            $table->timestampTz('read_at')->nullable();
            $table->timestampsTz();

            $table->unique(
                ['user_id', 'deduplication_key'],
                'app_notifications_user_dedup_unique',
            );
            $table->index(
                ['user_id', 'read_at', 'created_at'],
                'app_notifications_user_read_created_idx',
            );
            $table->index(['type', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_notifications');
    }
};
