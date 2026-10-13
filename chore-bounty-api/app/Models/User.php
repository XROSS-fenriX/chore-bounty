<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
    public function households(): BelongsToMany
    {
        return $this->belongsToMany(
            Household::class,
            'household_user'
        )
            ->using(HouseholdUser::class)
            ->withPivot(['id', 'role', 'joined_at'])
            ->withTimestamps();
    }

    public function memberships(): HasMany
    {
        return $this->hasMany(HouseholdUser::class);
    }

    public function createdBounties(): HasMany
    {
        return $this->hasMany(Bounty::class, 'created_by');
    }

    public function bountyClaims(): HasMany
    {
        return $this->hasMany(BountyClaim::class);
    }

    public function reviewedCompletions(): HasMany
    {
        return $this->hasMany(
            BountyCompletion::class,
            'reviewed_by'
        );
    }

    public function rewardRedemptions(): HasMany
    {
        return $this->hasMany(
            RewardRedemption::class,
            'redeemed_by'
        );
    }
}
