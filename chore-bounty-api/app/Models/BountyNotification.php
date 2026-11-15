<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
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

    public function scopeVisibleTo(Builder $query, User $user, ?int $householdId = null): Builder
    {
        $query->where('bounty_notifications.user_id', $user->id)
            ->whereIn('bounty_notifications.household_id', $user->households()->select('households.id'))
            ->where(function (Builder $q) use ($user) {
                $q->whereNull('actor_id')->orWhere('actor_id', '!=', $user->id);
            })
            ->where(function (Builder $q) use ($user) {
                $q->where('event_type', '!=', 'submitted')
                    ->orWhereHas('bounty', fn (Builder $bq) => $bq->withTrashed()->where('created_by', $user->id));
            })
            ->where(function (Builder $q) {
                $q->whereNull('bounty_id')
                    ->orWhereHas('bounty', function (Builder $bq) {
                        $bq->withTrashed()->where(function (Builder $inner) {
                            $inner->whereNotNull('deleted_at')
                                ->orWhere('status', 'completed')
                                ->orWhereExists(function ($sub) {
                                    $sub->selectRaw('1')
                                        ->from('household_user')
                                        ->whereColumn('household_user.household_id', 'bounties.household_id')
                                        ->whereColumn('household_user.user_id', 'bounties.created_by');
                                });
                        });
                    });
            });

        if ($householdId !== null) {
            $query->where('bounty_notifications.household_id', $householdId);
        }

        return $query;
    }

    public static function dispatchHouseholdEvent(
        int $householdId,
        User $actor,
        string $eventType,
        string $eventName,
        string $description,
        ?int $bountyId = null,
        ?string $category = null,
        array $exceptUserIds = []
    ): void {
        $memberIds = HouseholdUser::query()
            ->where('household_id', $householdId)
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        $excluded = array_map('intval', [$actor->id, ...$exceptUserIds]);

        // Only notify active household members other than the actor and excluded recipients
        $recipientIds = array_values(array_unique(array_filter(
            $memberIds,
            fn (int $id) => $id > 0 && ! in_array($id, $excluded, true)
        )));

        $now = now();
        $rows = [];
        foreach ($recipientIds as $recipientId) {
            $rows[] = [
                'household_id' => $householdId,
                'bounty_id' => $bountyId,
                'user_id' => $recipientId,
                'actor_id' => $actor->id,
                'event_type' => $eventType,
                'event_name' => $eventName,
                'description' => $description,
                'category' => $category ?? 'Other',
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

    public static function dispatchForHousehold(
        Bounty $bounty,
        User $actor,
        string $eventType,
        string $eventName,
        string $description,
        array $exceptUserIds = []
    ): void {
        self::dispatchHouseholdEvent(
            householdId: (int) $bounty->household_id,
            actor: $actor,
            eventType: $eventType,
            eventName: $eventName,
            description: $description,
            bountyId: (int) $bounty->id,
            category: $bounty->category ?? 'Other',
            exceptUserIds: $exceptUserIds,
        );
    }

    public static function dispatchToUser(
        Bounty $bounty,
        User $actor,
        int $recipientId,
        string $eventType,
        string $eventName,
        string $description
    ): ?self {
        if ($recipientId <= 0 || $recipientId === (int) $actor->id) {
            return null;
        }

        $isActiveMember = HouseholdUser::query()
            ->where('household_id', $bounty->household_id)
            ->where('user_id', $recipientId)
            ->exists();

        if (! $isActiveMember) {
            return null;
        }

        return self::create([
            'household_id' => $bounty->household_id,
            'bounty_id' => $bounty->id,
            'user_id' => $recipientId,
            'actor_id' => $actor->id,
            'event_type' => $eventType,
            'event_name' => $eventName,
            'description' => $description,
            'category' => $bounty->category ?? 'Other',
            'is_read' => false,
            'read_at' => null,
        ]);
    }
}
