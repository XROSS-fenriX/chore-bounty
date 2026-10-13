<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Bounty extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'household_id',
        'created_by',
        'title',
        'description',
        'difficulty',
        'reward_value',
        'reward_description',
        'status',
        'due_at',
    ];

    protected function casts(): array
    {
        return [
            'reward_value' => 'decimal:2',
            'due_at' => 'datetime',
        ];
    }

    public function household(): BelongsTo
    {
        return $this->belongsTo(Household::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function claims(): HasMany
    {
        return $this->hasMany(BountyClaim::class);
    }

    public function activeClaim(): HasMany
    {
        return $this->claims()->where('status', 'active');
    }
}
