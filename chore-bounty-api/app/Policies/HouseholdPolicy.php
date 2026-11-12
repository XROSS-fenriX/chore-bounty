<?php

namespace App\Policies;

use App\Models\Household;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class HouseholdPolicy
{
    public function view(User $actor, Household $household): Response
    {
        return $household->members()->where('users.id', $actor->id)->exists()
            ? Response::allow()
            : Response::deny('You are not a member of this household.');
    }

    public function manageMembers(User $actor, Household $household): Response
    {
        if ($household->created_by === $actor->id) {
            return Response::allow();
        }

        $isOwner = $household->memberships()
            ->where('user_id', $actor->id)
            ->whereIn('role', ['owner', 'admin'])
            ->exists();

        return $isOwner
            ? Response::allow()
            : Response::deny('Only the household owner can manage household settings or members.');
    }

    public function update(User $actor, Household $household): Response
    {
        return $this->manageMembers($actor, $household);
    }

    public function delete(User $actor, Household $household): Response
    {
        return $household->created_by === $actor->id
            ? Response::allow()
            : Response::deny('Only the household creator can delete this household.');
    }
}

