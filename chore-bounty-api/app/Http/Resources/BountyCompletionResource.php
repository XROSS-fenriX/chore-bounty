<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BountyCompletionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'bounty_claim_id' => $this->bounty_claim_id,
            'reviewed_by' => $this->reviewed_by,
            'submission_note' => $this->submission_note,
            'proof_url' => $this->proof_url,
            'status' => $this->status,
            'submitted_at' => $this->submitted_at,
            'reviewed_at' => $this->reviewed_at,
            'claim' => new BountyClaimResource(
                $this->whenLoaded('claim')
            ),
            'reviewer' => new UserResource(
                $this->whenLoaded('reviewer')
            ),
            'redemption' => new RewardRedemptionResource(
                $this->whenLoaded('redemption')
            ),
        ];
    }
}
