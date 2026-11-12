<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bounties', function (Blueprint $table) {
            if (! Schema::hasColumn('bounties', 'category')) {
                $table->string('category', 50)->nullable()->after('difficulty');
            }
        });
    }

    public function down(): void
    {
        Schema::table('bounties', function (Blueprint $table) {
            if (Schema::hasColumn('bounties', 'category')) {
                $table->dropColumn('category');
            }
        });
    }
};

