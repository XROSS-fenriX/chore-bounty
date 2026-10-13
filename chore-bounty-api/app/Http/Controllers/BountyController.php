<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Resources\BountyResource;
use App\Models\Bounty;
use App\Models\Household;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BountyController extends Controller
{
    public function index(Request $request)
    {
        $query = Bounty::query()
            ->whereHas('household.members', function ($q) use ($request) {
                $q->where('users.id', $request->user()->id);
            })
            ->with(['creator', 'activeClaim.user'])
            ->latest();

        if ($request->filled('household_id')) {
            $query->where('household_id', $request->integer('household_id'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        return BountyResource::collection($query->paginate(15));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'household_id' => ['required', 'exists:households,id'],
            'title' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string'],
            'difficulty' => [
                'required',
                Rule::in(['easy', 'medium', 'hard']),
            ],
            'reward_value' => ['nullable', 'numeric', 'min:0'],
            'reward_description' => ['required', 'string', 'max:255'],
            'due_at' => ['nullable', 'date', 'after:now'],
        ]);

        $household = Household::findOrFail($validated['household_id']);

        // $this->authorize('view', $household);

        $bounty = $household->bounties()->create([
            ...$validated,
            'created_by' => $request->user()->id,
            'status' => 'open',
        ]);

        return (new BountyResource($bounty->load('creator', 'household')))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Bounty $bounty)
    {
        // $this->authorize('view', $bounty->household);

        return new BountyResource(
            $bounty->load([
                'creator',
                'household',
                'claims.user',
                'claims.completions',
            ])
        );
    }

    public function update(Request $request, Bounty $bounty)
    {
        // $this->authorize('update', $bounty);

        abort_unless(
            $bounty->status === 'open',
            422,
            'Only open bounties can be edited.'
        );

        $validated = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:150'],
            'description' => ['sometimes', 'nullable', 'string'],
            'difficulty' => [
                'sometimes',
                'required',
                Rule::in(['easy', 'medium', 'hard']),
            ],
            'reward_value' => ['sometimes', 'nullable', 'numeric', 'min:0'],
            'reward_description' => [
                'sometimes',
                'required',
                'string',
                'max:255',
            ],
            'due_at' => ['sometimes', 'nullable', 'date', 'after:now'],
        ]);

        $bounty->update($validated);

        return new BountyResource($bounty->fresh()->load('creator'));
    }

    public function destroy(Bounty $bounty)
    {
        // $this->authorize('delete', $bounty);

        abort_unless(
            $bounty->status === 'open',
            422,
            'Only open bounties can be deleted.'
        );

        $bounty->delete();

        return response()->noContent();
    }
}
