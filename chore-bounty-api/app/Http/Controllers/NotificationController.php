<?php

namespace App\Http\Controllers;

use App\Http\Resources\BountyNotificationResource;
use App\Models\BountyNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $householdId = $this->resolveAuthorizedHouseholdId($request);

        $query = BountyNotification::query()
            ->visibleTo($user, $householdId)
            ->with([
                'actor',
                'bounty' => fn ($q) => $q->withTrashed(),
            ])
            ->latest('id');

        $unreadCount = (clone $query)->where('is_read', false)->count();
        $items = $query->limit(100)->get();

        return response()->json([
            'data' => BountyNotificationResource::collection($items),
            'meta' => [
                'unread_count' => $unreadCount,
            ],
        ]);
    }

    public function markAsRead(Request $request, BountyNotification $notification): JsonResponse
    {
        $user = $request->user();
        $isAuthorized = BountyNotification::query()
            ->visibleTo($user)
            ->whereKey($notification->id)
            ->exists();

        if (! $isAuthorized) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        if (! $notification->is_read) {
            $notification->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
        }

        return response()->json([
            'message' => 'Notification marked as read.',
            'data' => new BountyNotificationResource($notification->fresh()->load(['actor', 'bounty' => fn ($q) => $q->withTrashed()])),
        ]);
    }

    public function markAllAsRead(Request $request): JsonResponse
    {
        $user = $request->user();
        $householdId = $this->resolveAuthorizedHouseholdId($request);

        BountyNotification::query()
            ->visibleTo($user, $householdId)
            ->where('is_read', false)
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);

        return response()->json([
            'message' => 'All notifications marked as read.',
            'meta' => [
                'unread_count' => 0,
            ],
        ]);
    }

    private function resolveAuthorizedHouseholdId(Request $request): ?int
    {
        $raw = $request->header('X-Household-Id')
            ?? $request->query('household_id')
            ?? $request->input('household_id');

        if ($raw === null || trim((string) $raw) === '') {
            return null;
        }

        $householdId = (int) $raw;
        abort_unless(
            $householdId > 0 && $request->user()->households()->where('households.id', $householdId)->exists(),
            403,
            'You are not an active member of this household.'
        );

        return $householdId;
    }
}

