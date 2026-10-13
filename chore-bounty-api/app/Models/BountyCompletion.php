<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class BountyCompletion extends Model
{
    protected $fillable = [
        'bounty_claim_id',
        'reviewed_by',
        'submission_note',
        'proof_url',
        'status',
        'submitted_at',
        'reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'submitted_at' => 'datetime',
            'reviewed_at' => 'datetime',
        ];
    }

    public function claim(): BelongsTo
    {
        return $this->belongsTo(BountyClaim::class, 'bounty_claim_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function redemption(): HasOne
    {
        return $this->hasOne(RewardRedemption::class);
    }
}
