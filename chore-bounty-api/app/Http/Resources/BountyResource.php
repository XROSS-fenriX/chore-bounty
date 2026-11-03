<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BountyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'household_id' => $this->household_id,
            'created_by' => $this->created_by,
            'creator_id' => $this->created_by,
            'assignee_id' => $this->assignee_id,
            'title' => $this->title,
            'description' => $this->description,
            'difficulty' => $this->difficulty,
            'xp_reward' => (int) ($this->xp_reward ?? 50),
            'reward_value' => $this->reward_value,
            'reward_description' => $this->reward_description,
            'status' => $this->status,
            'submission_proof' => $this->submission_proof,
            'claimed_at' => $this->claimed_at,
            'submitted_at' => $this->submitted_at,
            'completed_at' => $this->completed_at,
            'due_at' => $this->due_at,
            'creator' => new UserResource(
                $this->whenLoaded('creator')
            ),
            'assignee' => new UserResource(
                $this->whenLoaded('assignee')
            ),
            'household' => new HouseholdResource(
                $this->whenLoaded('household')
            ),
            'claims' => BountyClaimResource::collection(
                $this->whenLoaded('claims')
            ),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
