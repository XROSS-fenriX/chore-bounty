<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Resources\BountyCompletionResource;
use App\Models\BountyClaim;
use App\Models\BountyCompletion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class BountyCompletionController extends Controller
{
    public function index(Request $request)
    {
        $completions = BountyCompletion::query()
            ->whereHas('claim.bounty.household.members', function ($query) use ($request) {
                $query->where('users.id', $request->user()->id);
            })
            ->with(['claim.bounty', 'claim.user', 'reviewer'])
            ->latest()
            ->paginate(15);

        return BountyCompletionResource::collection($completions);
    }

    public function store(Request $request, BountyClaim $bountyClaim)
    {
        abort_unless(
            $bountyClaim->user_id === $request->user()->id,
            403,
            'Only the claimant can submit completion.'
        );

        $validated = $request->validate([
            'submission_note' => ['nullable', 'string'],
            'proof_url' => ['nullable', 'url', 'max:2048'],
        ]);

        $completion = DB::transaction(function () use (
            $bountyClaim,
            $validated
        ) {
            $claim = BountyClaim::whereKey($bountyClaim->id)
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless(
                $claim->status === 'active',
                422,
                'Only active claims can be submitted.'
            );

            if ($claim->completions()->whereIn('status', [
                'pending',
                'approved',
            ])->exists()) {
                abort(422, 'A completion has already been submitted.');
            }

            return $claim->completions()->create([
                ...$validated,
                'status' => 'pending',
                'submitted_at' => now(),
            ]);
        });

        return (new BountyCompletionResource(
            $completion->load('claim')
        ))->response()->setStatusCode(201);
    }

    public function show(BountyCompletion $bountyCompletion)
    {
        // $this->authorize(
        //     'view',
        //     $bountyCompletion->claim->bounty->household
        // );

        return new BountyCompletionResource(
            $bountyCompletion->load([
                'claim.bounty',
                'claim.user',
                'reviewer',
                'redemption',
            ])
        );
    }

    public function update(
        Request $request,
        BountyCompletion $bountyCompletion
    ) {
        // $this->authorize(
        //     'review',
        //     $bountyCompletion->claim->bounty
        // );

        $validated = $request->validate([
            'status' => [
                'required',
                Rule::in(['approved', 'rejected']),
            ],
        ]);

        abort_unless(
            $bountyCompletion->status === 'pending',
            422,
            'Only pending submissions can be reviewed.'
        );

        DB::transaction(function () use (
            $request,
            $bountyCompletion,
            $validated
        ) {
            $completion = BountyCompletion::whereKey($bountyCompletion->id)
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless(
                $completion->status === 'pending',
                422,
                'This submission has already been reviewed.'
            );

            $completion->update([
                'status' => $validated['status'],
                'reviewed_by' => $request->user()->id,
                'reviewed_at' => now(),
            ]);

            $claim = $completion->claim;
            $bounty = $claim->bounty;

            if ($validated['status'] === 'approved') {
                $claim->update(['status' => 'completed']);
                $bounty->update(['status' => 'completed']);
            } else {
                $bounty->update(['status' => 'open']);
                $claim->update([
                    'status' => 'released',
                    'released_at' => now(),
                ]);
            }
        });

        return new BountyCompletionResource(
            $bountyCompletion->fresh()->load([
                'claim.bounty',
                'claim.user',
                'reviewer',
            ])
        );
    }
}
