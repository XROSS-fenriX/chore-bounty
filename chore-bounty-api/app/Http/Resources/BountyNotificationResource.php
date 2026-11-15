<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BountyNotificationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'household_id' => $this->household_id,
            'bounty_id' => $this->bounty_id,
            'user_id' => $this->user_id,
            'actor_id' => $this->actor_id,
            'actor_name' => $this->whenLoaded('actor', fn () => $this->actor?->name),
            'bounty' => $this->whenLoaded('bounty', function () {
                if (! $this->bounty) {
                    return null;
                }

                return [
                    'id' => $this->bounty->id,
                    'title' => $this->bounty->title,
                    'tokens' => $this->bounty->tokens(),
                ];
            }),
            'event_type' => $this->event_type,
            'event_name' => $this->event_name,
            'description' => $this->description,
            'category' => $this->category ?? 'Other',
            'is_read' => (bool) $this->is_read,
            'read_at' => $this->read_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}

