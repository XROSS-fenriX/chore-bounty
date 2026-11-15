<?php

namespace Tests\Feature;

use App\Models\Bounty;
use App\Models\BountyClaim;
use App\Models\BountyCompletion;
use App\Models\Household;
use App\Models\User;
use Database\Seeders\Apartment4AChoresSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ChoreStateAndIntegrityTest extends TestCase
{
    use RefreshDatabase;

    private function seedHousehold(): array
    {
        $creator = User::factory()->create(['first_name' => 'Sheldon', 'last_name' => 'Cooper']);
        $member = User::factory()->create(['first_name' => 'Leonard', 'last_name' => 'Hofstadter']);
        $observer = User::factory()->create(['first_name' => 'Penny', 'last_name' => 'Teller']);

        $household = Household::create([
            'name' => 'Apt 4A',
            'invite_code' => 'STATE123',
            'created_by' => $creator->id,
        ]);
        $household->members()->attach($creator->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($member->id, ['role' => 'member', 'joined_at' => now()]);
        $household->members()->attach($observer->id, ['role' => 'member', 'joined_at' => now()]);

        return [$creator, $member, $observer, $household];
    }

    private function createBounty(Household $household, User $creator, array $overrides = []): Bounty
    {
        return Bounty::create([
            'household_id' => $household->id,
            'created_by' => $creator->id,
            'title' => 'Sample chore',
            'category' => 'Cleaning',
            'difficulty' => 'easy',
            'xp_reward' => 25,
            'reward_value' => 25,
            'reward_description' => '25 Tokens',
            'status' => 'open',
            ...$overrides,
        ]);
    }

    public function test_state_matrix_for_creator_and_non_creator(): void
    {
        [$creator, $member, , $household] = $this->seedHousehold();

        // Available
        $available = $this->createBounty($household, $creator, [
            'due_at' => now()->addHour(),
        ]);
        Sanctum::actingAs($member);
        $this->putJson("/api/bounties/{$available->id}", ['title' => 'No'])->assertStatus(403);
        $this->postJson("/api/bounties/{$available->id}/cancel")->assertStatus(403);
        $this->deleteJson("/api/bounties/{$available->id}")->assertStatus(403);

        Sanctum::actingAs($creator);
        $this->postJson("/api/bounties/{$available->id}/claim")->assertStatus(403);
        $this->putJson("/api/bounties/{$available->id}", ['title' => 'Updated'])->assertStatus(200);
        $this->deleteJson("/api/bounties/{$available->id}")->assertStatus(204);

        // Taken (even if past due)
        $taken = $this->createBounty($household, $creator, [
            'status' => 'claimed',
            'assignee_id' => $member->id,
            'due_at' => now()->subHours(2),
        ]);
        $pastDueStr = $taken->due_at->toIso8601String();
        Sanctum::actingAs($member);
        $this->putJson("/api/bounties/{$taken->id}", ['title' => 'No'])->assertStatus(403);
        $this->postJson("/api/bounties/{$taken->id}/cancel")->assertStatus(403);
        $this->deleteJson("/api/bounties/{$taken->id}")->assertStatus(403);
        $this->postJson("/api/bounties/{$taken->id}/claim")->assertStatus(403);

        Sanctum::actingAs($creator);
        $this->deleteJson("/api/bounties/{$taken->id}")->assertStatus(403);
        $this->putJson("/api/bounties/{$taken->id}", [
            'title' => 'Still Taken',
            'due_at' => $pastDueStr,
        ])->assertStatus(200)->assertJsonPath('data.title', 'Still Taken');
        $this->postJson("/api/bounties/{$taken->id}/cancel")->assertStatus(200);

        // Cancelled
        Sanctum::actingAs($member);
        $this->deleteJson("/api/bounties/{$taken->id}")->assertStatus(403);
        Sanctum::actingAs($creator);
        $this->putJson("/api/bounties/{$taken->id}", ['title' => 'No'])->assertStatus(403);
        $this->postJson("/api/bounties/{$taken->id}/cancel")->assertStatus(403);
        $this->postJson("/api/bounties/{$taken->id}/claim")->assertStatus(403);
        $this->deleteJson("/api/bounties/{$taken->id}")->assertStatus(204);

        // Expired
        $expired = $this->createBounty($household, $creator, [
            'due_at' => now()->subMinutes(10),
        ]);
        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$expired->id}/claim")->assertStatus(403);
        $this->deleteJson("/api/bounties/{$expired->id}")->assertStatus(403);
        Sanctum::actingAs($creator);
        $this->putJson("/api/bounties/{$expired->id}", ['title' => 'No'])->assertStatus(403);
        $this->postJson("/api/bounties/{$expired->id}/cancel")->assertStatus(403);
        $this->deleteJson("/api/bounties/{$expired->id}")->assertStatus(204);

        // Submitted & Completed
        $submitted = $this->createBounty($household, $creator, [
            'status' => 'submitted',
            'assignee_id' => $member->id,
        ]);
        Sanctum::actingAs($creator);
        $this->putJson("/api/bounties/{$submitted->id}", ['title' => 'No'])->assertStatus(403);
        $this->postJson("/api/bounties/{$submitted->id}/cancel")->assertStatus(403);
        $this->deleteJson("/api/bounties/{$submitted->id}")->assertStatus(403);

        $completed = $this->createBounty($household, $creator, [
            'status' => 'completed',
            'assignee_id' => $member->id,
        ]);
        $this->putJson("/api/bounties/{$completed->id}", ['title' => 'No'])->assertStatus(403);
        $this->postJson("/api/bounties/{$completed->id}/cancel")->assertStatus(403);
        $this->deleteJson("/api/bounties/{$completed->id}")->assertStatus(403);
    }

    public function test_cancel_taken_chore_releases_claim_and_rejects_pending_completion(): void
    {
        [$creator, $member, , $household] = $this->seedHousehold();
        $bounty = $this->createBounty($household, $creator);

        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);

        $claim = BountyClaim::where('bounty_id', $bounty->id)->where('status', 'active')->firstOrFail();
        $completion = $claim->completions()->create([
            'submission_note' => 'Done',
            'status' => 'pending',
            'submitted_at' => now(),
        ]);

        Sanctum::actingAs($creator);
        $this->postJson("/api/bounties/{$bounty->id}/cancel")->assertStatus(200);

        $this->assertSame('cancelled', $bounty->fresh()->status);
        $this->assertSame('released', $claim->fresh()->status);
        $this->assertNotNull($claim->fresh()->released_at);
        $this->assertSame('rejected', $completion->fresh()->status);
    }

    public function test_second_claim_on_claimed_chore_is_rejected_and_only_one_active_claim_exists(): void
    {
        [$creator, $member, $observer, $household] = $this->seedHousehold();
        $bounty = $this->createBounty($household, $creator);

        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);

        Sanctum::actingAs($observer);
        $res = $this->postJson("/api/bounties/{$bounty->id}/claim");
        $this->assertContains($res->getStatusCode(), [403, 422]);

        $this->assertSame(
            1,
            BountyClaim::where('bounty_id', $bounty->id)->where('status', 'active')->count()
        );
    }

    public function test_approve_sends_approved_to_assignee_awarded_to_others_and_includes_bounty_payload(): void
    {
        [$creator, $member, $observer, $household] = $this->seedHousehold();
        $bounty = $this->createBounty($household, $creator, [
            'title' => 'Buy water',
            'reward_value' => 10,
            'xp_reward' => 10,
            'reward_description' => '10 Tokens',
        ]);

        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);
        $this->postJson("/api/bounties/{$bounty->id}/submit", ['submission_proof' => 'Bought it'])->assertStatus(200);

        Sanctum::actingAs($creator);
        $this->postJson("/api/bounties/{$bounty->id}/verify")->assertStatus(200);

        Sanctum::actingAs($member);
        $memberNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200)
            ->json('data');
        $approvedRows = collect($memberNotifs)->where('event_type', 'approved')->values();
        $this->assertCount(1, $approvedRows);
        $this->assertSame('Buy water', $approvedRows[0]['bounty']['title']);
        $this->assertSame(10, $approvedRows[0]['bounty']['tokens']);
        $this->assertEmpty(collect($memberNotifs)->where('event_type', 'awarded'));

        Sanctum::actingAs($observer);
        $observerNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200)
            ->json('data');
        $this->assertCount(1, collect($observerNotifs)->where('event_type', 'awarded'));
        $this->assertEmpty(collect($observerNotifs)->where('event_type', 'approved'));

        Sanctum::actingAs($creator);
        $creatorNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200)
            ->json('data');
        $this->assertEmpty(collect($creatorNotifs)->whereIn('event_type', ['approved', 'awarded']));
    }

    public function test_reject_with_feedback_sends_redo_notification_to_assignee(): void
    {
        [$creator, $member, , $household] = $this->seedHousehold();
        $bounty = $this->createBounty($household, $creator, ['title' => 'Sweep porch']);

        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);
        $this->postJson("/api/bounties/{$bounty->id}/submit", ['submission_proof' => 'Swept'])->assertStatus(200);

        Sanctum::actingAs($creator);
        $this->postJson("/api/bounties/{$bounty->id}/reject", [
            'feedback' => 'Missed the corners',
        ])->assertStatus(200);

        Sanctum::actingAs($member);
        $notifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200)
            ->json('data');
        $redo = collect($notifs)->firstWhere('event_type', 'redo');
        $this->assertNotNull($redo);
        $this->assertStringContainsString('Missed the corners', $redo['description']);
    }

    public function test_household_leave_releases_claims_and_keeps_household_when_chores_exist(): void
    {
        [$creator, $member, $observer, $household] = $this->seedHousehold();
        $bounty = $this->createBounty($household, $creator);

        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);
        $this->postJson("/api/households/{$household->id}/leave")->assertStatus(200);

        $bounty->refresh();
        $this->assertSame('open', $bounty->status);
        $this->assertNull($bounty->assignee_id);
        $this->assertSame(
            'released',
            BountyClaim::where('bounty_id', $bounty->id)->firstOrFail()->status
        );

        // Remaining members leave -> household has chores so it must not throw 500 and remains in DB
        Sanctum::actingAs($observer);
        $this->postJson("/api/households/{$household->id}/leave")->assertStatus(200);

        Sanctum::actingAs($creator);
        $this->postJson("/api/households/{$household->id}/leave")->assertStatus(200);

        $this->assertDatabaseHas('households', ['id' => $household->id]);
    }

    public function test_household_join_and_leave_dispatch_notifications_to_active_members(): void
    {
        [$creator, $member, , $household] = $this->seedHousehold();
        $newcomer = User::factory()->create(['first_name' => 'Howard', 'last_name' => 'Wolowitz']);

        Sanctum::actingAs($newcomer);
        $this->postJson('/api/households/join', [
            'invite_code' => $household->invite_code,
        ])->assertStatus(200);

        // Newcomer does not receive their own join notification
        $newcomerNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200)
            ->json('data');
        $this->assertNull(collect($newcomerNotifs)->firstWhere('event_type', 'member_joined'));

        // Existing member receives member_joined notification
        Sanctum::actingAs($member);
        $memberNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200)
            ->json('data');
        $joined = collect($memberNotifs)->firstWhere('event_type', 'member_joined');
        $this->assertNotNull($joined);
        $this->assertSame('Member Joined', $joined['event_name']);
        $this->assertStringContainsString('Howard Wolowitz joined "Apt 4A"', $joined['description']);
        $this->assertNull($joined['bounty_id']);

        // Newcomer leaves -> creator & remaining members receive member_left notification
        Sanctum::actingAs($newcomer);
        $this->postJson("/api/households/{$household->id}/leave")->assertStatus(200);

        Sanctum::actingAs($creator);
        $creatorNotifs = $this->getJson("/api/notifications?household_id={$household->id}")
            ->assertStatus(200)
            ->json('data');
        $left = collect($creatorNotifs)->firstWhere('event_type', 'member_left');
        $this->assertNotNull($left);
        $this->assertSame('Member Left', $left['event_name']);
        $this->assertStringContainsString('Howard Wolowitz left "Apt 4A"', $left['description']);
        $this->assertNull($left['bounty_id']);
    }

    public function test_leaderboard_ties_share_rank_and_bogus_period_falls_back_to_all(): void
    {
        [$creator, $member, $observer, $household] = $this->seedHousehold();

        $this->createBounty($household, $creator, [
            'assignee_id' => $member->id,
            'status' => 'completed',
            'completed_at' => now()->subMonths(2),
            'reward_value' => 100,
            'xp_reward' => 100,
        ]);
        $this->createBounty($household, $creator, [
            'assignee_id' => $observer->id,
            'status' => 'completed',
            'completed_at' => now()->subMonths(2),
            'reward_value' => 100,
            'xp_reward' => 100,
        ]);

        Sanctum::actingAs($creator);
        $res = $this->getJson("/api/households/{$household->id}/leaderboard?period=bogus")
            ->assertStatus(200)
            ->json('data');

        // Leonard Hofstadter and Penny Teller both have 100 -> both rank 1; Sheldon has 0 -> rank 3
        $this->assertSame(1, $res[0]['rank']);
        $this->assertSame(1, $res[1]['rank']);
        $this->assertSame(3, $res[2]['rank']);
        $this->assertSame(100, $res[0]['total_tokens']);
    }

    public function test_legacy_completion_reject_clears_assignee_id_and_update_preserves_difficulty(): void
    {
        [$creator, $member, , $household] = $this->seedHousehold();
        $bounty = $this->createBounty($household, $creator, [
            'difficulty' => 'hard',
            'category' => 'Kitchen',
        ]);

        // Update with category only does not overwrite difficulty
        Sanctum::actingAs($creator);
        $this->putJson("/api/bounties/{$bounty->id}", ['category' => 'Groceries'])
            ->assertStatus(200)
            ->assertJsonPath('data.difficulty', 'hard')
            ->assertJsonPath('data.category', 'Groceries');

        // Legacy claim + completion reject clears assignee_id
        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);
        $claim = BountyClaim::where('bounty_id', $bounty->id)->where('status', 'active')->firstOrFail();
        $completion = BountyCompletion::create([
            'bounty_claim_id' => $claim->id,
            'submission_note' => 'Done',
            'status' => 'pending',
            'submitted_at' => now(),
        ]);

        Sanctum::actingAs($creator);
        $this->patchJson("/api/completions/{$completion->id}", ['status' => 'rejected'])
            ->assertStatus(200);

        $bounty->refresh();
        $this->assertSame('open', $bounty->status);
        $this->assertNull($bounty->assignee_id);
        $this->assertNull($bounty->claimed_at);
    }

    public function test_chore_creation_rejects_past_or_current_due_at_and_accepts_future_or_null(): void
    {
        [$creator, , , $household] = $this->seedHousehold();
        Sanctum::actingAs($creator);

        $basePayload = [
            'household_id' => $household->id,
            'title' => 'Water plants',
            'category' => 'Cleaning',
            'points' => 25,
            'reward_description' => '25 Tokens',
        ];

        $this->postJson('/api/bounties', [
            ...$basePayload,
            'due_at' => now()->subMinute()->toIso8601String(),
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['due_at']);

        $this->postJson('/api/bounties', [
            ...$basePayload,
            'due_at' => now()->toIso8601String(),
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['due_at']);

        $this->postJson('/api/bounties', [
            ...$basePayload,
            'due_at' => now()->addHour()->toIso8601String(),
        ])->assertStatus(201);

        $this->postJson('/api/bounties', $basePayload)->assertStatus(201);
    }

    public function test_apartment_4a_chores_seeder_adds_amy_farrah_fowler_and_seeds_five_chores_per_member(): void
    {
        $sheldon = User::factory()->create(['first_name' => 'Sheldon', 'last_name' => 'Cooper']);
        $leonard = User::factory()->create(['first_name' => 'Leonard', 'last_name' => 'Hofstadter']);
        $penny = User::factory()->create(['first_name' => 'Penelophe', 'last_name' => 'Hofstadter']);

        $household = Household::create([
            'name' => 'Apartment 4A',
            'invite_code' => 'BDVAUBRV',
            'created_by' => $leonard->id,
        ]);
        $household->members()->attach($leonard->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($sheldon->id, ['role' => 'member', 'joined_at' => now()]);
        $household->members()->attach($penny->id, ['role' => 'member', 'joined_at' => now()]);

        $this->seed(Apartment4AChoresSeeder::class);
        $this->seed(Apartment4AChoresSeeder::class);

        $amy = User::where('email', 'amy.fowler@gmail.com')->first();
        $this->assertNotNull($amy);
        $this->assertSame('Amy Farrah Fowler', $amy->name);
        $this->assertSame('female', $amy->gender);

        $memberIds = $household->members()->pluck('users.id')->all();
        $this->assertContains($amy->id, $memberIds);
        $this->assertCount(4, $memberIds);

        foreach ($memberIds as $memberId) {
            $count = Bounty::where('household_id', $household->id)
                ->where('created_by', $memberId)
                ->count();
            $this->assertSame(5, $count);
        }

        $this->assertSame(20, Bounty::where('household_id', $household->id)->count());
    }

    public function test_bounties_index_sets_content_length_and_supports_gzip_compression(): void
    {
        [$creator, , , $household] = $this->seedHousehold();
        for ($i = 1; $i <= 30; $i++) {
            $this->createBounty($household, $creator, [
                'title' => "Household Chore #$i",
            ]);
        }

        Sanctum::actingAs($creator);

        $plainResponse = $this->getJson("/api/bounties?household_id={$household->id}&per_page=100");
        $plainResponse->assertStatus(200);
        $this->assertTrue($plainResponse->headers->has('Content-Length'));
        $this->assertSame(
            (string) strlen((string) $plainResponse->getContent()),
            $plainResponse->headers->get('Content-Length')
        );

        $gzipResponse = $this->withHeaders(['Accept-Encoding' => 'gzip'])
            ->getJson("/api/bounties?household_id={$household->id}&per_page=100");
        $gzipResponse->assertStatus(200);
        $this->assertSame('gzip', $gzipResponse->headers->get('Content-Encoding'));
        $this->assertStringContainsString('Accept-Encoding', (string) $gzipResponse->headers->get('Vary'));

        $compressed = (string) $gzipResponse->getContent();
        $this->assertSame((string) strlen($compressed), $gzipResponse->headers->get('Content-Length'));

        $decoded = gzdecode($compressed);
        $this->assertIsString($decoded);
        $payload = json_decode($decoded, true, 512, JSON_THROW_ON_ERROR);
        $this->assertCount(30, $payload['data']);
    }

    public function test_submit_stores_up_to_three_proof_images_validates_files_and_reject_cleans_up(): void
    {
        Storage::fake('public');
        [$creator, $member, , $household] = $this->seedHousehold();
        $bounty = $this->createBounty($household, $creator);

        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/claim")->assertStatus(200);

        // Rejects more than 3 images
        $this->post("/api/bounties/{$bounty->id}/submit", [
            'proof_images' => [
                UploadedFile::fake()->image('a.jpg'),
                UploadedFile::fake()->image('b.jpg'),
                UploadedFile::fake()->image('c.jpg'),
                UploadedFile::fake()->image('d.jpg'),
            ],
        ], ['Accept' => 'application/json'])->assertStatus(422);

        // Rejects non-image uploads
        $this->post("/api/bounties/{$bounty->id}/submit", [
            'proof_images' => [
                UploadedFile::fake()->create('note.txt', 10, 'text/plain'),
            ],
        ], ['Accept' => 'application/json'])->assertStatus(422);

        // Accepts up to 3 valid images without requiring a text note
        $submitRes = $this->post("/api/bounties/{$bounty->id}/submit", [
            'proof_images' => [
                UploadedFile::fake()->image('counter.jpg', 400, 300),
                UploadedFile::fake()->image('sink.png', 400, 300),
            ],
        ], ['Accept' => 'application/json'])->assertStatus(200);

        $data = $submitRes->json('data');
        $this->assertSame('submitted', $data['status']);
        $this->assertSame('Photo proof submitted', $data['submission_proof']);
        $this->assertCount(2, $data['submission_images']);

        $bounty->refresh();
        $this->assertCount(2, $bounty->submission_images);
        foreach ($bounty->submission_images as $urlPath) {
            $diskPath = ltrim(str_replace('/storage/', '', $urlPath), '/');
            Storage::disk('public')->assertExists($diskPath);
        }

        // Serves stored proof images via API route with HTTP byte-range support
        $apiImagePath = str_replace('/storage/bounty-proofs/', '/api/bounty-proofs/', $bounty->submission_images[0]);
        $fullBytes = Storage::disk('public')->get(
            ltrim(str_replace('/storage/', '', $bounty->submission_images[0]), '/')
        );
        $chunkEnd = min(63, strlen($fullBytes) - 1);
        $rangeRes = $this->get($apiImagePath, [
            'Range' => "bytes=0-{$chunkEnd}",
        ])->assertStatus(206);
        $this->assertSame(substr($fullBytes, 0, $chunkEnd + 1), $rangeRes->getContent());

        // Creator requests redo -> deletes stored proof images and resets fields
        Sanctum::actingAs($creator);
        $this->postJson("/api/bounties/{$bounty->id}/reject", [
            'feedback' => 'Please upload a clearer photo',
        ])->assertStatus(200);

        $oldImages = $bounty->submission_images;
        $bounty->refresh();
        $this->assertSame('claimed', $bounty->status);
        $this->assertNull($bounty->submission_images);
        $this->assertNull($bounty->submission_proof);

        foreach ($oldImages as $urlPath) {
            $diskPath = ltrim(str_replace('/storage/', '', $urlPath), '/');
            Storage::disk('public')->assertMissing($diskPath);
        }

        // Resubmitting with text note only (without photos) succeeds
        Sanctum::actingAs($member);
        $this->postJson("/api/bounties/{$bounty->id}/submit", [
            'submission_proof' => 'Done without photos',
        ])->assertStatus(200)
          ->assertJsonPath('data.status', 'submitted')
          ->assertJsonPath('data.submission_proof', 'Done without photos')
          ->assertJsonPath('data.submission_images', []);
    }
}
