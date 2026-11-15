<?php

namespace Tests\Feature;

use App\Models\Bounty;
use App\Models\BountyClaim;
use App\Models\BountyNotification;
use App\Models\Household;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
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
        $observer = User::factory()->create(['first_name' => 'Penny', 'last_name' => 'Teller']);

        $household = Household::create([
            'name' => 'Apt 4A',
            'invite_code' => 'NOTIF123',
            'created_by' => $creator->id,
        ]);
        $household->members()->attach($creator->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($roommate->id, ['role' => 'member', 'joined_at' => now()]);
        $household->members()->attach($observer->id, ['role' => 'member', 'joined_at' => now()]);

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

        // 4. Creator approves the bounty -> assignee receives 'approved', observer receives 'awarded'
        $this->postJson("/api/bounties/{$bountyId}/verify")->assertStatus(200);

        // Creator CANNOT edit or delete when completed
        $this->putJson("/api/bounties/{$bountyId}", ['title' => 'Blocked Edit'])->assertStatus(403);
        $this->deleteJson("/api/bounties/{$bountyId}")->assertStatus(403);

        // 5. Creator posts a second bounty, roommate claims it; taken chore cannot be deleted directly, must cancel first
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

        $this->deleteJson("/api/bounties/{$bounty2->id}")->assertStatus(403);
        $this->postJson("/api/bounties/{$bounty2->id}/cancel")->assertStatus(200);
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

        // Cancelled bounty cannot be edited, but CAN be deleted
        $this->putJson("/api/bounties/{$bounty3->id}", ['title' => 'No edit'])->assertStatus(403);
        $this->deleteJson("/api/bounties/{$bounty3->id}")->assertStatus(204);

        // 7. Assignee sees 'posted', 'approved', and 'cancelled', but NOT 'awarded' or own 'claimed'/'submitted'
        Sanctum::actingAs($roommate);
        $notifRes = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200);

        $events = collect($notifRes->json('data'))->pluck('event_type')->all();
        $this->assertContains('posted', $events);
        $this->assertContains('approved', $events);
        $this->assertContains('cancelled', $events);
        $this->assertNotContains('awarded', $events);
        $this->assertNotContains('claimed', $events);
        $this->assertNotContains('submitted', $events);
        $this->assertSame(4, $notifRes->json('meta.unread_count'));

        // Observer sees 'awarded', NOT 'approved' and NOT 'submitted' (creator-only)
        Sanctum::actingAs($observer);
        $observerNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200);
        $observerEvents = collect($observerNotifs->json('data'))->pluck('event_type')->all();
        $this->assertContains('awarded', $observerEvents);
        $this->assertNotContains('approved', $observerEvents);
        $this->assertNotContains('submitted', $observerEvents);

        // Verify only the chore poster received a 'submitted' DB notification
        $submittedRecipients = BountyNotification::query()
            ->where('bounty_id', $bountyId)
            ->where('event_type', 'submitted')
            ->pluck('user_id')
            ->all();
        $this->assertSame([$creator->id], $submittedRecipients);

        // Even if a legacy 'submitted' row exists for a non-creator, /api/notifications hides it
        BountyNotification::create([
            'household_id' => $household->id,
            'bounty_id' => $bountyId,
            'user_id' => $observer->id,
            'actor_id' => $roommate->id,
            'event_type' => 'submitted',
            'event_name' => 'Chore Submitted',
            'description' => "{$roommate->name} submitted chore for approval.",
            'category' => 'Cleaning',
            'is_read' => false,
        ]);
        Sanctum::actingAs($observer);
        $legacyCheckEvents = collect(
            $this->getJson("/api/notifications?household_id={$household->id}")
                ->assertStatus(200)
                ->json('data')
        )->pluck('event_type')->all();
        $this->assertNotContains('submitted', $legacyCheckEvents);

        // Creator sees events triggered by roommate (claimed, submitted), but not own events (posted, awarded, cancelled)
        Sanctum::actingAs($creator);
        $creatorNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200);
        $creatorEvents = collect($creatorNotifs->json('data'))->pluck('event_type')->all();
        $this->assertContains('claimed', $creatorEvents);
        $this->assertContains('submitted', $creatorEvents);
        $this->assertNotContains('posted', $creatorEvents);
        $this->assertNotContains('approved', $creatorEvents);
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

    public function test_notifications_cross_household_authorization_and_boundaries(): void
    {
        $alice = User::factory()->create(['name' => 'Alice']);
        $bob = User::factory()->create(['name' => 'Bob']);

        $h1 = Household::create([
            'name' => 'House One',
            'invite_code' => 'HOUSE001',
            'created_by' => $alice->id,
        ]);
        $h1->members()->attach($alice->id, ['role' => 'owner', 'joined_at' => now()]);

        $h2 = Household::create([
            'name' => 'House Two',
            'invite_code' => 'HOUSE002',
            'created_by' => $bob->id,
        ]);
        $h2->members()->attach($bob->id, ['role' => 'owner', 'joined_at' => now()]);

        $bobNotif = BountyNotification::create([
            'household_id' => $h2->id,
            'user_id' => $bob->id,
            'actor_id' => $alice->id,
            'event_type' => 'posted',
            'event_name' => 'Chore Posted',
            'description' => 'Secret household chore',
            'category' => 'Cleaning',
            'is_read' => false,
        ]);

        Sanctum::actingAs($alice);

        $this->getJson("/api/notifications?household_id={$h2->id}")->assertStatus(403);
        $this->withHeaders(['X-Household-Id' => (string) $h2->id])
            ->getJson('/api/notifications')
            ->assertStatus(403);

        $this->postJson('/api/notifications/read-all', ['household_id' => $h2->id])
            ->assertStatus(403);

        $this->postJson("/api/notifications/{$bobNotif->id}/read")
            ->assertStatus(403);
        $this->assertFalse((bool) $bobNotif->fresh()->is_read);
    }

    public function test_household_departure_hides_non_completed_chores_and_revokes_mutations_until_rejoin(): void
    {
        $alice = User::factory()->create(['name' => 'Alice']);
        $bob = User::factory()->create(['name' => 'Bob']);
        $carol = User::factory()->create(['name' => 'Carol']);

        $household = Household::create([
            'name' => 'Elm Street',
            'invite_code' => 'ELMST123',
            'created_by' => $alice->id,
        ]);
        $household->members()->attach($alice->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($bob->id, ['role' => 'member', 'joined_at' => now()]);
        $household->members()->attach($carol->id, ['role' => 'member', 'joined_at' => now()]);

        $openByBob = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $bob->id,
            'title' => 'Bob Open Chore',
            'category' => 'Cleaning',
            'difficulty' => 'easy',
            'reward_value' => 25,
            'reward_description' => '25 Points',
            'status' => 'open',
        ]);

        $takenByCarol = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $alice->id,
            'assignee_id' => $carol->id,
            'title' => 'Carol Taken Chore',
            'category' => 'Kitchen',
            'difficulty' => 'easy',
            'reward_value' => 30,
            'reward_description' => '30 Points',
            'status' => 'claimed',
            'claimed_at' => now(),
        ]);

        $awaitingReview = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $alice->id,
            'assignee_id' => $carol->id,
            'title' => 'Carol Awaiting Review',
            'category' => 'Kitchen',
            'difficulty' => 'medium',
            'reward_value' => 40,
            'reward_description' => '40 Points',
            'status' => 'submitted',
            'claimed_at' => now()->subHour(),
            'submitted_at' => now(),
        ]);

        $completedByCarol = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $alice->id,
            'assignee_id' => $carol->id,
            'title' => 'Completed By Carol',
            'category' => 'Cleaning',
            'difficulty' => 'easy',
            'reward_value' => 50,
            'reward_description' => '50 Points',
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        $completedByBob = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $alice->id,
            'assignee_id' => $bob->id,
            'title' => 'Completed By Bob',
            'category' => 'Cleaning',
            'difficulty' => 'easy',
            'reward_value' => 20,
            'reward_description' => '20 Points',
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        BountyNotification::create([
            'household_id' => $household->id,
            'bounty_id' => $takenByCarol->id,
            'user_id' => $bob->id,
            'actor_id' => $carol->id,
            'event_type' => 'claimed',
            'event_name' => 'Chore Claimed',
            'description' => 'Carol claimed a chore.',
            'category' => 'Kitchen',
            'is_read' => false,
        ]);

        // Bob leaves the household
        Sanctum::actingAs($bob);
        $this->postJson("/api/households/{$household->id}/leave")->assertStatus(200);

        // Departed user cannot mutate or verify household chores anymore
        $this->putJson("/api/bounties/{$openByBob->id}", ['title' => 'Sneaky Edit'])->assertStatus(403);
        $this->postJson("/api/bounties/{$openByBob->id}/cancel")->assertStatus(403);
        $this->deleteJson("/api/bounties/{$openByBob->id}")->assertStatus(403);
        $this->postJson("/api/bounties/{$awaitingReview->id}/verify")->assertStatus(403);

        // Departed user's /api/bounties retains ONLY completed chores executed by other members
        $bobVisibleIds = collect($this->getJson('/api/bounties')->assertStatus(200)->json('data'))
            ->pluck('id')
            ->all();
        $this->assertContains($completedByCarol->id, $bobVisibleIds);
        $this->assertNotContains($openByBob->id, $bobVisibleIds);
        $this->assertNotContains($takenByCarol->id, $bobVisibleIds);
        $this->assertNotContains($awaitingReview->id, $bobVisibleIds);
        $this->assertNotContains($completedByBob->id, $bobVisibleIds);

        // Direct show of hidden chore returns 403
        $this->getJson("/api/bounties/{$openByBob->id}")->assertStatus(403);
        $this->getJson("/api/bounties/{$completedByCarol->id}")->assertStatus(200);

        // Notifications for departed household are revoked
        $this->getJson("/api/notifications?household_id={$household->id}")->assertStatus(403);
        $this->assertCount(0, $this->getJson('/api/notifications')->assertStatus(200)->json('data'));

        // Active member Carol does NOT see non-completed chores created by departed Bob
        Sanctum::actingAs($carol);
        $carolVisibleIds = collect(
            $this->getJson("/api/bounties?household_id={$household->id}")->assertStatus(200)->json('data')
        )->pluck('id')->all();
        $this->assertNotContains($openByBob->id, $carolVisibleIds);
        $this->assertContains($takenByCarol->id, $carolVisibleIds);
        $this->assertContains($completedByCarol->id, $carolVisibleIds);

        // Bob rejoins via invite code: active visibility is restored
        Sanctum::actingAs($bob);
        $this->postJson('/api/households/join', ['invite_code' => 'ELMST123'])->assertStatus(200);
        $rejoinedIds = collect(
            $this->getJson("/api/bounties?household_id={$household->id}")->assertStatus(200)->json('data')
        )->pluck('id')->all();
        $this->assertContains($openByBob->id, $rejoinedIds);
        $this->assertContains($takenByCarol->id, $rejoinedIds);
        $this->assertContains($awaitingReview->id, $rejoinedIds);
        $this->assertContains($completedByCarol->id, $rejoinedIds);
    }

    public function test_owner_cannot_force_add_outsider_and_member_removal_releases_claims(): void
    {
        Storage::fake('public');

        $owner = User::factory()->create(['name' => 'Owner']);
        $member = User::factory()->create(['name' => 'Member']);
        $outsider = User::factory()->create(['name' => 'Outsider']);

        $household = Household::create([
            'name' => 'Oak Place',
            'invite_code' => 'OAKPL123',
            'created_by' => $owner->id,
        ]);
        $household->members()->attach($owner->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($member->id, ['role' => 'member', 'joined_at' => now()]);

        Sanctum::actingAs($owner);

        // Owner cannot attach arbitrary user_id directly
        $this->postJson("/api/households/{$household->id}/members", [
            'user_id' => $outsider->id,
        ])->assertStatus(403);

        // Validation upper bound rejects absurd points
        $this->postJson('/api/bounties', [
            'household_id' => $household->id,
            'title' => 'Overpriced Chore',
            'category' => 'Cleaning',
            'difficulty' => 'easy',
            'points' => 999999999,
        ])->assertStatus(422);

        $bounty = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $owner->id,
            'title' => 'Take out trash',
            'category' => 'Trash',
            'difficulty' => 'easy',
            'reward_value' => 20,
            'reward_description' => '20 Points',
            'status' => 'open',
        ]);

        $otherBounty = Bounty::create([
            'household_id' => $household->id,
            'created_by' => $owner->id,
            'assignee_id' => $owner->id,
            'title' => 'Wipe counters',
            'category' => 'Kitchen',
            'difficulty' => 'easy',
            'reward_value' => 15,
            'reward_description' => '15 Points',
            'status' => 'submitted',
        ]);

        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);
        $proofFile = UploadedFile::fake()->image('proof.jpg');
        $this->postJson("/api/bounties/{$bounty->id}/submit", [
            'proof' => 'Done',
            'proof_images' => [$proofFile],
        ])->assertStatus(200);

        $bounty->refresh();
        $storedPath = $bounty->submission_images[0] ?? '';
        $this->assertNotEmpty($storedPath);
        $filename = basename($storedPath);

        // Proof image endpoint denies cross-bounty path traversal / mismatch
        $this->get("/api/bounty-proofs/{$household->id}/{$otherBounty->id}/{$filename}")
            ->assertStatus(404);
        $this->get("/api/bounty-proofs/{$household->id}/{$bounty->id}/{$filename}")
            ->assertStatus(200);

        // Removing member releases claimed/submitted chores back to open & deletes proof
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/households/{$household->id}/members/{$member->id}")
            ->assertStatus(204);

        $bounty->refresh();
        $this->assertSame('open', $bounty->status);
        $this->assertNull($bounty->assignee_id);
        $this->assertEmpty($bounty->submission_images ?? []);
        Storage::disk('public')->assertMissing($storedPath);
        $this->assertSame(
            'released',
            BountyClaim::where('bounty_id', $bounty->id)->first()?->status
        );
    }
}

