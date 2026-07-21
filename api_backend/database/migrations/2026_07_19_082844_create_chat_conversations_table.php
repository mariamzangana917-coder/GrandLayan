<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_conversations', function (Blueprint $table): void {
            $table->id();

            $table->foreignId('customer_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('title', 150)
                ->nullable();

            $table->timestamp('last_message_at')
                ->nullable();

            $table->timestamps();

            $table->index([
                'customer_id',
                'last_message_at',
            ]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_conversations');
    }
};