<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\BountyClaimController;
use App\Http\Controllers\BountyCompletionController;
use App\Http\Controllers\BountyController;
use App\Http\Controllers\HouseholdController;
use App\Http\Controllers\HouseholdUserController;
use App\Http\Controllers\RewardRedemptionController;
use App\Http\Controllers\UserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $request) =>
        new \App\Http\Resources\UserResource($request->user())
    );

    Route::apiResource('users', UserController::class)
        ->only(['index', 'show', 'update']);

    Route::apiResource('households', HouseholdController::class);

    Route::get(
        'households/{household}/members',
        [HouseholdUserController::class, 'index']
    );

    Route::post(
        'households/{household}/members',
        [HouseholdUserController::class, 'store']
    );

    Route::delete(
        'households/{household}/members/{user}',
        [HouseholdUserController::class, 'destroy']
    );

    Route::apiResource('bounties', BountyController::class);

    Route::get('claims', [BountyClaimController::class, 'index']);

    Route::post(
        'bounties/{bounty}/claim',
        [BountyClaimController::class, 'store']
    );

    Route::get(
        'claims/{bountyClaim}',
        [BountyClaimController::class, 'show']
    );

    Route::delete(
        'claims/{bountyClaim}',
        [BountyClaimController::class, 'destroy']
    );

    Route::get(
        'completions',
        [BountyCompletionController::class, 'index']
    );

    Route::post(
        'claims/{bountyClaim}/completions',
        [BountyCompletionController::class, 'store']
    );

    Route::get(
        'completions/{bountyCompletion}',
        [BountyCompletionController::class, 'show']
    );

    Route::patch(
        'completions/{bountyCompletion}',
        [BountyCompletionController::class, 'update']
    );

    Route::get(
        'redemptions',
        [RewardRedemptionController::class, 'index']
    );

    Route::post(
        'completions/{bountyCompletion}/redemption',
        [RewardRedemptionController::class, 'store']
    );

    Route::get(
        'redemptions/{rewardRedemption}',
        [RewardRedemptionController::class, 'show']
    );

    Route::patch(
        'redemptions/{rewardRedemption}',
        [RewardRedemptionController::class, 'update']
    );
});
