<?php

namespace Tests\Feature;

use App\Models\Bounty;
use App\Models\Household;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BountyLifecycleTest extends TestCase
{
    use RefreshDatabase;

    public function test_complete_bounty_lifecycle_and_leaderboard(): void
    {
        // 1. Setup two roommates in the same household
        $roommate1 = User::factory()->create(['name' => 'Sarah Connor', 'email' => 'sarah@example.com']);
        $roommate2 = User::factory()->create(['name' => 'John Connor', 'email' => 'john@example.com']);

        $household = Household::create([
            'name' => 'Apt 4B',
            'invite_code' => 'APT4B123',
            'created_by' => $roommate1->id,
        ]);

        $household->members()->attach($roommate1->id, ['role' => 'admin']);
        $household->members()->attach($roommate2->id, ['role' => 'member']);

        // 2. Roommate 1 posts a bounty
        Sanctum::actingAs($roommate1);

        $response = $this->postJson('/api/bounties', [
            'household_id' => $household->id,
            'title' => 'Vanquish the Mount Dishmore',
            'description' => 'Load and run the dishwasher, wipe down counter.',
            'difficulty' => 'medium',
            'reward_value' => 100.00,
            'reward_description' => '1 Free Iced Caramel Macchiato',
            'xp_reward' => 100,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.title', 'Vanquish the Mount Dishmore')
            ->assertJsonPath('data.status', 'open');

        $bountyId = $response->json('data.id');
        $bounty = Bounty::findOrFail($bountyId);

        // Verify creator cannot claim their own bounty (Policy check)
        $claimFail = $this->postJson("/api/bounties/{$bounty->id}/claim");
        $claimFail->assertStatus(403);

        // 3. Roommate 2 claims the bounty
        Sanctum::actingAs($roommate2);

        $claimResponse = $this->postJson("/api/bounties/{$bounty->id}/claim");
        $claimResponse->assertStatus(200)
            ->assertJsonPath('data.status', 'claimed')
            ->assertJsonPath('data.assignee.name', 'John Connor');

        // 4. Roommate 2 submits completion proof
        $submitResponse = $this->postJson("/api/bounties/{$bounty->id}/submit", [
            'submission_proof' => 'All dishes washed and drying rack cleaned!',
        ]);

        $submitResponse->assertStatus(200)
            ->assertJsonPath('data.status', 'submitted');

        // 5. Roommate 1 verifies and approves the bounty
        Sanctum::actingAs($roommate1);

        $verifyResponse = $this->postJson("/api/bounties/{$bounty->id}/verify");
        $verifyResponse->assertStatus(200)
            ->assertJsonPath('data.status', 'completed');

        // 6. Check leaderboard to verify John Connor is #1
        $leaderboardResponse = $this->getJson("/api/households/{$household->id}/leaderboard");

        $leaderboardResponse->assertStatus(200)
            ->assertJsonPath('data.0.name', 'John Connor')
            ->assertJsonPath('data.0.completed_bounties_count', 1)
            ->assertJsonPath('data.0.total_tokens', 100)
            ->assertJsonPath('data.0.total_xp', 100);
    }
}
