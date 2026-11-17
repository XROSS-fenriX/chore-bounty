<?php

namespace Tests\Feature;

use App\Models\Bounty;
use App\Models\Household;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AccountAndHouseholdTest extends TestCase
{
    use RefreshDatabase;

    private function householdWithMember(): array
    {
        $owner = User::factory()->create(['first_name' => 'Sheldon', 'last_name' => 'Cooper']);
        $member = User::factory()->create(['first_name' => 'Leonard', 'last_name' => 'Hofstadter']);

        $household = Household::create([
            'name' => 'Apt 4A',
            'invite_code' => 'OLDCODE1',
            'created_by' => $owner->id,
        ]);
        $household->members()->attach($owner->id, ['role' => 'owner', 'joined_at' => now()]);
        $household->members()->attach($member->id, ['role' => 'member', 'joined_at' => now()]);

        return [$owner, $member, $household];
    }

    public function test_change_password_validates_input_and_keeps_only_current_session(): void
    {
        User::factory()->create([
            'email' => 'pw@example.com',
            'password' => Hash::make('old-password-1'),
        ]);

        $tokenA = $this->postJson('/api/auth/login', [
            'email' => 'pw@example.com',
            'password' => 'old-password-1',
        ])->assertStatus(200)->json('token');
        $tokenB = $this->postJson('/api/auth/login', [
            'email' => 'pw@example.com',
            'password' => 'old-password-1',
        ])->assertStatus(200)->json('token');

        $as = fn (string $token) => $this->withHeader('Authorization', "Bearer {$token}");

        // Wrong current password
        $as($tokenA)->putJson('/api/user/password', [
            'current_password' => 'not-the-password',
            'password' => 'new-password-1',
            'password_confirmation' => 'new-password-1',
        ])->assertStatus(422)->assertJsonValidationErrors(['current_password']);

        // Too short, unconfirmed, and unchanged passwords
        $as($tokenA)->putJson('/api/user/password', [
            'current_password' => 'old-password-1',
            'password' => 'short',
            'password_confirmation' => 'short',
        ])->assertStatus(422)->assertJsonValidationErrors(['password']);
        $as($tokenA)->putJson('/api/user/password', [
            'current_password' => 'old-password-1',
            'password' => 'new-password-1',
            'password_confirmation' => 'different-1',
        ])->assertStatus(422)->assertJsonValidationErrors(['password']);
        $as($tokenA)->putJson('/api/user/password', [
            'current_password' => 'old-password-1',
            'password' => 'old-password-1',
            'password_confirmation' => 'old-password-1',
        ])->assertStatus(422)->assertJsonValidationErrors(['password']);

        // Valid change
        $as($tokenA)->putJson('/api/user/password', [
            'current_password' => 'old-password-1',
            'password' => 'new-password-1',
            'password_confirmation' => 'new-password-1',
        ])->assertStatus(200)->assertJsonPath('message', 'Password updated.');

        $this->assertDatabaseCount('personal_access_tokens', 1);

        // Fresh requests: the other session is revoked, the current one still works.
        $this->app['auth']->forgetGuards();
        $as($tokenA)->getJson('/api/auth/me')->assertStatus(200);
        $this->app['auth']->forgetGuards();
        $as($tokenB)->getJson('/api/auth/me')->assertStatus(401);

        // New password signs in, old password does not.
        $this->postJson('/api/auth/login', [
            'email' => 'pw@example.com',
            'password' => 'new-password-1',
        ])->assertStatus(200);
        $this->postJson('/api/auth/login', [
            'email' => 'pw@example.com',
            'password' => 'old-password-1',
        ])->assertStatus(422);
    }

    public function test_only_owner_can_regenerate_invite_code_and_old_code_stops_working(): void
    {
        [$owner, $member, $household] = $this->householdWithMember();
        $outsider = User::factory()->create();

        Sanctum::actingAs($member);
        $this->postJson("/api/households/{$household->id}/invite-code/regenerate")->assertStatus(403);
        $this->assertSame('OLDCODE1', $household->fresh()->invite_code);

        Sanctum::actingAs($owner);
        $res = $this->postJson("/api/households/{$household->id}/invite-code/regenerate")
            ->assertStatus(200);
        $newCode = $res->json('data.invite_code');

        $this->assertMatchesRegularExpression('/^[A-Z0-9]{8}$/', $newCode);
        $this->assertNotSame('OLDCODE1', $newCode);
        $this->assertSame($newCode, $household->fresh()->invite_code);
        $this->assertSame(2, $household->members()->count());

        Sanctum::actingAs($outsider);
        $this->postJson('/api/households/join', ['invite_code' => 'OLDCODE1'])->assertStatus(404);
        $this->postJson('/api/households/join', ['invite_code' => $newCode])->assertStatus(200);
    }

    public function test_household_with_chores_or_other_members_cannot_be_deleted(): void
    {
        [$owner, $member, $household] = $this->householdWithMember();

        Sanctum::actingAs($member);
        $this->deleteJson("/api/households/{$household->id}")->assertStatus(403);

        Sanctum::actingAs($owner);

        // Other member still present
        $this->deleteJson("/api/households/{$household->id}")->assertStatus(422);
        $this->assertDatabaseHas('households', ['id' => $household->id]);

        // Member removed, but a chore exists
        $household->members()->detach($member->id);
        Bounty::create([
            'household_id' => $household->id,
            'created_by' => $owner->id,
            'title' => 'Sample chore',
            'category' => 'Cleaning',
            'difficulty' => 'easy',
            'xp_reward' => 20,
            'reward_value' => 20,
            'reward_description' => '20 Tokens',
            'status' => 'open',
        ]);
        $this->deleteJson("/api/households/{$household->id}")->assertStatus(422);
        $this->assertDatabaseHas('households', ['id' => $household->id]);
    }

    public function test_empty_single_member_household_can_be_deleted(): void
    {
        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        $id = $this->postJson('/api/households', ['name' => 'Solo'])
            ->assertStatus(201)
            ->json('data.id');

        $this->deleteJson("/api/households/{$id}")->assertStatus(204);
        $this->assertDatabaseMissing('households', ['id' => $id]);
    }
}
