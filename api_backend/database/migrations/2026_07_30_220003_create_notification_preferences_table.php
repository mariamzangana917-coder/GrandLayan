<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_preferences', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->boolean('push_enabled')->default(true);
            $table->boolean('appointment_updates')->default(true);
            $table->boolean('appointment_reminders')->default(true);
            $table->boolean('chat_messages')->default(true);
            $table->boolean('offers')->default(true);
            $table->boolean('gift_cards')->default(true);
            $table->boolean('payments')->default(true);
            $table->boolean('reviews')->default(true);
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_preferences');
    }
};
