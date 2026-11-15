<?php

namespace App\Http\Resources;

use App\Models\HouseholdUser;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BountyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        [$isCreatorActive, $isViewerActive] = $this->resolveMembershipFlags($request);

        return [
            'id' => $this->id,
            'household_id' => $this->household_id,
            'created_by' => $this->created_by,
            'creator_id' => $this->created_by,
            'assignee_id' => $this->assignee_id,
            'is_creator_active_member' => $isCreatorActive,
            'is_viewer_active_member' => $isViewerActive,
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

    /**
     * @return array{0: bool, 1: bool}
     */
    private function resolveMembershipFlags(Request $request): array
    {
        $viewerId = (int) ($request->user()?->id ?? 0);
        $creatorId = (int) ($this->created_by ?? 0);

        if ($this->relationLoaded('household') && $this->household) {
            if ($this->household->relationLoaded('memberships')) {
                $memberIds = $this->household->memberships
                    ->pluck('user_id')
                    ->map(fn ($id) => (int) $id)
                    ->all();

                return [
                    $creatorId > 0 && in_array($creatorId, $memberIds, true),
                    $viewerId > 0 && in_array($viewerId, $memberIds, true),
                ];
            }

            if ($this->household->relationLoaded('members')) {
                $memberIds = $this->household->members
                    ->pluck('id')
                    ->map(fn ($id) => (int) $id)
                    ->all();

                return [
                    $creatorId > 0 && in_array($creatorId, $memberIds, true),
                    $viewerId > 0 && in_array($viewerId, $memberIds, true),
                ];
            }
        }

        $memberIds = HouseholdUser::query()
            ->where('household_id', $this->household_id)
            ->whereIn('user_id', array_values(array_filter([$creatorId, $viewerId])))
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        return [
            $creatorId > 0 && in_array($creatorId, $memberIds, true),
            $viewerId > 0 && in_array($viewerId, $memberIds, true),
        ];
    }
}
