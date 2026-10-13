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
        Schema::create('bounties', function (Blueprint $table) {
            $table->id();

            $table->foreignId('household_id')
                ->constrained('households')
                ->restrictOnDelete();

            $table->foreignId('created_by')
                ->constrained('users')
                ->restrictOnDelete();

            $table->string('title', 150);
            $table->text('description')->nullable();
            $table->string('difficulty', 20)->default('easy');
            $table->decimal('reward_value', 10, 2)->nullable();
            $table->string('reward_description', 255);
            $table->string('status', 30)->default('open');
            $table->timestamp('due_at')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->index(['household_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bounties');
    }
};
