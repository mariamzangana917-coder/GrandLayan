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
        Schema::create('posts', function (Blueprint $table) {
            $table->id();

            /*
             * Department code.
             *
             * Official values are managed by the departments table:
             * salon, clinic.
             *
             * We keep the code directly on the post because the
             * application already works with department codes.
             */
            $table->string('department', 30);

            /*
             * Relative path of the uploaded post image.
             */
            $table->string('image_path', 500);
            

            /*
             * Disabled posts remain in the database and are simply
             * excluded from customer-facing results.
             */
$table->string('description', 500)->nullable();

            $table->boolean('is_active')
                ->default(true)
                ->index();

            /*
             * Manager who created the post.
             */
            $table->foreignId('created_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->timestamps();

            /*
             * Keep department values consistent with the departments table.
             */
            $table->foreign('department')
                ->references('code')
                ->on('departments')
                ->restrictOnUpdate()
                ->restrictOnDelete();

            /*
             * Optimizes customer queries such as:
             * active salon posts / active clinic posts ordered by newest.
             */
            $table->index(
                ['department', 'is_active', 'created_at'],
                'posts_department_active_created_at_index'
            );
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};