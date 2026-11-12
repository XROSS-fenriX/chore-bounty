<?php

namespace App\Http\Controllers;

use App\Http\Resources\HouseholdUserResource;
use App\Models\Household;
use App\Models\HouseholdUser;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

class HouseholdUserController extends Controller
{
    public function index(Request $request, Household $household)
    {
        abort_unless(
            $household->members()->where('users.id', $request->user()->id)->exists(),
            403,
            'You are not a member of this household.'
        );

        return HouseholdUserResource::collection(
            $household->memberships()
                ->with('user')
                ->orderByRaw("CASE WHEN role = 'owner' THEN 0 ELSE 1 END")
                ->orderBy('joined_at')
                ->paginate(50)
        );
    }

    public function store(Request $request, Household $household)
    {
        Gate::authorize('manageMembers', $household);

        $validated = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'role' => ['sometimes', Rule::in(['owner', 'member'])],
        ]);

        $membership = HouseholdUser::firstOrCreate(
            [
                'household_id' => $household->id,
                'user_id' => $validated['user_id'],
            ],
            [
                'role' => $validated['role'] ?? 'member',
                'joined_at' => now(),
            ]
        );

        return (new HouseholdUserResource($membership->load('user')))
            ->response()
            ->setStatusCode(201);
    }

    public function destroy(Household $household, User $user)
    {
        Gate::authorize('manageMembers', $household);

        $membership = $household->memberships()
            ->where('user_id', $user->id)
            ->firstOrFail();

        abort_if(
            $membership->role === 'owner' || $household->created_by === $user->id,
            422,
            'Transfer ownership before removing the household owner.'
        );

        $membership->delete();

        return response()->noContent();
    }
}
