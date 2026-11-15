<?php

namespace App\Http\Controllers;

use App\Http\Requests\ReviewBountyRequest;
use App\Http\Requests\SubmitBountyRequest;
use App\Http\Resources\BountyResource;
use App\Models\Bounty;
use App\Models\BountyNotification;
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

            if (! $lockedBounty->isAvailable() || $lockedBounty->claims()->where('status', 'active')->exists()) {
                abort(422, 'This bounty is no longer available for claiming.');
            }

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

        $fresh = $bounty->fresh()->load(['creator', 'assignee', 'household']);
        BountyNotification::dispatchForHousehold(
            $fresh,
            $user,
            'claimed',
            'Chore Claimed',
            "{$user->name} claimed \"{$fresh->title}\"."
        );

        return response()->json([
            'message' => 'Quest accepted! Best of luck, adventurer.',
            'data' => new BountyResource($fresh),
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

        $fresh = $bounty->fresh()->load(['creator', 'assignee', 'household']);
        BountyNotification::dispatchToUser(
            $fresh,
            $user,
            (int) $fresh->created_by,
            'submitted',
            'Chore Submitted',
            "{$user->name} submitted \"{$fresh->title}\" for approval."
        );

        return response()->json([
            'message' => 'Completion proof submitted for roommate verification.',
            'data' => new BountyResource($fresh),
        ]);
    }

    public function complete(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('complete', $bounty);

        return $this->approve(
            $request,
            $bounty,
            assignActorIfMissing: true,
            message: 'Bounty marked as completed! Points disbursed.'
        );
    }

    public function verify(ReviewBountyRequest $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('verify', $bounty);

        return $this->approve(
            $request,
            $bounty,
            assignActorIfMissing: false,
            message: 'Bounty approved! Tokens disbursed to assignee.'
        );
    }

    private function approve(
        Request $request,
        Bounty $bounty,
        bool $assignActorIfMissing,
        string $message
    ): JsonResponse {
        $user = $request->user();

        DB::transaction(function () use ($user, $bounty, $assignActorIfMissing) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            if ($lockedBounty->status === 'completed') {
                abort(422, 'This bounty has already been completed.');
            }

            $updates = [
                'status' => 'completed',
                'completed_at' => now(),
            ];
            if ($assignActorIfMissing) {
                $updates['assignee_id'] = $lockedBounty->assignee_id ?? $user->id;
            }

            $lockedBounty->update($updates);

            $this->finalizeCompletion($lockedBounty, $user->id);
        });

        $fresh = $bounty->fresh()->load(['creator', 'assignee', 'household']);
        $tokens = $fresh->tokens();
        $assigneeId = (int) ($fresh->assignee_id ?? 0);
        $assigneeName = $fresh->assignee?->name ?? 'Roommate';

        if ($assigneeId > 0 && $assigneeId !== (int) $user->id) {
            BountyNotification::dispatchToUser(
                $fresh,
                $user,
                $assigneeId,
                'approved',
                'Chore Approved!',
                "{$user->name} approved \"{$fresh->title}\" (+{$tokens} Tokens)."
            );
        }

        BountyNotification::dispatchForHousehold(
            $fresh,
            $user,
            'awarded',
            'Bounty Awarded',
            "{$user->name} awarded {$tokens} Tokens to {$assigneeName} for \"{$fresh->title}\".",
            $assigneeId > 0 ? [$assigneeId] : []
        );

        return response()->json([
            'message' => $message,
            'data' => new BountyResource($fresh),
        ]);
    }

    private function finalizeCompletion(Bounty $lockedBounty, int $reviewerId): void
    {
        $activeClaim = $lockedBounty->claims()->where('status', 'active')->first();
        if (! $activeClaim) {
            return;
        }

        $activeClaim->update(['status' => 'completed']);
        $completion = $activeClaim->completions()->where('status', 'pending')->first();
        if (! $completion) {
            return;
        }

        $completion->update([
            'status' => 'approved',
            'reviewed_by' => $reviewerId,
            'reviewed_at' => now(),
        ]);

        $completion->redemption()->firstOrCreate(
            ['bounty_completion_id' => $completion->id],
            [
                'redeemed_by' => $activeClaim->user_id,
                'status' => 'unredeemed',
            ]
        );
    }

    public function reject(ReviewBountyRequest $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('verify', $bounty);

        $user = $request->user();
        $feedback = trim((string) ($request->validated('feedback') ?? ''));

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

        $fresh = $bounty->fresh()->load(['creator', 'assignee', 'household']);
        if ($fresh->assignee_id) {
            $description = $feedback !== ''
                ? "{$user->name} requested a redo on \"{$fresh->title}\": {$feedback}"
                : "{$user->name} requested a redo on \"{$fresh->title}\".";

            BountyNotification::dispatchToUser(
                $fresh,
                $user,
                (int) $fresh->assignee_id,
                'redo',
                'Redo Requested',
                $description
            );
        }

        return response()->json([
            'message' => 'Proof was not approved. Task returned to in-progress.',
            'data' => new BountyResource($fresh),
        ]);
    }

    public function cancel(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('cancel', $bounty);

        $user = $request->user();

        DB::transaction(function () use ($bounty, $user) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            $lockedBounty->claims()
                ->where('status', 'active')
                ->get()
                ->each(function ($claim) use ($user) {
                    $claim->completions()
                        ->where('status', 'pending')
                        ->update([
                            'status' => 'rejected',
                            'reviewed_by' => $user->id,
                            'reviewed_at' => now(),
                        ]);

                    $claim->update([
                        'status' => 'released',
                        'released_at' => now(),
                    ]);
                });

            $lockedBounty->update(['status' => 'cancelled']);
        });

        $fresh = $bounty->fresh()->load(['creator', 'assignee', 'household']);
        BountyNotification::dispatchForHousehold(
            $fresh,
            $user,
            'cancelled',
            'Chore Cancelled',
            "{$user->name} cancelled \"{$fresh->title}\"."
        );

        return response()->json([
            'message' => 'Bounty cancelled.',
            'data' => new BountyResource($fresh),
        ]);
    }
}
