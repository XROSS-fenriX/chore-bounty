<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

class Bounty extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'household_id',
        'created_by',
        'assignee_id',
        'title',
        'description',
        'difficulty',
        'category',
        'xp_reward',
        'reward_value',
        'reward_description',
        'status',
        'submission_proof',
        'submission_images',
        'claimed_at',
        'submitted_at',
        'completed_at',
        'due_at',
    ];

    protected function casts(): array
    {
        return [
            'reward_value' => 'decimal:2',
            'xp_reward' => 'integer',
            'submission_images' => 'array',
            'claimed_at' => 'datetime',
            'submitted_at' => 'datetime',
            'completed_at' => 'datetime',
            'due_at' => 'datetime',
        ];
    }

    /**
     * Alias creator_id with created_by attribute.
     */
    protected function creatorId(): Attribute
    {
        return Attribute::make(
            get: fn ($value, array $attributes) => $attributes['created_by'] ?? null,
            set: fn ($value) => ['created_by' => $value],
        );
    }

    /**
     * Resolve category name for the bounty.
     */
    protected function category(): Attribute
    {
        return Attribute::make(
            get: function ($value, array $attributes) {
                if (!empty($value)) {
                    return $value;
                }
                $title = strtolower($attributes['title'] ?? '');
                $desc = strtolower($attributes['description'] ?? '');
                $text = $title . ' ' . $desc;
                if (str_contains($text, 'laundry') || str_contains($text, 'clothes') || str_contains($text, 'wash')) {
                    return 'Laundry';
                }
                if (str_contains($text, 'clean') || str_contains($text, 'sweep') || str_contains($text, 'mop') || str_contains($text, 'dust') || str_contains($text, 'vacuum') || str_contains($text, 'trash') || str_contains($text, 'bunnies') || str_contains($text, 'room')) {
                    return 'Cleaning';
                }
                if (str_contains($text, 'kitchen') || str_contains($text, 'dish') || str_contains($text, 'cook') || str_contains($text, 'dishmore') || str_contains($text, 'counter') || str_contains($text, 'pots')) {
                    return 'Kitchen';
                }
                if (str_contains($text, 'grocer') || str_contains($text, 'shop') || str_contains($text, 'dinner') || str_contains($text, 'beans') || str_contains($text, 'milk') || str_contains($text, 'food') || str_contains($text, 'market') || str_contains($text, 'pizza')) {
                    return 'Groceries';
                }
                if (str_contains($text, 'fix') || str_contains($text, 'repair') || str_contains($text, 'bulb') || str_contains($text, 'maintenance')) {
                    return 'Maintenance';
                }
                return 'Other';
            }
        );
    }

    public function household(): BelongsTo
    {
        return $this->belongsTo(Household::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assignee_id');
    }

    public function claims(): HasMany
    {
        return $this->hasMany(BountyClaim::class);
    }

    public function activeClaim(): HasMany
    {
        return $this->claims()->where('status', 'active');
    }

    public function isAvailable(): bool
    {
        if ($this->status !== 'open') {
            return false;
        }

        return $this->due_at === null || $this->due_at->isFuture();
    }

    public function isExpired(): bool
    {
        return $this->status === 'open'
            && $this->due_at !== null
            && ! $this->due_at->isFuture();
    }

    public function isTaken(): bool
    {
        return in_array($this->status, ['claimed', 'in_progress'], true);
    }

    public function isCancelled(): bool
    {
        return in_array($this->status, ['cancelled', 'canceled'], true);
    }

    public function tokens(): int
    {
        $reward = (int) round((float) ($this->reward_value ?? 0));
        if ($reward > 0) {
            return $reward;
        }

        $xp = (int) ($this->xp_reward ?? 0);

        return $xp > 0 ? $xp : 50;
    }

    // Local Query Scopes
    public function scopeForHousehold(Builder $query, int $householdId): Builder
    {
        return $query->where('household_id', $householdId);
    }

    public function scopeOpen(Builder $query): Builder
    {
        return $query->where('status', 'open');
    }

    public function scopeClaimedBy(Builder $query, int $userId): Builder
    {
        return $query->where('assignee_id', $userId)->where('status', 'claimed');
    }

    public function scopeCompleted(Builder $query): Builder
    {
        return $query->where('status', 'completed');
    }

    /**
     * Scope bounties visible to a user under household membership and departure rules.
     *
     * - Active members see active-member chores plus completed chores executed by
     *   other household members when the creator has departed.
     * - Users who left a household have all available, taken, and awaiting review
     *   chores in that household hidden until they rejoin, retaining visibility
     *   only for completed chores executed by other household members.
     */
    public function scopeVisibleToUser(Builder $query, User $user): Builder
    {
        $userId = (int) $user->id;

        return $query->where(function (Builder $outer) use ($userId) {
            // Case 1: Viewer is an active member of the bounty's household.
            $outer->where(function (Builder $activeCase) use ($userId) {
                $activeCase->whereExists(function ($sub) use ($userId) {
                    $sub->selectRaw('1')
                        ->from('household_user')
                        ->whereColumn('household_user.household_id', 'bounties.household_id')
                        ->where('household_user.user_id', $userId);
                })->where(function (Builder $creatorCheck) {
                    $creatorCheck->whereExists(function ($sub) {
                        $sub->selectRaw('1')
                            ->from('household_user')
                            ->whereColumn('household_user.household_id', 'bounties.household_id')
                            ->whereColumn('household_user.user_id', 'bounties.created_by');
                    })->orWhere(function (Builder $completedOther) {
                        $completedOther->where('bounties.status', 'completed')
                            ->whereNotNull('bounties.assignee_id')
                            ->whereColumn('bounties.assignee_id', '!=', 'bounties.created_by');
                    });
                });
            })
            // Case 2: Viewer left the bounty's household.
            ->orWhere(function (Builder $departedCase) use ($userId) {
                $departedCase->whereNotExists(function ($sub) use ($userId) {
                    $sub->selectRaw('1')
                        ->from('household_user')
                        ->whereColumn('household_user.household_id', 'bounties.household_id')
                        ->where('household_user.user_id', $userId);
                })
                ->where('bounties.status', 'completed')
                ->whereNotNull('bounties.assignee_id')
                ->where('bounties.assignee_id', '!=', $userId)
                ->where(function (Builder $association) use ($userId) {
                    $association->where('bounties.created_by', $userId)
                        ->orWhereExists(function ($sub) use ($userId) {
                            $sub->selectRaw('1')
                                ->from('bounty_notifications')
                                ->whereColumn('bounty_notifications.household_id', 'bounties.household_id')
                                ->where('bounty_notifications.user_id', $userId);
                        })
                        ->orWhereExists(function ($sub) use ($userId) {
                            $sub->selectRaw('1')
                                ->from('bounty_claims')
                                ->join('bounties as bc_bounties', 'bc_bounties.id', '=', 'bounty_claims.bounty_id')
                                ->whereColumn('bc_bounties.household_id', 'bounties.household_id')
                                ->where('bounty_claims.user_id', $userId);
                        })
                        ->orWhereExists(function ($sub) use ($userId) {
                            $sub->selectRaw('1')
                                ->from('bounties as prior_bounties')
                                ->whereColumn('prior_bounties.household_id', 'bounties.household_id')
                                ->where(function ($q) use ($userId) {
                                    $q->where('prior_bounties.created_by', $userId)
                                        ->orWhere('prior_bounties.assignee_id', $userId);
                                });
                        });
                });
            });
        });
    }

    /**
     * Remove stored public disk files referenced by /storage/... paths.
     *
     * @param  array<int, mixed>  $paths
     */
    public static function removeStoredProofPaths(array $paths): void
    {
        $diskPaths = [];
        foreach ($paths as $path) {
            if (! is_string($path)) {
                continue;
            }
            $relative = ltrim(preg_replace('#^/storage/#', '', trim($path)) ?? '', '/');
            if ($relative !== '' && ! str_contains($relative, '://')) {
                $diskPaths[] = $relative;
            }
        }

        if (! empty($diskPaths)) {
            Storage::disk('public')->delete($diskPaths);
        }
    }
}
