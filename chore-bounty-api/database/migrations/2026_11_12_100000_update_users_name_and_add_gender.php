<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('first_name', 100)->nullable()->after('id');
            $table->string('middle_name', 100)->nullable()->after('first_name');
            $table->string('last_name', 100)->nullable()->after('middle_name');
            $table->string('gender', 32)->nullable()->after('last_name');
        });

        if (Schema::hasColumn('users', 'name')) {
            DB::table('users')->orderBy('id')->chunkById(100, function ($users) {
                foreach ($users as $user) {
                    $trimmed = trim(preg_replace('/\s+/', ' ', (string) ($user->name ?? '')));
                    $parts = $trimmed === '' ? [] : explode(' ', $trimmed);

                    $firstName = $parts[0] ?? '';
                    $middleName = null;
                    $lastName = '';

                    if (count($parts) === 2) {
                        $lastName = $parts[1];
                    } elseif (count($parts) >= 3) {
                        $firstName = array_shift($parts);
                        $lastName = array_pop($parts);
                        $middleName = implode(' ', $parts);
                    }

                    DB::table('users')
                        ->where('id', $user->id)
                        ->update([
                            'first_name' => $firstName,
                            'middle_name' => $middleName,
                            'last_name' => $lastName,
                        ]);
                }
            });

            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('name');
            });
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'name')) {
                $table->string('name')->nullable()->after('id');
            }
        });

        DB::table('users')->orderBy('id')->chunkById(100, function ($users) {
            foreach ($users as $user) {
                $fullName = trim(implode(' ', array_filter([
                    $user->first_name ?? null,
                    $user->middle_name ?? null,
                    $user->last_name ?? null,
                ], fn ($part) => is_string($part) && trim($part) !== '')));

                DB::table('users')
                    ->where('id', $user->id)
                    ->update(['name' => $fullName]);
            }
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['first_name', 'middle_name', 'last_name', 'gender']);
        });
    }
};

