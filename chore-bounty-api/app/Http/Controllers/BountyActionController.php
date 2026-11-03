<?php

namespace App\Http\Controllers;

use App\Http\Requests\ReviewBountyRequest;
use App\Http\Requests\SubmitBountyRequest;
use App\Http\Resources\BountyResource;
use App\Models\Bounty;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class BountyActionController extends Controller
{
    public function claim(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('claim', $bounty);

        $user = $request->user();

        DB::transaction(function () use ($user, $bounty) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            $lockedBounty->update([
                'assignee_id' => $user->id,
                'status' => 'claimed',
                'claimed_at' => now(),
            ]);

            // Synchronize with bounty_claims for relationship integrity
            $lockedBounty->claims()->create([
                'user_id' => $user->id,
                'status' => 'active',
                'claimed_at' => now(),
            ]);
        });

        return response()->json([
            'message' => 'Quest accepted! Best of luck, adventurer.',
            'data' => new BountyResource($bounty->fresh()->load(['creator', 'assignee', 'household'])),
        ]);
    }

    public function release(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('release', $bounty);

        DB::transaction(function () use ($bounty) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            $lockedBounty->claims()
                ->where('status', 'active')
                ->update([
                    'status' => 'released',
                    'released_at' => now(),
                ]);

            $lockedBounty->update([
                'assignee_id' => null,
                'status' => 'open',
                'claimed_at' => null,
            ]);
        });

        return response()->json([
            'message' => 'Quest abandoned and returned to the board.',
            'data' => new BountyResource($bounty->fresh()->load(['creator', 'household'])),
        ]);
    }

    public function submit(SubmitBountyRequest $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('submit', $bounty);

        $user = $request->user();
        $proof = $request->validated('submission_proof')
            ?? $request->validated('proof_url')
            ?? $request->validated('note')
            ?? 'Chore completed';

        DB::transaction(function () use ($user, $bounty, $proof) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            $lockedBounty->update([
                'submission_proof' => $proof,
                'status' => 'submitted',
                'submitted_at' => now(),
            ]);

            // Synchronize with bounty_completions
            $activeClaim = $lockedBounty->claims()->where('user_id', $user->id)->where('status', 'active')->first();
            if ($activeClaim) {
                $activeClaim->completions()->create([
                    'submission_note' => $proof,
                    'status' => 'pending',
                    'submitted_at' => now(),
                ]);
            }
        });

        return response()->json([
            'message' => 'Completion proof submitted for roommate verification.',
            'data' => new BountyResource($bounty->fresh()->load(['creator', 'assignee', 'household'])),
        ]);
    }

    public function complete(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('complete', $bounty);

        $user = $request->user();

        DB::transaction(function () use ($user, $bounty) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            // If creator completes/verifies or assignee directly completes
            $assigneeId = $lockedBounty->assignee_id ?? $user->id;

            $lockedBounty->update([
                'assignee_id' => $assigneeId,
                'status' => 'completed',
                'completed_at' => now(),
            ]);

            $activeClaim = $lockedBounty->claims()->where('status', 'active')->first();
            if ($activeClaim) {
                $activeClaim->update(['status' => 'completed']);
                $completion = $activeClaim->completions()->where('status', 'pending')->first();
                if ($completion) {
                    $completion->update([
                        'status' => 'approved',
                        'reviewed_by' => $user->id,
                        'reviewed_at' => now(),
                    ]);
                }
            }
        });

        return response()->json([
            'message' => 'Bounty marked as completed! Points disbursed.',
            'data' => new BountyResource($bounty->fresh()->load(['creator', 'assignee', 'household'])),
        ]);
    }

    public function verify(ReviewBountyRequest $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('verify', $bounty);

        $user = $request->user();

        DB::transaction(function () use ($user, $bounty) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            $lockedBounty->update([
                'status' => 'completed',
                'completed_at' => now(),
            ]);

            $activeClaim = $lockedBounty->claims()->where('status', 'active')->first();
            if ($activeClaim) {
                $activeClaim->update(['status' => 'completed']);
                $completion = $activeClaim->completions()->where('status', 'pending')->first();
                if ($completion) {
                    $completion->update([
                        'status' => 'approved',
                        'reviewed_by' => $user->id,
                        'reviewed_at' => now(),
                    ]);
                }
            }
        });

        return response()->json([
            'message' => 'Bounty approved! Reward and XP disbursed to assignee.',
            'data' => new BountyResource($bounty->fresh()->load(['creator', 'assignee', 'household'])),
        ]);
    }

    public function reject(ReviewBountyRequest $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('verify', $bounty);

        $user = $request->user();

        DB::transaction(function () use ($user, $bounty) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            $lockedBounty->update([
                'status' => 'claimed',
                'submitted_at' => null,
            ]);

            $activeClaim = $lockedBounty->claims()->where('status', 'active')->first();
            if ($activeClaim) {
                $completion = $activeClaim->completions()->where('status', 'pending')->first();
                if ($completion) {
                    $completion->update([
                        'status' => 'rejected',
                        'reviewed_by' => $user->id,
                        'reviewed_at' => now(),
                    ]);
                }
            }
        });

        return response()->json([
            'message' => 'Proof was not approved. Task returned to in-progress.',
            'data' => new BountyResource($bounty->fresh()->load(['creator', 'assignee', 'household'])),
        ]);
    }

    public function cancel(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('cancel', $bounty);

        $bounty->update(['status' => 'cancelled']);

        return response()->json([
            'message' => 'Bounty cancelled.',
            'data' => new BountyResource($bounty->fresh()->load(['creator', 'household'])),
        ]);
    }
}
