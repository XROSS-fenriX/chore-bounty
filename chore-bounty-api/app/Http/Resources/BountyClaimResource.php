<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BountyClaimResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'bounty_id' => $this->bounty_id,
            'user_id' => $this->user_id,
            'status' => $this->status,
            'claimed_at' => $this->claimed_at,
            'released_at' => $this->released_at,
            'user' => new UserResource(
                $this->whenLoaded('user')
            ),
            'bounty' => new BountyResource(
                $this->whenLoaded('bounty')
            ),
            'completions' => BountyCompletionResource::collection(
                $this->whenLoaded('completions')
            ),
        ];
    }
}
