<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HouseholdResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'invite_code' => $this->invite_code,
            'created_by' => $this->created_by,
            'role' => $this->pivot?->role ?? ($this->created_by === $request->user()?->id ? 'owner' : 'member'),
            'members_count' => $this->members_count ?? $this->members()->count(),
            'bounties_count' => $this->bounties_count ?? $this->bounties()->count(),
            'creator' => new UserResource(
                $this->whenLoaded('creator')
            ),
            'members' => UserResource::collection(
                $this->whenLoaded('members')
            ),
            'bounties' => BountyResource::collection(
                $this->whenLoaded('bounties')
            ),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
