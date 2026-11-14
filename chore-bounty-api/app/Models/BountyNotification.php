<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BountyNotification extends Model
{
    protected $fillable = [
        'household_id',
        'bounty_id',
        'user_id',
        'actor_id',
        'event_type',
        'event_name',
        'description',
        'category',
        'is_read',
        'read_at',
    ];

    protected function casts(): array
    {
        return [
            'is_read' => 'boolean',
            'read_at' => 'datetime',
        ];
    }

    public function household(): BelongsTo
    {
        return $this->belongsTo(Household::class);
    }

    public function bounty(): BelongsTo
    {
        return $this->belongsTo(Bounty::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }

    public static function dispatchForHousehold(
        Bounty $bounty,
        User $actor,
        string $eventType,
        string $eventName,
        string $description
    ): void {
        $memberIds = HouseholdUser::query()
            ->where('household_id', $bounty->household_id)
            ->pluck('user_id')
            ->all();

        $recipientIds = array_values(array_unique(array_filter([
            ...$memberIds,
            $bounty->created_by,
            $bounty->assignee_id,
        ])));

        // Only notify other users (do not notify the actor who triggered or posted the event)
        $recipientIds = array_values(array_filter(
            $recipientIds,
            fn ($id) => (int) $id !== (int) $actor->id
        ));

        $now = now();
        $rows = [];
        foreach ($recipientIds as $recipientId) {
            $rows[] = [
                'household_id' => $bounty->household_id,
                'bounty_id' => $bounty->id,
                'user_id' => (int) $recipientId,
                'actor_id' => $actor->id,
                'event_type' => $eventType,
                'event_name' => $eventName,
                'description' => $description,
                'category' => $bounty->category ?? 'Other',
                'is_read' => false,
                'read_at' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        if (! empty($rows)) {
            self::insert($rows);
        }
    }
}
