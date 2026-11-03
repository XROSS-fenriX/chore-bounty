<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreBountyRequest;
use App\Http\Requests\UpdateBountyRequest;
use App\Http\Resources\BountyResource;
use App\Models\Bounty;
use App\Models\Household;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class BountyController extends Controller
{
    public function index(Request $request)
    {
        $query = Bounty::query()
            ->whereHas('household.members', function ($q) use ($request) {
                $q->where('users.id', $request->user()->id);
            })
            ->with(['creator', 'assignee', 'household', 'activeClaim.user'])
            ->latest();

        $householdId = $request->header('X-Household-Id') ?? $request->query('household_id');
        if ($householdId) {
            $query->where('household_id', (int) $householdId);
        }

        if ($request->filled('status')) {
            $status = $request->input('status');
            if ($status === 'available' || $status === 'open') {
                $query->where('status', 'open');
            } elseif ($status === 'in_progress' || $status === 'claimed') {
                $query->whereIn('status', ['claimed', 'in_progress']);
            } else {
                $query->where('status', $status);
            }
        }

        return BountyResource::collection($query->paginate(20));
    }

    public function store(StoreBountyRequest $request)
    {
        $validated = $request->validated();
        $household = Household::findOrFail($validated['household_id']);

        Gate::authorize('create', [Bounty::class, $household->id]);

        $bounty = $household->bounties()->create([
            ...$validated,
            'created_by' => $request->user()->id,
            'status' => 'open',
        ]);

        return (new BountyResource($bounty->load(['creator', 'assignee', 'household'])))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Bounty $bounty)
    {
        Gate::authorize('view', $bounty);

        return new BountyResource(
            $bounty->load([
                'creator',
                'assignee',
                'household',
                'claims.user',
                'claims.completions',
            ])
        );
    }

    public function update(UpdateBountyRequest $request, Bounty $bounty)
    {
        Gate::authorize('update', $bounty);

        $bounty->update($request->validated());

        return new BountyResource($bounty->fresh()->load(['creator', 'assignee', 'household']));
    }

    public function destroy(Bounty $bounty)
    {
        Gate::authorize('delete', $bounty);

        $bounty->delete();

        return response()->noContent();
    }
}
