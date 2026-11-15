<?php

namespace App\Services;

use App\Models\Household;
use Illuminate\Support\Collection;

class LeaderboardService
{
    /**
     * Fetch household leaderboard ranking with completed bounty count and accumulated tokens.
     */
    public function getHouseholdLeaderboard(Household $household, ?string $period = 'all'): Collection
    {
        $since = match ($period) {
            'week' => now()->startOfWeek(),
            'month' => now()->startOfMonth(),
            default => null,
        };

        $completedScope = function ($query) use ($household, $since) {
            $query->where('household_id', $household->id)
                ->where('status', 'completed');
            if ($since !== null) {
                $query->where('completed_at', '>=', $since);
            }
        };

        $rows = $household->members()
            ->withCount([
                'assignedBounties as completed_bounties_count' => $completedScope,
                'assignedBounties as active_bounties_count' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                        ->whereIn('status', ['claimed', 'submitted', 'in_progress']);
                },
            ])
            ->withSum([
                'assignedBounties as total_tokens_earned' => $completedScope,
            ], 'reward_value')
            ->withSum([
                'assignedBounties as fallback_xp_earned' => $completedScope,
            ], 'xp_reward')
            ->get()
            ->map(function ($user) {
                $tokens = (int) ($user->total_tokens_earned ?? 0);
                if ($tokens === 0 && isset($user->fallback_xp_earned) && $user->fallback_xp_earned > 0) {
                    $tokens = (int) $user->fallback_xp_earned;
                }

                return [
                    'user_id' => (int) $user->id,
                    'first_name' => $user->first_name,
                    'middle_name' => $user->middle_name,
                    'last_name' => $user->last_name,
                    'name' => $user->name,
                    'gender' => $user->gender,
                    'avatar_url' => $user->avatar_url ?? $user->avatar,
                    'avatar' => $user->avatar,
                    'completed_bounties_count' => (int) $user->completed_bounties_count,
                    'active_bounties_count' => (int) $user->active_bounties_count,
                    'total_tokens' => $tokens,
                    'total_xp' => $tokens,
                    'total_reward_value' => (float) $tokens,
                    'tier' => $this->calculateRpgTier($tokens),
                ];
            })
            ->sort(function (array $a, array $b) {
                return ($b['total_tokens'] <=> $a['total_tokens'])
                    ?: ($b['completed_bounties_count'] <=> $a['completed_bounties_count'])
                    ?: (strtolower((string) $a['name']) <=> strtolower((string) $b['name']))
                    ?: ($a['user_id'] <=> $b['user_id']);
            })
            ->values();

        $previousTokens = null;
        $currentRank = 0;

        return $rows->map(function (array $row, int $index) use (&$previousTokens, &$currentRank) {
            if ($previousTokens === null || $row['total_tokens'] !== $previousTokens) {
                $currentRank = $index + 1;
                $previousTokens = $row['total_tokens'];
            }

            return [
                'rank' => $currentRank,
                ...$row,
            ];
        });
    }

    public function calculateRpgTier(int $tokens): string
    {
        return match (true) {
            $tokens >= 1000 => 'Grandmaster Roommate',
            $tokens >= 500  => 'Chore Knight',
            $tokens >= 200  => 'Apprentice Sweeper',
            default         => 'Household Novice',
        };
    }
}
