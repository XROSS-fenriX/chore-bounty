<?php

namespace App\Policies;

use App\Models\Bounty;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class BountyPolicy
{
    private function isHouseholdMember(User $user, int $householdId): bool
    {
        return $user->households()->where('households.id', $householdId)->exists();
    }

    public function viewAny(User $user): Response
    {
        return Response::allow();
    }

    public function view(User $user, Bounty $bounty): Response
    {
        return $this->isHouseholdMember($user, $bounty->household_id)
            ? Response::allow()
            : Response::deny('You are not a member of this household.');
    }

    public function create(User $user, int $householdId): Response
    {
        return $this->isHouseholdMember($user, $householdId)
            ? Response::allow()
            : Response::deny('You must belong to this household to create bounties.');
    }

    public function update(User $user, Bounty $bounty): Response
    {
        if ($bounty->created_by !== $user->id) {
            return Response::deny('Only the bounty creator can update this quest.');
        }

        if ($bounty->status !== 'open') {
            return Response::deny('Cannot edit a bounty that is already in progress or completed.');
        }

        return Response::allow();
    }

    public function delete(User $user, Bounty $bounty): Response
    {
        return ($bounty->created_by === $user->id && $bounty->status === 'open')
            ? Response::allow()
            : Response::deny('Only open bounties can be deleted by their creator.');
    }

    public function claim(User $user, Bounty $bounty): Response
    {
        if (! $this->isHouseholdMember($user, $bounty->household_id)) {
            return Response::deny('You must be a roommate in this household to claim this bounty.');
        }

        if ($bounty->created_by === $user->id) {
            return Response::deny('You cannot claim your own bounty.');
        }

        if ($bounty->status !== 'open') {
            return Response::deny('This bounty is no longer available for claiming.');
        }

        return Response::allow();
    }

    public function release(User $user, Bounty $bounty): Response
    {
        $isAssignee = ($bounty->assignee_id === $user->id) ||
                      $bounty->claims()->where('user_id', $user->id)->where('status', 'active')->exists();

        return $isAssignee && in_array($bounty->status, ['claimed', 'in_progress'])
            ? Response::allow()
            : Response::deny('Only the assigned roommate can forfeit this quest.');
    }

    public function submit(User $user, Bounty $bounty): Response
    {
        $isAssignee = ($bounty->assignee_id === $user->id) ||
                      $bounty->claims()->where('user_id', $user->id)->where('status', 'active')->exists();

        return $isAssignee && in_array($bounty->status, ['claimed', 'in_progress'])
            ? Response::allow()
            : Response::deny('Only the active assignee can submit completion proof.');
    }

    public function complete(User $user, Bounty $bounty): Response
    {
        if ($bounty->created_by !== $user->id) {
            return Response::deny('Only the bounty creator can mark this bounty completed without review.');
        }

        if (! in_array($bounty->status, ['claimed', 'in_progress', 'submitted'])) {
            return Response::deny('This bounty cannot be marked completed from its current status.');
        }

        return Response::allow();
    }

    public function verify(User $user, Bounty $bounty): Response
    {
        if ($bounty->created_by !== $user->id) {
            return Response::deny('Only the creator can verify quest completion.');
        }

        if (! in_array($bounty->status, ['submitted', 'claimed', 'in_progress'])) {
            return Response::deny('Bounty must be in progress or submitted for review before verification.');
        }

        return Response::allow();
    }

    public function cancel(User $user, Bounty $bounty): Response
    {
        return $bounty->created_by === $user->id && in_array($bounty->status, ['open', 'claimed', 'in_progress'])
            ? Response::allow()
            : Response::deny('Only the quest creator can cancel active bounties.');
    }
}
