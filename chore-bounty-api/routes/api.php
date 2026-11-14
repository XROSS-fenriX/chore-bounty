<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\BountyActionController;
use App\Http\Controllers\BountyClaimController;
use App\Http\Controllers\BountyCompletionController;
use App\Http\Controllers\BountyController;
use App\Http\Controllers\HouseholdController;
use App\Http\Controllers\HouseholdUserController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\RewardRedemptionController;
use App\Http\Controllers\UserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $request) =>
        new \App\Http\Resources\UserResource($request->user())
    );
    Route::put('/user/avatar', [UserController::class, 'updateAvatar']);

    Route::apiResource('users', UserController::class)
        ->only(['index', 'show', 'update']);

    // Household Management & Leaderboard
    Route::post('households/join', [HouseholdController::class, 'joinByCode'])->middleware('throttle:15,1');
    Route::post('households/{household}/leave', [HouseholdController::class, 'leave']);
    Route::apiResource('households', HouseholdController::class);
    Route::get('households/{household}/leaderboard', [LeaderboardController::class, 'index']);
    Route::get('leaderboard', [LeaderboardController::class, 'current']);

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

    // Notifications
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::post('notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::post('notifications/{notification}/read', [NotificationController::class, 'markAsRead']);
    Route::patch('notifications/{notification}/read', [NotificationController::class, 'markAsRead']);

    // Bounty REST Resource
    Route::apiResource('bounties', BountyController::class);

    // Bounty Lifecycle Actions (Route Model Binding: {bounty})
    Route::prefix('bounties/{bounty}')->group(function () {
        Route::post('/claim', [BountyActionController::class, 'claim']);
        Route::delete('/claim', [BountyActionController::class, 'release']);
        Route::post('/release', [BountyActionController::class, 'release']);
        Route::post('/submit', [BountyActionController::class, 'submit']);
        Route::post('/complete', [BountyActionController::class, 'complete']);
        Route::post('/verify', [BountyActionController::class, 'verify']);
        Route::post('/reject', [BountyActionController::class, 'reject']);
        Route::post('/cancel', [BountyActionController::class, 'cancel']);
    });

    // Legacy Claim & Completion Sub-routes
    Route::get('claims', [BountyClaimController::class, 'index']);
    Route::get('claims/{bountyClaim}', [BountyClaimController::class, 'show']);
    Route::delete('claims/{bountyClaim}', [BountyClaimController::class, 'destroy']);

    Route::get('completions', [BountyCompletionController::class, 'index']);
    Route::post('claims/{bountyClaim}/completions', [BountyCompletionController::class, 'store']);
    Route::get('completions/{bountyCompletion}', [BountyCompletionController::class, 'show']);
    Route::patch('completions/{bountyCompletion}', [BountyCompletionController::class, 'update']);

    Route::get('redemptions', [RewardRedemptionController::class, 'index']);
    Route::post('completions/{bountyCompletion}/redemption', [RewardRedemptionController::class, 'store']);
    Route::get('redemptions/{rewardRedemption}', [RewardRedemptionController::class, 'show']);
    Route::patch('redemptions/{rewardRedemption}', [RewardRedemptionController::class, 'update']);
});
