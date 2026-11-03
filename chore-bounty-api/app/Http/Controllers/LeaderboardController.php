<?php

namespace App\Http\Controllers;

use App\Models\Household;
use App\Services\LeaderboardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LeaderboardController extends Controller
{
    public function __construct(
        protected LeaderboardService $leaderboardService
    ) {}

    public function index(Request $request, Household $household): JsonResponse
    {
        abort_unless(
            $household->members()->where('users.id', $request->user()->id)->exists(),
            403,
            'You are not a member of this household.'
        );

        $leaderboard = $this->leaderboardService->getHouseholdLeaderboard($household);

        return response()->json([
            'household' => [
                'id' => $household->id,
                'name' => $household->name,
            ],
            'data' => $leaderboard,
        ]);
    }

    public function current(Request $request): JsonResponse
    {
        $householdId = $request->header('X-Household-Id') ?? $request->query('household_id');

        $household = null;
        if ($householdId) {
            $household = $request->user()->households()->where('households.id', $householdId)->first();
        }

        if (! $household) {
            $household = $request->user()->households()->first();
        }

        if (! $household) {
            return response()->json([
                'household' => null,
                'data' => [],
            ]);
        }

        $leaderboard = $this->leaderboardService->getHouseholdLeaderboard($household);

        return response()->json([
            'household' => [
                'id' => $household->id,
                'name' => $household->name,
            ],
            'data' => $leaderboard,
        ]);
    }
}
