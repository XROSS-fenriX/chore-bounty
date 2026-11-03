<?php

namespace App\Services;

use App\Models\Household;
use Illuminate\Support\Collection;

class LeaderboardService
{
    /**
     * Fetch household leaderboard ranking with completed bounty count and accumulated XP/rewards.
     */
    public function getHouseholdLeaderboard(Household $household): Collection
    {
        return $household->members()
            ->withCount([
                'assignedBounties as completed_bounties_count' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                          ->where('status', 'completed');
                },
                'assignedBounties as active_bounties_count' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                          ->whereIn('status', ['claimed', 'submitted', 'in_progress']);
                }
            ])
            ->withSum([
                'assignedBounties as total_xp_earned' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                          ->where('status', 'completed');
                }
            ], 'xp_reward')
            ->withSum([
                'assignedBounties as total_reward_value' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                          ->where('status', 'completed');
                }
            ], 'reward_value')
            ->orderByDesc('completed_bounties_count')
            ->orderByDesc('total_xp_earned')
            ->get()
            ->map(function ($user, $index) {
                $xp = (int) ($user->total_xp_earned ?? 0);
                return [
                    'rank' => $index + 1,
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'avatar_url' => $user->avatar_url,
                    'completed_bounties_count' => (int) $user->completed_bounties_count,
                    'active_bounties_count' => (int) $user->active_bounties_count,
                    'total_xp' => $xp,
                    'total_reward_value' => (float) ($user->total_reward_value ?? 0.0),
                    'tier' => $this->calculateRpgTier($xp),
                ];
            });
    }

    public function calculateRpgTier(int $xp): string
    {
        return match (true) {
            $xp >= 1000 => 'Grandmaster Roommate',
            $xp >= 500  => 'Chore Knight',
            $xp >= 200  => 'Apprentice Sweeper',
            default     => 'Household Novice',
        };
    }
}
