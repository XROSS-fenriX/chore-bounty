<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $users = User::query()
            ->whereHas('households.members', function ($query) use ($request) {
                $query->where('users.id', $request->user()->id);
            })
            ->select(['id', 'name', 'email', 'avatar', 'created_at'])
            ->distinct()
            ->paginate(15);

        return UserResource::collection($users);
    }

    public function show(User $user)
    {
        // $this->authorize('view', $user);

        return new UserResource($user);
    }

    public function update(Request $request, User $user)
    {
        // $this->authorize('update', $user);

        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'avatar' => ['sometimes', 'nullable', 'string', 'max:255'],
        ]);

        $user->update($validated);

        return new UserResource($user->fresh());
    }

    public function updateAvatar(Request $request)
    {
        $validated = $request->validate([
            'avatar' => ['required', 'string', 'max:255'],
        ]);

        $user = $request->user();
        $user->update(['avatar' => $validated['avatar']]);

        return response()->json([
            'message' => 'Avatar updated successfully.',
            'user' => new UserResource($user->fresh()),
        ]);
    }
}
