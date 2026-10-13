<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RewardRedemptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'bounty_completion_id' => $this->bounty_completion_id,
            'redeemed_by' => $this->redeemed_by,
            'status' => $this->status,
            'redeemed_at' => $this->redeemed_at,
            'user' => new UserResource(
                $this->whenLoaded('user')
            ),
        ];
    }
}
