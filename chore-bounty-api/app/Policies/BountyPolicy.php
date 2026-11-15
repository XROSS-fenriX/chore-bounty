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
        return Bounty::query()->whereKey($bounty->id)->visibleToUser($user)->exists()
            ? Response::allow()
            : Response::deny('You do not have permission to view this chore.');
    }

    public function create(User $user, int $householdId): Response
    {
        return $this->isHouseholdMember($user, $householdId)
            ? Response::allow()
            : Response::deny('You must belong to this household to create bounties.');
    }

    public function update(User $user, Bounty $bounty): Response
    {
        if (! $this->isHouseholdMember($user, (int) $bounty->household_id)) {
            return Response::deny('You must belong to this household to update this chore.');
        }

        if ($bounty->created_by !== $user->id) {
            return Response::deny('Only the bounty creator can update this quest.');
        }

        if (! ($bounty->isAvailable() || $bounty->isTaken())) {
            return Response::deny('Chores can only be edited when available or taken.');
        }

        return Response::allow();
    }

    public function delete(User $user, Bounty $bounty): Response
    {
        if (! $this->isHouseholdMember($user, (int) $bounty->household_id)) {
            return Response::deny('You must belong to this household to delete this chore.');
        }

        $canDelete = $bounty->isAvailable() || $bounty->isCancelled() || $bounty->isExpired();

        return ($bounty->created_by === $user->id && $canDelete)
            ? Response::allow()
            : Response::deny('Chores can only be deleted by their creator when available, cancelled, or expired.');
    }

    public function claim(User $user, Bounty $bounty): Response
    {
        if (! $this->isHouseholdMember($user, $bounty->household_id)) {
            return Response::deny('You must be a roommate in this household to claim this bounty.');
        }

        if ($bounty->created_by === $user->id) {
            return Response::deny('You cannot claim your own bounty.');
        }

        if (! $bounty->isAvailable()) {
            return Response::deny('This bounty is no longer available for claiming.');
        }

        return Response::allow();
    }

    public function release(User $user, Bounty $bounty): Response
    {
        if (! $this->isHouseholdMember($user, (int) $bounty->household_id)) {
            return Response::deny('You must belong to this household to release this chore.');
        }

        $isAssignee = ($bounty->assignee_id === $user->id) ||
                      $bounty->claims()->where('user_id', $user->id)->where('status', 'active')->exists();

        return $isAssignee && in_array($bounty->status, ['claimed', 'in_progress'])
            ? Response::allow()
            : Response::deny('Only the assigned roommate can forfeit this quest.');
    }

    public function submit(User $user, Bounty $bounty): Response
    {
        if (! $this->isHouseholdMember($user, (int) $bounty->household_id)) {
            return Response::deny('You must belong to this household to submit completion proof.');
        }

        $isAssignee = ($bounty->assignee_id === $user->id) ||
                      $bounty->claims()->where('user_id', $user->id)->where('status', 'active')->exists();

        return $isAssignee && in_array($bounty->status, ['claimed', 'in_progress'])
            ? Response::allow()
            : Response::deny('Only the active assignee can submit completion proof.');
    }

    public function complete(User $user, Bounty $bounty): Response
    {
        if (! $this->isHouseholdMember($user, (int) $bounty->household_id)) {
            return Response::deny('You must belong to this household to complete this chore.');
        }

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
        if (! $this->isHouseholdMember($user, (int) $bounty->household_id)) {
            return Response::deny('You must belong to this household to review this chore.');
        }

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
        if (! $this->isHouseholdMember($user, (int) $bounty->household_id)) {
            return Response::deny('You must belong to this household to cancel this chore.');
        }

        return $bounty->created_by === $user->id && ($bounty->isAvailable() || $bounty->isTaken())
            ? Response::allow()
            : Response::deny('Only the quest creator can cancel active bounties.');
    }
}
