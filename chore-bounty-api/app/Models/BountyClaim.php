<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class BountyClaim extends Model
{
    protected $fillable = [
        'bounty_id',
        'user_id',
        'status',
        'claimed_at',
        'released_at',
    ];

    protected function casts(): array
    {
        return [
            'claimed_at' => 'datetime',
            'released_at' => 'datetime',
        ];
    }

    public function bounty(): BelongsTo
    {
        return $this->belongsTo(Bounty::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function completions(): HasMany
    {
        return $this->hasMany(BountyCompletion::class);
    }
}
