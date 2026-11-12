<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Resources\RewardRedemptionResource;
use App\Models\BountyCompletion;
use App\Models\RewardRedemption;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RewardRedemptionController extends Controller
{
    public function index(Request $request)
    {
        $redemptions = RewardRedemption::query()
            ->where('redeemed_by', $request->user()->id)
            ->with(['completion'])
            ->latest()
            ->paginate(15);

        return RewardRedemptionResource::collection($redemptions);
    }

    public function store(
        Request $request,
        BountyCompletion $bountyCompletion
    ) {
        abort_unless(
            $bountyCompletion->claim->user_id === $request->user()->id,
            403,
            'Only the person who completed the bounty can redeem its reward.'
        );

        $redemption = DB::transaction(function () use (
            $request,
            $bountyCompletion
        ) {
            $completion = BountyCompletion::whereKey($bountyCompletion->id)
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless(
                $completion->status === 'approved',
                422,
                'Only approved completions can earn rewards.'
            );

            abort_if(
                $completion->redemption()->exists(),
                409,
                'A redemption record already exists.'
            );

            return $completion->redemption()->create([
                'redeemed_by' => $request->user()->id,
                'status' => 'unredeemed',
            ]);
        });

        return (new RewardRedemptionResource($redemption))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, RewardRedemption $rewardRedemption)
    {
        abort_unless(
            $rewardRedemption->redeemed_by === $request->user()->id
                || $rewardRedemption->completion?->claim?->bounty?->created_by === $request->user()->id,
            403,
            'You cannot access this redemption.'
        );

        return new RewardRedemptionResource(
            $rewardRedemption->load('completion')
        );
    }

    public function update(
        Request $request,
        RewardRedemption $rewardRedemption
    ) {
        abort_unless(
            $rewardRedemption->redeemed_by === $request->user()->id,
            403,
            'Only the earner can redeem this reward.'
        );

        abort_unless(
            $rewardRedemption->status === 'unredeemed',
            422,
            'This reward is not available for redemption.'
        );

        $rewardRedemption->update([
            'status' => 'redeemed',
            'redeemed_at' => now(),
        ]);

        return new RewardRedemptionResource(
            $rewardRedemption->fresh()
        );
    }
}
