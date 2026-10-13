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
}
