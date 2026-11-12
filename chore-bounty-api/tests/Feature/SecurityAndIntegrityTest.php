<?php

namespace Tests\Feature;

use App\Models\Bounty;
use App\Models\Household;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SecurityAndIntegrityTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_cannot_update_or_view_unrelated_user_profile(): void
    {
        $alice = User::factory()->create(['name' => 'Alice']);
        $bob = User::factory()->create(['name' => 'Bob']);

        Sanctum::actingAs($alice);

        $this->getJson("/api/users/{$bob->id}")->assertStatus(403);
        $this->putJson("/api/users/{$bob->id}", ['name' => 'Hacked'])->assertStatus(403);
        $this->assertSame('Bob', $bob->fresh()->name);

        // Alice can update her own profile with a valid avatar
        $this->putJson("/api/users/{$alice->id}", [
            'name' => 'Alice Updated',
            'avatar' => 'gal_2',
        ])->assertStatus(200)
          ->assertJsonPath('data.name', 'Alice Updated')
          ->assertJsonPath('data.avatar', 'gal_2');
    }

    public function test_user_cannot_manage_members_or_rename_without_owner_role(): void
    {
        $owner = User::factory()->create(['name' => 'Owner']);
        $member = User::factory()->create(['name' => 'Member']);
        $outsider = User::factory()->create(['name' => 'Outsider']);

        $household = Household::create([
            'name' => 'Apt 4A',
            'invite_code' => 'APT4A123',
            'created_by' => $owner->id,
        ]);
        $household->members()->attach($owner->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($member->id, ['role' => 'member', 'joined_at' => now()]);

        // Outsider cannot add themselves or anyone else as owner
        Sanctum::actingAs($outsider);
        $this->postJson("/api/households/{$household->id}/members", [
            'user_id' => $outsider->id,
            'role' => 'owner',
        ])->assertStatus(403);

        // Regular member cannot rename household or kick members
        Sanctum::actingAs($member);
        $this->putJson("/api/households/{$household->id}", ['name' => 'Hijacked'])->assertStatus(403);
        $this->deleteJson("/api/households/{$household->id}/members/{$owner->id}")->assertStatus(403);

        // Owner can rename household
        Sanctum::actingAs($owner);
        $this->putJson("/api/households/{$household->id}", ['name' => 'Renamed Apt'])->assertStatus(200);
    }

    public function test_assignee_cannot_self_complete_bounty_without_creator_approval(): void
    {
        $creator = User::factory()->create();
        $assignee = User::factory()->create();

        $household = Household::create([
            'name' => 'Apt 4B',
            'invite_code' => 'SELFCHK1',
            'created_by' => $creator->id,
        ]);
        $household->members()->attach($creator->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($assignee->id, ['role' => 'member', 'joined_at' => now()]);

        $bounty = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $creator->id,
            'assignee_id' => $assignee->id,
            'title' => 'Help with chores',
            'category' => 'Laundry',
            'difficulty' => 'medium',
            'xp_reward' => 50,
            'reward_value' => 50,
            'reward_description' => '50 Tokens',
            'status' => 'claimed',
        ]);

        // Category is persisted on Bounty
        $this->assertSame('Laundry', $bounty->fresh()->category);

        // Assignee cannot bypass verification via /complete
        Sanctum::actingAs($assignee);
        $this->postJson("/api/bounties/{$bounty->id}/complete")->assertStatus(403);
    }

    public function test_logout_revokes_sanctum_token(): void
    {
        $user = User::factory()->create([
            'email' => 'logout@example.com',
            'password' => Hash::make('secret123'),
        ]);

        $loginRes = $this->postJson('/api/auth/login', [
            'email' => 'logout@example.com',
            'password' => 'secret123',
        ])->assertStatus(200);

        $token = $loginRes->json('token');

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/auth/logout')
            ->assertStatus(200);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_user_registration_and_update_use_structured_name_and_gender_columns(): void
    {
        $this->assertFalse(Schema::hasColumn('users', 'name'));
        $this->assertTrue(Schema::hasColumns('users', ['first_name', 'middle_name', 'last_name', 'gender']));

        $registerRes = $this->postJson('/api/auth/register', [
            'first_name' => 'Leonard',
            'middle_name' => 'Leakey',
            'last_name' => 'Hofstadter',
            'gender' => 'male',
            'email' => 'leonard.structured@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertStatus(201);

        $registerRes->assertJsonPath('user.first_name', 'Leonard')
            ->assertJsonPath('user.middle_name', 'Leakey')
            ->assertJsonPath('user.last_name', 'Hofstadter')
            ->assertJsonPath('user.name', 'Leonard Leakey Hofstadter')
            ->assertJsonPath('user.gender', 'male');

        $userId = $registerRes->json('user.id');
        $user = User::findOrFail($userId);
        Sanctum::actingAs($user);

        $this->putJson("/api/users/{$userId}", [
            'first_name' => 'Penny',
            'middle_name' => null,
            'last_name' => 'Hofstadter',
            'gender' => 'female',
            'avatar' => 'gal_1',
        ])->assertStatus(200)
          ->assertJsonPath('data.first_name', 'Penny')
          ->assertJsonPath('data.middle_name', null)
          ->assertJsonPath('data.last_name', 'Hofstadter')
          ->assertJsonPath('data.name', 'Penny Hofstadter')
          ->assertJsonPath('data.gender', 'female');
    }

    public function test_bounty_submit_reject_and_verify_creates_redemption(): void
    {
        $creator = User::factory()->create();
        $assignee = User::factory()->create();

        $household = Household::create([
            'name' => 'Apt 4C',
            'invite_code' => 'REDEMP12',
            'created_by' => $creator->id,
        ]);
        $household->members()->attach($creator->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($assignee->id, ['role' => 'member', 'joined_at' => now()]);

        $bounty = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $creator->id,
            'title' => 'Scrub stove',
            'category' => 'Kitchen',
            'difficulty' => 'medium',
            'xp_reward' => 60,
            'reward_value' => 60,
            'reward_description' => '60 Tokens',
            'status' => 'open',
        ]);

        // Assignee claims & submits
        Sanctum::actingAs($assignee);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);
        $this->postJson("/api/bounties/{$bounty->id}/submit", [
            'submission_proof' => 'First wipe done',
        ])->assertStatus(200);

        // Creator rejects -> status returns to claimed
        Sanctum::actingAs($creator);
        $this->postJson("/api/bounties/{$bounty->id}/reject", [
            'feedback' => 'Please scrub the back burners too',
        ])->assertStatus(200)
          ->assertJsonPath('data.status', 'claimed');

        // Assignee re-submits -> Creator verifies -> RewardRedemption is automatically created
        Sanctum::actingAs($assignee);
        $this->postJson("/api/bounties/{$bounty->id}/submit", [
            'submission_proof' => 'Back burners cleaned',
        ])->assertStatus(200);

        Sanctum::actingAs($creator);
        $this->postJson("/api/bounties/{$bounty->id}/verify")
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'completed');

        $this->assertDatabaseHas('reward_redemptions', [
            'redeemed_by' => $assignee->id,
            'status' => 'unredeemed',
        ]);
    }
}

