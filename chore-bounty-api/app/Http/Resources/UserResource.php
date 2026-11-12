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
            'first_name' => $this->first_name,
            'middle_name' => $this->middle_name,
            'last_name' => $this->last_name,
            'name' => $this->name,
            'gender' => $this->gender,
            'email' => $this->when(
                ! $request->user() || $request->user()->id === $this->id,
                $this->email
            ),
            'avatar' => $this->avatar,

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
