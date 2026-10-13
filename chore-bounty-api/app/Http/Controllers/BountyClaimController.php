<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Resources\BountyClaimResource;
use App\Models\Bounty;
use App\Models\BountyClaim;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class BountyClaimController extends Controller
{
    public function index(Request $request)
    {
        $claims = BountyClaim::query()
            ->where('user_id', $request->user()->id)
            ->with(['bounty', 'completions'])
            ->latest()
            ->paginate(15);

        return BountyClaimResource::collection($claims);
    }

    public function store(Request $request, Bounty $bounty)
    {
        // $this->authorize('view', $bounty->household);

        $claim = DB::transaction(function () use ($request, $bounty) {
            $lockedBounty = Bounty::whereKey($bounty->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($lockedBounty->status !== 'open') {
                throw ValidationException::withMessages([
                    'bounty' => 'This bounty is no longer available.',
                ]);
            }

            $user = $request->user();

            abort_unless(
                $lockedBounty->household->members()
                    ->where('users.id', $user->id)
                    ->exists(),
                403,
                'You are not a member of this household.'
            );

            $claim = $lockedBounty->claims()->create([
                'user_id' => $user->id,
                'status' => 'active',
                'claimed_at' => now(),
            ]);

            $lockedBounty->update(['status' => 'in_progress']);

            return $claim;
        });

        return (new BountyClaimResource(
            $claim->load(['bounty', 'user'])
        ))->response()->setStatusCode(201);
    }

    public function show(BountyClaim $bountyClaim)
    {
        // $this->authorize('view', $bountyClaim->bounty->household);

        return new BountyClaimResource(
            $bountyClaim->load(['bounty', 'user', 'completions'])
        );
    }

    public function destroy(BountyClaim $bountyClaim)
    {
        // $this->authorize('release', $bountyClaim);

        DB::transaction(function () use ($bountyClaim) {
            $claim = BountyClaim::whereKey($bountyClaim->id)
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless(
                $claim->status === 'active',
                422,
                'This claim is no longer active.'
            );

            $claim->update([
                'status' => 'released',
                'released_at' => now(),
            ]);

            $claim->bounty()->update(['status' => 'open']);
        });

        return response()->noContent();
    }
}
