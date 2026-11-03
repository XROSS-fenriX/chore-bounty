<?php

namespace Tests\Feature;

use App\Models\Household;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HouseholdManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_multiple_households_and_join_by_invite_code(): void
    {
        $user1 = User::factory()->create(['name' => 'Alice']);
        $user2 = User::factory()->create(['name' => 'Bob']);

        Sanctum::actingAs($user1);

        // 1. User1 creates first household
        $createRes1 = $this->postJson('/api/households', [
            'name' => 'Downtown Loft',
        ]);
        $createRes1->assertStatus(201)
            ->assertJsonPath('data.name', 'Downtown Loft');

        $household1Id = $createRes1->json('data.id');
        $inviteCode1 = $createRes1->json('data.invite_code');

        // 2. User1 creates second household
        $createRes2 = $this->postJson('/api/households', [
            'name' => 'Lake Cabin',
        ]);
        $createRes2->assertStatus(201)
            ->assertJsonPath('data.name', 'Lake Cabin');

        // 3. User1 lists their households (should have 2)
        $listRes = $this->getJson('/api/households');
        $listRes->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // 4. User2 joins User1's Downtown Loft via invite code
        Sanctum::actingAs($user2);

        $joinRes = $this->postJson('/api/households/join', [
            'invite_code' => $inviteCode1,
        ]);
        $joinRes->assertStatus(200)
            ->assertJsonPath('data.name', 'Downtown Loft');

        // Verify User2 is in Downtown Loft
        $user2Households = $this->getJson('/api/households');
        $user2Households->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Downtown Loft');

        // 5. User2 leaves Downtown Loft
        $leaveRes = $this->postJson("/api/households/{$household1Id}/leave");
        $leaveRes->assertStatus(200);

        // Verify User2 now has 0 households
        $afterLeave = $this->getJson('/api/households');
        $afterLeave->assertStatus(200)
            ->assertJsonCount(0, 'data');
    }
}
