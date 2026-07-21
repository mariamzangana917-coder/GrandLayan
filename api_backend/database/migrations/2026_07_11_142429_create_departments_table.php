<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('departments', function (Blueprint $table) {
            $table->id();

            /*
             * Stable internal identifier used by business logic.
             * Official values: salon, clinic.
             */
            $table->string('code', 30)->unique();

            /*
             * Display name shown in the applications.
             */
            $table->string('name', 100);

            /*
             * A department is disabled instead of being deleted,
             * preserving historical bookings and financial records.
             */
            $table->boolean('is_active')->default(true)->index();

            $table->unsignedSmallInteger('sort_order')->default(0);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('departments');
    }
};
