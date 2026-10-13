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
            'title' => $this->title,
            'description' => $this->description,
            'difficulty' => $this->difficulty,
            'reward_value' => $this->reward_value,
            'reward_description' => $this->reward_description,
            'status' => $this->status,
            'due_at' => $this->due_at,
            'creator' => new UserResource(
                $this->whenLoaded('creator')
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
