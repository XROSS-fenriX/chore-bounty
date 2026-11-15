<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Household extends Model
{
    protected $fillable = [
        'created_by',
        'name',
        'invite_code',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function members(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'household_user')
            ->using(HouseholdUser::class)
            ->withPivot(['id', 'role', 'joined_at'])
            ->withTimestamps();
    }

    public function memberships(): HasMany
    {
        return $this->hasMany(HouseholdUser::class);
    }

    public function bounties(): HasMany
    {
        return $this->hasMany(Bounty::class);
    }

    /**
     * Release all active claims, reject pending completions, and clean up proof
     * files for assignments held by a departing or removed household member.
     */
    public function releaseMemberAssignments(int $userId): void
    {
        BountyClaim::query()
            ->where('user_id', $userId)
            ->where('status', 'active')
            ->whereHas('bounty', fn ($q) => $q->where('household_id', $this->id))
            ->get()
            ->each(function (BountyClaim $claim) {
                $claim->completions()
                    ->where('status', 'pending')
                    ->update([
                        'status' => 'rejected',
                        'reviewed_at' => now(),
                    ]);

                $claim->update([
                    'status' => 'released',
                    'released_at' => now(),
                ]);
            });

        $this->bounties()
            ->where('assignee_id', $userId)
            ->whereIn('status', ['claimed', 'in_progress', 'submitted'])
            ->get()
            ->each(function (Bounty $bounty) {
                if (is_array($bounty->submission_images) && ! empty($bounty->submission_images)) {
                    Bounty::removeStoredProofPaths($bounty->submission_images);
                }

                $bounty->update([
                    'status' => 'open',
                    'assignee_id' => null,
                    'claimed_at' => null,
                    'submitted_at' => null,
                    'submission_proof' => null,
                    'submission_images' => null,
                ]);
            });
    }
}
