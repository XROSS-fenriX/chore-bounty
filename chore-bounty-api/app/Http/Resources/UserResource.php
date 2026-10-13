<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,

            'households' => HouseholdResource::collection(
                $this->whenLoaded('households')
            ),

            'memberships' => HouseholdUserResource::collection(
                $this->whenLoaded('memberships')
            ),

            'created_bounties' => BountyResource::collection(
                $this->whenLoaded('createdBounties')
            ),

            'bounty_claims' => BountyClaimResource::collection(
                $this->whenLoaded('bountyClaims')
            ),

            'reward_redemptions' => RewardRedemptionResource::collection(
                $this->whenLoaded('rewardRedemptions')
            ),

            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
