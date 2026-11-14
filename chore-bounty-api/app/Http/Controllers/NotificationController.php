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
        $householdId = $request->header('X-Household-Id') ?? $request->query('household_id');

        $query = BountyNotification::query()
            ->where('user_id', $user->id)
            ->where(function ($q) use ($user) {
                $q->whereNull('actor_id')->orWhere('actor_id', '!=', $user->id);
            })
            ->with('actor')
            ->latest('id');

        if ($householdId) {
            $query->where('household_id', (int) $householdId);
        }

        $items = $query->limit(100)->get();
        $unreadCount = $items->where('is_read', false)->count();

        return response()->json([
            'data' => BountyNotificationResource::collection($items),
            'meta' => [
                'unread_count' => $unreadCount,
            ],
        ]);
    }

    public function markAsRead(Request $request, BountyNotification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
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
            'data' => new BountyNotificationResource($notification->fresh()->load('actor')),
        ]);
    }

    public function markAllAsRead(Request $request): JsonResponse
    {
        $user = $request->user();
        $householdId = $request->header('X-Household-Id') ?? $request->query('household_id');

        $query = BountyNotification::query()
            ->where('user_id', $user->id)
            ->where(function ($q) use ($user) {
                $q->whereNull('actor_id')->orWhere('actor_id', '!=', $user->id);
            })
            ->where('is_read', false);

        if ($householdId) {
            $query->where('household_id', (int) $householdId);
        }

        $query->update([
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
}

