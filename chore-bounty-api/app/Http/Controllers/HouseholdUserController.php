<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Resources\HouseholdUserResource;
use App\Models\Household;
use App\Models\HouseholdUser;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HouseholdUserController extends Controller
{
    public function index(Household $household)
    {
        // $this->authorize('view', $household);

        return HouseholdUserResource::collection(
            $household->memberships()->with('user')->paginate(20)
        );
    }

    public function store(Request $request, Household $household)
    {
        // $this->authorize('manageMembers', $household);

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
        // $this->authorize('manageMembers', $household);

        $membership = $household->memberships()
            ->where('user_id', $user->id)
            ->firstOrFail();

        abort_if(
            $membership->role === 'owner',
            422,
            'Transfer ownership before removing the household owner.'
        );

        $membership->delete();

        return response()->noContent();
    }
}
