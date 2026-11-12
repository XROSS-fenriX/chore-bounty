<?php

namespace Database\Seeders;

use App\Models\Bounty;
use App\Models\Household;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $sarah = User::firstOrCreate(
            ['email' => 'sarah@example.com'],
            [
                'first_name' => 'Sarah',
                'last_name' => 'Connor',
                'gender' => 'female',
                'password' => Hash::make('password'),
            ]
        );

        $alex = User::firstOrCreate(
            ['email' => 'alex@example.com'],
            [
                'first_name' => 'Alex',
                'last_name' => 'Mercer',
                'gender' => 'male',
                'password' => Hash::make('password'),
            ]
        );

        $liam = User::firstOrCreate(
            ['email' => 'liam@example.com'],
            [
                'first_name' => 'Liam',
                'last_name' => 'Vance',
                'gender' => 'male',
                'password' => Hash::make('password'),
            ]
        );

        $household = Household::firstOrCreate(
            ['invite_code' => 'GUILD4B'],
            [
                'name' => 'Apt 4B - Guild Hall',
                'created_by' => $sarah->id,
            ]
        );

        $household->members()->syncWithoutDetaching([
            $sarah->id => ['role' => 'admin'],
            $alex->id => ['role' => 'member'],
            $liam->id => ['role' => 'member'],
        ]);

        // Seed Sample RPG Bounties
        if ($household->bounties()->count() === 0) {
            Bounty::create([
                'household_id' => $household->id,
                'created_by' => $sarah->id,
                'title' => 'Defeat Mount Dishmore',
                'description' => 'Unload clean dishes, load dirty pots, and wipe down the marble counter.',
                'difficulty' => 'epic',
                'xp_reward' => 250,
                'reward_value' => 15.00,
                'reward_description' => '1 Venti Oat Latte + Pastry from Starbucks',
                'status' => 'open',
                'due_at' => now()->addDays(2),
            ]);

            Bounty::create([
                'household_id' => $household->id,
                'created_by' => $sarah->id,
                'assignee_id' => $alex->id,
                'title' => 'Vanquish the Hallway Dust Bunnies',
                'description' => 'Vacuum the shared corridor and mop entryway tiles.',
                'difficulty' => 'medium',
                'xp_reward' => 100,
                'reward_value' => 10.00,
                'reward_description' => 'Chore Bounty $10 Credit',
                'status' => 'claimed',
                'claimed_at' => now()->subHours(3),
                'due_at' => now()->addDay(),
            ]);

            Bounty::create([
                'household_id' => $household->id,
                'created_by' => $alex->id,
                'assignee_id' => $liam->id,
                'title' => 'Restock Sacred Espresso Beans & Oat Milk',
                'description' => 'Walk over to the corner grocer and pick up fresh roast beans and 2 cartons of oat milk.',
                'difficulty' => 'easy',
                'xp_reward' => 60,
                'reward_value' => 8.00,
                'reward_description' => 'Free slice of NY style pizza tonight',
                'status' => 'completed',
                'claimed_at' => now()->subDays(2),
                'submitted_at' => now()->subDays(1),
                'completed_at' => now()->subHours(12),
                'submission_proof' => 'Beans and milk placed in the fridge & pantry!',
            ]);
        }
    }
}
