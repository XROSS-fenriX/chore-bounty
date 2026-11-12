<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['first_name', 'middle_name', 'last_name', 'name', 'gender', 'email', 'password', 'avatar'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    public const GENDERS = ['male', 'female', 'non_binary', 'prefer_not_to_say'];

    public static function splitFullName(?string $fullName): array
    {
        $trimmed = trim(preg_replace('/\s+/', ' ', (string) $fullName));
        if ($trimmed === '') {
            return ['first_name' => '', 'middle_name' => null, 'last_name' => ''];
        }

        $parts = explode(' ', $trimmed);
        if (count($parts) === 1) {
            return ['first_name' => $parts[0], 'middle_name' => null, 'last_name' => ''];
        }
        if (count($parts) === 2) {
            return ['first_name' => $parts[0], 'middle_name' => null, 'last_name' => $parts[1]];
        }

        $first = array_shift($parts);
        $last = array_pop($parts);

        return [
            'first_name' => $first,
            'middle_name' => implode(' ', $parts),
            'last_name' => $last,
        ];
    }

    protected function name(): Attribute
    {
        return Attribute::make(
            get: function ($value, array $attributes) {
                $parts = array_filter([
                    $attributes['first_name'] ?? null,
                    $attributes['middle_name'] ?? null,
                    $attributes['last_name'] ?? null,
                ], fn ($part) => is_string($part) && trim($part) !== '');

                return trim(implode(' ', $parts));
            },
            set: fn (?string $value) => self::splitFullName($value),
        );
    }

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

    public function assignedBounties(): HasMany
    {
        return $this->hasMany(Bounty::class, 'assignee_id');
    }

    public function completedBounties(): HasMany
    {
        return $this->hasMany(Bounty::class, 'assignee_id')
            ->where('status', 'completed');
    }
}
