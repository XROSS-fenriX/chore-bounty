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
        Schema::create('bounty_claims', function (Blueprint $table) {
            $table->id();

            $table->foreignId('bounty_id')
                ->constrained('bounties')
                ->restrictOnDelete();

            $table->foreignId('user_id')
                ->constrained('users')
                ->restrictOnDelete();

            $table->string('status', 20)->default('active');
            $table->timestamp('claimed_at')->useCurrent();
            $table->timestamp('released_at')->nullable();

            $table->timestamps();

            $table->index(['bounty_id', 'status']);
            $table->index(['user_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bounty_claims');
    }
};
