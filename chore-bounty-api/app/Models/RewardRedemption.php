<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RewardRedemption extends Model
{
    protected $fillable = [
        'bounty_completion_id',
        'redeemed_by',
        'status',
        'redeemed_at',
    ];

    protected function casts(): array
    {
        return [
            'redeemed_at' => 'datetime',
        ];
    }

    public function completion(): BelongsTo
    {
        return $this->belongsTo(
            BountyCompletion::class,
            'bounty_completion_id'
        );
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'redeemed_by');
    }
}
