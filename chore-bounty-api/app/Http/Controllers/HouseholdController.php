<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Resources\HouseholdResource;
use App\Models\Household;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class HouseholdController extends Controller
{
    public function index(Request $request)
    {
        $households = $request->user()
            ->households()
            ->with('creator')
            ->paginate(10);

        return HouseholdResource::collection($households);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
        ]);

        $household = Household::create([
            'created_by' => $request->user()->id,
            'name' => $validated['name'],
            'invite_code' => Str::upper(Str::random(12)),
        ]);

        $household->members()->attach($request->user()->id, [
            'role' => 'owner',
            'joined_at' => now(),
        ]);

        return (new HouseholdResource($household->load('creator', 'members')))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Household $household)
    {
        return new HouseholdResource(
            $household->load('creator', 'members', 'bounties')
        );
    }

    public function update(Request $request, Household $household)
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:150'],
        ]);

        $household->update($validated);

        return new HouseholdResource($household->fresh());
    }

    public function destroy(Household $household)
    {

        $household->delete();

        return response()->noContent();
    }
}
