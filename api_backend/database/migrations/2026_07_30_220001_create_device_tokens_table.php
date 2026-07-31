<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('device_tokens', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('app', 20);
            $table->string('platform', 20);
            $table->string('token', 2048)->unique();
            $table->string('device_id')->nullable();
            $table->string('device_name')->nullable();
            $table->string('locale', 16)->default('ar');
            $table->string('timezone', 64)->nullable();
            $table->boolean('notifications_enabled')->default(true);
            $table->boolean('is_active')->default(true);
            $table->timestampTz('last_seen_at')->nullable();
            $table->timestampsTz();

            $table->index(
                ['user_id', 'app', 'is_active'],
                'device_tokens_user_app_active_idx',
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_tokens');
    }
};
