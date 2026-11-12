<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\Response;

class UserPolicy
{
    public function view(User $actor, User $target): Response
    {
        if ($actor->id === $target->id) {
            return Response::allow();
        }

        $sharesHousehold = $actor->households()
            ->whereHas('members', fn ($query) => $query->where('users.id', $target->id))
            ->exists();

        return $sharesHousehold
            ? Response::allow()
            : Response::deny('You do not share a household with this user.');
    }

    public function update(User $actor, User $target): Response
    {
        return $actor->id === $target->id
            ? Response::allow()
            : Response::deny('You can only update your own profile.');
    }
}

