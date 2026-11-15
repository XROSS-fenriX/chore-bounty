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
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;

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
        $rawProof = $request->validated('submission_proof')
            ?? $request->validated('proof_url')
            ?? $request->validated('note');
        $trimmedProof = is_string($rawProof) ? trim($rawProof) : '';

        $uploadedFiles = $request->file('proof_images', []);
        $storedUrls = [];
        $storedDiskPaths = [];

        foreach ($uploadedFiles as $file) {
            $diskPath = Storage::disk('public')->putFile(
                "bounty-proofs/{$bounty->household_id}/{$bounty->id}",
                $file
            );
            if ($diskPath !== false) {
                $storedDiskPaths[] = $diskPath;
                $storedUrls[] = '/storage/'.ltrim($diskPath, '/');
            }
        }

        $proof = $trimmedProof !== ''
            ? $trimmedProof
            : (! empty($storedUrls) ? 'Photo proof submitted' : 'Chore completed');

        $previousImages = $bounty->submission_images;

        try {
            DB::transaction(function () use ($user, $bounty, $proof, $storedUrls, $request) {
                $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

                $lockedBounty->update([
                    'submission_proof' => $proof,
                    'submission_images' => ! empty($storedUrls) ? $storedUrls : null,
                    'status' => 'submitted',
                    'submitted_at' => now(),
                ]);

                // Synchronize with bounty_completions
                $activeClaim = $lockedBounty->claims()->where('user_id', $user->id)->where('status', 'active')->first();
                if ($activeClaim) {
                    $activeClaim->completions()->create([
                        'submission_note' => $proof,
                        'proof_url' => $storedUrls[0] ?? $request->validated('proof_url'),
                        'proof_images' => ! empty($storedUrls) ? $storedUrls : null,
                        'status' => 'pending',
                        'submitted_at' => now(),
                    ]);
                }
            });
        } catch (\Throwable $e) {
            if (! empty($storedDiskPaths)) {
                Storage::disk('public')->delete($storedDiskPaths);
            }
            throw $e;
        }

        $this->deleteStoredProofImages(is_array($previousImages) ? $previousImages : []);

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

        $previousImages = $bounty->submission_images;

        DB::transaction(function () use ($user, $bounty) {
            $lockedBounty = Bounty::whereKey($bounty->id)->lockForUpdate()->firstOrFail();

            $lockedBounty->update([
                'status' => 'claimed',
                'submitted_at' => null,
                'submission_proof' => null,
                'submission_images' => null,
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

        $this->deleteStoredProofImages(is_array($previousImages) ? $previousImages : []);

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

    /**
     * Serve an uploaded proof image with optional HTTP byte-range chunking.
     */
    public function serveProofImage(
        Request $request,
        int $householdId,
        int $bountyId,
        string $filename,
    ): Response {
        if ($filename === '' || str_contains($filename, '..')) {
            abort(404);
        }

        $relativePath = "bounty-proofs/{$householdId}/{$bountyId}/{$filename}";
        $disk = Storage::disk('public');
        if (! $disk->exists($relativePath)) {
            abort(404);
        }

        $size = (int) $disk->size($relativePath);
        $mime = $disk->mimeType($relativePath) ?: 'image/jpeg';
        $rangeHeader = trim((string) $request->header('Range', ''));

        $headers = [
            'Content-Type' => $mime,
            'Accept-Ranges' => 'bytes',
            'Cache-Control' => 'public, max-age=86400',
        ];

        if ($size > 0 && preg_match('/^bytes=(\d*)-(\d*)$/i', $rangeHeader, $matches)) {
            $start = $matches[1] !== '' ? (int) $matches[1] : 0;
            $end = $matches[2] !== '' ? min((int) $matches[2], $size - 1) : ($size - 1);

            if ($start > $end || $start >= $size) {
                return response('', 416, [
                    'Content-Range' => "bytes */{$size}",
                ]);
            }

            $length = $end - $start + 1;
            $stream = $disk->readStream($relativePath);
            if ($stream === false) {
                abort(404);
            }

            try {
                if ($start > 0) {
                    fseek($stream, $start);
                }
                $slice = '';
                $remaining = $length;
                while ($remaining > 0 && ! feof($stream)) {
                    $chunk = fread($stream, $remaining);
                    if ($chunk === false || $chunk === '') {
                        break;
                    }
                    $slice .= $chunk;
                    $remaining -= strlen($chunk);
                }
            } finally {
                fclose($stream);
            }

            return response($slice, 206, array_merge($headers, [
                'Content-Range' => "bytes {$start}-{$end}/{$size}",
                'Content-Length' => (string) strlen($slice),
            ]));
        }

        $content = (string) $disk->get($relativePath);

        return response($content, 200, array_merge($headers, [
            'Content-Length' => (string) strlen($content),
        ]));
    }

    /**
     * Remove stored public disk files referenced by /storage/... paths.
     */
    private function deleteStoredProofImages(array $paths): void
    {
        $diskPaths = [];
        foreach ($paths as $path) {
            if (! is_string($path)) {
                continue;
            }
            $relative = ltrim(preg_replace('#^/storage/#', '', trim($path)) ?? '', '/');
            if ($relative !== '' && ! str_contains($relative, '://')) {
                $diskPaths[] = $relative;
            }
        }

        if (! empty($diskPaths)) {
            Storage::disk('public')->delete($diskPaths);
        }
    }
}
