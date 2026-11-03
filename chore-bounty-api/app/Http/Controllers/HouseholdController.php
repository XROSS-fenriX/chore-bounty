<?php

namespace App\Http\Controllers;

use App\Http\Resources\HouseholdResource;
use App\Models\Household;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
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
        abort_unless(
            $household->members()->where('users.id', $request->user()->id)->exists(),
            403,
            'You are not a member of this household.'
        );

        return new HouseholdResource(
            $household->load(['creator', 'members'])
        );
    }

    public function update(Request $request, Household $household)
    {
        abort_unless(
            $household->members()->where('users.id', $request->user()->id)->exists(),
            403,
            'You are not a member of this household.'
        );

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
        ]);

        $household->update($validated);

        return new HouseholdResource($household->fresh()->load('creator'));
    }

    public function destroy(Request $request, Household $household)
    {
        abort_unless(
            $household->created_by === $request->user()->id,
            403,
            'Only the household creator can delete this household.'
        );

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

        $userId = $request->user()->id;

        if (! $household->members()->where('users.id', $userId)->exists()) {
            $household->members()->attach($userId, [
                'role' => 'member',
                'joined_at' => now(),
            ]);
        }

        return response()->json([
            'message' => 'Successfully joined household ' . $household->name . '!',
            'data' => new HouseholdResource($household->fresh()->load(['creator', 'members'])),
        ]);
    }

    public function leave(Request $request, Household $household): JsonResponse
    {
        $userId = $request->user()->id;

        if (! $household->members()->where('users.id', $userId)->exists()) {
            return response()->json([
                'message' => 'You are not a member of this household.',
            ], 422);
        }

        $isOwner = $household->created_by === $userId;
        $remainingMembers = $household->members()->where('users.id', '!=', $userId)->get();

        if ($isOwner && $remainingMembers->isNotEmpty()) {
            $newOwner = $remainingMembers->first();
            $household->update(['created_by' => $newOwner->id]);
            $household->members()->updateExistingPivot($newOwner->id, ['role' => 'owner']);
        }

        $household->members()->detach($userId);

        if ($household->members()->count() === 0) {
            $household->delete();
        }

        return response()->json([
            'message' => 'Successfully left the household.',
        ]);
    }
}
