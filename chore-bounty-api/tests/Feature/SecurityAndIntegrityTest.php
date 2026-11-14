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

    public function test_notifications_lifecycle_and_edit_delete_when_available_or_taken(): void
    {
        $creator = User::factory()->create(['first_name' => 'Sheldon', 'last_name' => 'Cooper']);
        $roommate = User::factory()->create(['first_name' => 'Leonard', 'last_name' => 'Hofstadter']);

        $household = Household::create([
            'name' => 'Apt 4A',
            'invite_code' => 'NOTIF123',
            'created_by' => $creator->id,
        ]);
        $household->members()->attach($creator->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($roommate->id, ['role' => 'member', 'joined_at' => now()]);

        // 1. Creator posts a bounty -> generates 'posted' notification
        Sanctum::actingAs($creator);
        $postRes = $this->postJson('/api/bounties', [
            'household_id' => $household->id,
            'title' => 'Take out trash',
            'description' => 'All bins to the curb.',
            'category' => 'Cleaning',
            'difficulty' => 'easy',
            'xp_reward' => 40,
            'reward_value' => 40,
            'reward_description' => '40 Tokens',
        ])->assertStatus(201);

        $bountyId = $postRes->json('data.id');

        // Creator can edit when available (open)
        $this->putJson("/api/bounties/{$bountyId}", [
            'title' => 'Take out trash and recycling',
        ])->assertStatus(200)
          ->assertJsonPath('data.title', 'Take out trash and recycling');

        // 2. Roommate claims the bounty -> generates 'claimed' notification
        Sanctum::actingAs($roommate);
        $this->postJson("/api/bounties/{$bountyId}/claim")->assertStatus(200);

        // Creator CAN edit when taken (claimed)
        Sanctum::actingAs($creator);
        $this->putJson("/api/bounties/{$bountyId}", [
            'title' => 'Take out trash, recycling, and compost',
        ])->assertStatus(200)
          ->assertJsonPath('data.title', 'Take out trash, recycling, and compost');

        // 3. Roommate submits the bounty -> generates 'submitted' notification
        Sanctum::actingAs($roommate);
        $this->postJson("/api/bounties/{$bountyId}/submit", [
            'submission_proof' => 'Bins are at the curb.',
        ])->assertStatus(200);

        // Creator CANNOT edit or delete when submitted
        Sanctum::actingAs($creator);
        $this->putJson("/api/bounties/{$bountyId}", ['title' => 'Blocked Edit'])->assertStatus(403);
        $this->deleteJson("/api/bounties/{$bountyId}")->assertStatus(403);

        // 4. Creator approves (awards) the bounty -> generates 'awarded' notification
        $this->postJson("/api/bounties/{$bountyId}/verify")->assertStatus(200);

        // Creator CANNOT edit or delete when completed
        $this->putJson("/api/bounties/{$bountyId}", ['title' => 'Blocked Edit'])->assertStatus(403);
        $this->deleteJson("/api/bounties/{$bountyId}")->assertStatus(403);

        // 5. Creator posts a second bounty, roommate claims it, creator cancels and deletes
        $bounty2 = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $creator->id,
            'assignee_id' => $roommate->id,
            'title' => 'Wash windows',
            'category' => 'Cleaning',
            'difficulty' => 'medium',
            'xp_reward' => 30,
            'reward_value' => 30,
            'reward_description' => '30 Tokens',
            'status' => 'claimed',
        ]);

        // Creator can delete a taken bounty
        $this->deleteJson("/api/bounties/{$bounty2->id}")->assertStatus(204);

        // 6. Creator posts a third bounty and cancels it -> generates 'cancelled' notification
        $bounty3 = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $creator->id,
            'title' => 'Mop balcony',
            'category' => 'Cleaning',
            'difficulty' => 'easy',
            'xp_reward' => 25,
            'reward_value' => 25,
            'reward_description' => '25 Tokens',
            'status' => 'open',
        ]);
        $this->postJson("/api/bounties/{$bounty3->id}/cancel")->assertStatus(200);

        // Cancelled bounty cannot be edited or deleted
        $this->putJson("/api/bounties/{$bounty3->id}", ['title' => 'No edit'])->assertStatus(403);
        $this->deleteJson("/api/bounties/{$bounty3->id}")->assertStatus(403);

        // 7. Verify notifications endpoint returns only events triggered by other users
        Sanctum::actingAs($roommate);
        $notifRes = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200);

        $events = collect($notifRes->json('data'))->pluck('event_type')->all();
        $this->assertContains('posted', $events);
        $this->assertContains('awarded', $events);
        $this->assertContains('cancelled', $events);
        $this->assertNotContains('claimed', $events);
        $this->assertNotContains('submitted', $events);
        $this->assertSame(3, $notifRes->json('meta.unread_count'));

        // Creator sees events triggered by roommate (claimed, submitted), but not own events (posted, awarded, cancelled)
        Sanctum::actingAs($creator);
        $creatorNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200);
        $creatorEvents = collect($creatorNotifs->json('data'))->pluck('event_type')->all();
        $this->assertContains('claimed', $creatorEvents);
        $this->assertContains('submitted', $creatorEvents);
        $this->assertNotContains('posted', $creatorEvents);
        $this->assertNotContains('awarded', $creatorEvents);
        $this->assertNotContains('cancelled', $creatorEvents);
        $this->assertSame(2, $creatorNotifs->json('meta.unread_count'));

        // Mark single notification as read
        Sanctum::actingAs($roommate);
        $firstNotifId = $notifRes->json('data.0.id');
        $this->postJson("/api/notifications/{$firstNotifId}/read")
            ->assertStatus(200)
            ->assertJsonPath('data.is_read', true);

        // Mark all notifications as read
        $this->postJson('/api/notifications/read-all', [
            'household_id' => $household->id,
        ])->assertStatus(200)
          ->assertJsonPath('meta.unread_count', 0);
    }
}

