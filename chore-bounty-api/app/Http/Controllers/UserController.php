<?php

namespace App\Http\Controllers;

use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    private const AVATAR_RULE = [
        'string',
        'max:100',
        'regex:/^(?!.*\.\.)[A-Za-z0-9 _.-]+$/',
    ];

    public function index(Request $request)
    {
        $users = User::query()
            ->whereHas('households.members', function ($query) use ($request) {
                $query->where('users.id', $request->user()->id);
            })
            ->select([
                'id',
                'first_name',
                'middle_name',
                'last_name',
                'gender',
                'email',
                'avatar',
                'created_at',
            ])
            ->distinct()
            ->paginate(15);

        return UserResource::collection($users);
    }

    public function show(User $user)
    {
        Gate::authorize('view', $user);

        return new UserResource($user);
    }

    public function update(Request $request, User $user)
    {
        Gate::authorize('update', $user);

        $validated = $request->validate([
            'first_name' => ['sometimes', 'required', 'string', 'max:100'],
            'middle_name' => ['sometimes', 'nullable', 'string', 'max:100'],
            'last_name' => ['sometimes', 'required', 'string', 'max:100'],
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'gender' => ['sometimes', 'required', Rule::in(User::GENDERS)],
            'avatar' => ['sometimes', 'nullable', ...self::AVATAR_RULE],
        ]);

        if (array_key_exists('middle_name', $validated)) {
            $trimmedMiddle = trim((string) ($validated['middle_name'] ?? ''));
            $validated['middle_name'] = $trimmedMiddle !== '' ? $trimmedMiddle : null;
        }

        $user->update($validated);

        return new UserResource($user->fresh());
    }

    public function updateAvatar(Request $request)
    {
        $validated = $request->validate([
            'avatar' => ['required', ...self::AVATAR_RULE],
        ]);

        $user = $request->user();
        $user->update(['avatar' => $validated['avatar']]);

        return response()->json([
            'message' => 'Avatar updated successfully.',
            'user' => new UserResource($user->fresh()),
        ]);
    }
}
