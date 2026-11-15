<?php

namespace App\Http\Controllers;

use App\Http\Resources\HouseholdResource;
use App\Models\BountyNotification;
use App\Models\Household;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Str;

class HouseholdController extends Controller
{
    public function index(Request $request)
    {
        $households = $request->user()
            ->households()
            ->with(['creator'])
            ->withCount(['members', 'bounties'])
            ->latest()
            ->get();

        return response()->json([
            'data' => HouseholdResource::collection($households),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
        ]);

        $household = Household::create([
            'created_by' => $request->user()->id,
            'name' => $validated['name'],
            'invite_code' => Str::upper(Str::random(8)),
        ]);

        $household->members()->attach($request->user()->id, [
            'role' => 'owner',
            'joined_at' => now(),
        ]);

        return (new HouseholdResource($household->load('creator', 'members')))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, Household $household)
    {
        Gate::authorize('view', $household);

        return new HouseholdResource(
            $household->load(['creator', 'members'])
        );
    }

    public function update(Request $request, Household $household)
    {
        Gate::authorize('update', $household);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
        ]);

        $household->update($validated);

        return new HouseholdResource($household->fresh()->load('creator'));
    }

    public function destroy(Request $request, Household $household)
    {
        Gate::authorize('delete', $household);

        $household->delete();

        return response()->noContent();
    }

    public function joinByCode(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'invite_code' => ['required', 'string'],
        ]);

        $code = Str::upper(trim($validated['invite_code']));
        $household = Household::where('invite_code', $code)->first();

        if (! $household) {
            return response()->json([
                'message' => 'Invalid invite code. No household found with code: ' . $code,
            ], 404);
        }

        $user = $request->user();
        $userId = $user->id;

        if (! $household->members()->where('users.id', $userId)->exists()) {
            $household->members()->attach($userId, [
                'role' => 'member',
                'joined_at' => now(),
            ]);

            BountyNotification::dispatchHouseholdEvent(
                householdId: (int) $household->id,
                actor: $user,
                eventType: 'member_joined',
                eventName: 'Member Joined',
                description: "{$user->name} joined \"{$household->name}\".",
                category: 'Household',
            );
        }

        return response()->json([
            'message' => 'Successfully joined household ' . $household->name . '!',
            'data' => new HouseholdResource($household->fresh()->load(['creator', 'members'])),
        ]);
    }

    public function leave(Request $request, Household $household): JsonResponse
    {
        $user = $request->user();
        $userId = $user->id;

        if (! $household->members()->where('users.id', $userId)->exists()) {
            return response()->json([
                'message' => 'You are not a member of this household.',
            ], 422);
        }

        $householdDeleted = false;

        DB::transaction(function () use ($household, $userId, &$householdDeleted) {
            $household->releaseMemberAssignments($userId);

            $isOwner = $household->created_by === $userId;
            $remainingMembers = $household->members()->where('users.id', '!=', $userId)->get();

            if ($isOwner && $remainingMembers->isNotEmpty()) {
                $newOwner = $remainingMembers->first();
                $household->update(['created_by' => $newOwner->id]);
                $household->members()->updateExistingPivot($newOwner->id, ['role' => 'owner']);
            }

            $household->members()->detach($userId);

            if ($household->members()->count() === 0 && ! $household->bounties()->withTrashed()->exists()) {
                $household->delete();
                $householdDeleted = true;
            }
        });

        if (! $householdDeleted) {
            BountyNotification::dispatchHouseholdEvent(
                householdId: (int) $household->id,
                actor: $user,
                eventType: 'member_left',
                eventName: 'Member Left',
                description: "{$user->name} left \"{$household->name}\".",
                category: 'Household',
            );
        }

        return response()->json([
            'message' => 'Successfully left the household.',
        ]);
    }

    public function transferOwnership(Request $request, Household $household): JsonResponse
    {
        Gate::authorize('transferOwnership', $household);

        $validated = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
        ]);

        $actor = $request->user();
        $newOwnerId = (int) $validated['user_id'];

        abort_if(
            $newOwnerId === (int) $actor->id,
            422,
            'You are already the owner of this household.'
        );

        $isMember = $household->memberships()
            ->where('user_id', $newOwnerId)
            ->exists();

        abort_unless(
            $isMember,
            422,
            'Selected user is not a member of this household.'
        );

        DB::transaction(function () use ($household, $actor, $newOwnerId) {
            $lockedHousehold = Household::whereKey($household->id)->lockForUpdate()->firstOrFail();

            $lockedHousehold->memberships()
                ->where('role', 'owner')
                ->update(['role' => 'member']);

            $lockedHousehold->memberships()
                ->where('user_id', $actor->id)
                ->update(['role' => 'member']);

            $lockedHousehold->memberships()
                ->where('user_id', $newOwnerId)
                ->update(['role' => 'owner']);

            $lockedHousehold->update(['created_by' => $newOwnerId]);
        });

        $fresh = $household->fresh()
            ->load(['creator', 'members'])
            ->loadCount(['members', 'bounties']);

        return response()->json([
            'message' => 'Ownership transferred successfully.',
            'data' => new HouseholdResource($fresh),
        ]);
    }
}
