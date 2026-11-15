<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bounties', function (Blueprint $table) {
            $table->json('submission_images')->nullable()->after('submission_proof');
        });

        Schema::table('bounty_completions', function (Blueprint $table) {
            $table->json('proof_images')->nullable()->after('proof_url');
        });
    }

    public function down(): void
    {
        Schema::table('bounties', function (Blueprint $table) {
            $table->dropColumn('submission_images');
        });

        Schema::table('bounty_completions', function (Blueprint $table) {
            $table->dropColumn('proof_images');
        });
    }
};
