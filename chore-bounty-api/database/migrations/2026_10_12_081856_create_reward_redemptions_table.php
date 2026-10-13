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
        Schema::create('reward_redemptions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('bounty_completion_id')
                ->unique()
                ->constrained('bounty_completions')
                ->restrictOnDelete();

            $table->foreignId('redeemed_by')
                ->constrained('users')
                ->restrictOnDelete();

            $table->string('status', 20)->default('unredeemed');
            $table->timestamp('redeemed_at')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reward_redemptions');
    }
};
