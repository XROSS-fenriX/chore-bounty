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
            'category' => $this->category,
            'xp_reward' => (int) ($this->xp_reward ?? 50),
            'reward_value' => $this->reward_value,
            'reward_description' => $this->reward_description,
            'status' => $this->status,
            'submission_proof' => $this->submission_proof,
            'submission_images' => $this->formatSubmissionImages($request),
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

    /**
     * Normalize stored relative proof image paths to request-origin URLs.
     *
     * @return list<string>
     */
    private function formatSubmissionImages(Request $request): array
    {
        $rawImages = is_array($this->submission_images) ? $this->submission_images : [];
        $baseUrl = rtrim($request->getSchemeAndHttpHost(), '/');

        $urls = [];
        foreach ($rawImages as $path) {
            if (! is_string($path)) {
                continue;
            }
            $trimmed = trim($path);
            if ($trimmed === '') {
                continue;
            }
            if (str_starts_with($trimmed, 'http://') || str_starts_with($trimmed, 'https://')) {
                $urls[] = $trimmed;
                continue;
            }
            $normalized = str_starts_with($trimmed, '/') ? $trimmed : '/'.$trimmed;
            $urls[] = $baseUrl !== '' ? $baseUrl.$normalized : $normalized;
        }

        return $urls;
    }
}
