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
        Schema::create('bounty_completions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('bounty_claim_id')
                ->constrained('bounty_claims')
                ->restrictOnDelete();

            $table->foreignId('reviewed_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->text('submission_note')->nullable();
            $table->string('proof_url', 2048)->nullable();
            $table->string('status', 20)->default('pending');
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('reviewed_at')->nullable();

            $table->timestamps();

            $table->index(['status', 'submitted_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bounty_completions');
    }
};
