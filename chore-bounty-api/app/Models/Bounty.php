<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

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
        'xp_reward',
        'reward_value',
        'reward_description',
        'status',
        'submission_proof',
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
}
