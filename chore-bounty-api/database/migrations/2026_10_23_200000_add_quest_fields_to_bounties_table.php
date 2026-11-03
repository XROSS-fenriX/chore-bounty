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
        Schema::table('bounties', function (Blueprint $table) {
            $table->foreignId('assignee_id')
                ->nullable()
                ->after('created_by')
                ->constrained('users')
                ->nullOnDelete();

            $table->unsignedInteger('xp_reward')
                ->default(50)
                ->after('difficulty');

            $table->text('submission_proof')
                ->nullable()
                ->after('status');

            $table->timestamp('claimed_at')->nullable()->after('submission_proof');
            $table->timestamp('submitted_at')->nullable()->after('claimed_at');
            $table->timestamp('completed_at')->nullable()->after('submitted_at');

            $table->index(['assignee_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bounties', function (Blueprint $table) {
            $table->dropIndex(['assignee_id', 'status']);
            $table->dropForeign(['assignee_id']);
            $table->dropColumn([
                'assignee_id',
                'xp_reward',
                'submission_proof',
                'claimed_at',
                'submitted_at',
                'completed_at',
            ]);
        });
    }
};
