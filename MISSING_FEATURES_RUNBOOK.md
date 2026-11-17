# ChoreBounty: Missing Features Audit and Implementation Runbook

**Date:** November 18, 2026
**Scope:** Laravel API (`chore-bounty-api`) and Flutter app (`chore_bounty_application`)
**Baseline:** `main` at `2f4b3b9`. `php artisan test` 29/29, `flutter analyze` clean, `flutter test` 85/85.

This document lists the features the system lacks, ranks them, and defines the ones implemented in this change. The implementation follows this document.

---

## 1. Method

I read every route in `routes/api.php`, every controller, policy and model, and every screen and service in the app. For each user goal I checked whether the API supports it and whether the app exposes it. Findings are facts from the code, not assumptions.

## 2. What already works (no action)

Registration, login, logout with token revoke, profile edit, avatar, household create/join/leave/rename/transfer ownership/remove member, chore create/edit/cancel/delete by state, claim/abandon/submit with photo proof, approve/redo, past-due submit block, notifications with unread badge, leaderboard with periods, departed-member token display.

## 3. Missing features

Priority: **P1** = implement now, **P2** = needs a product or infrastructure decision, **P3** = nice to have.

| ID | Feature | Evidence | Gap | Priority |
| :-- | :-- | :-- | :-- | :-: |
| M-01 | Change password | `AuthController` has `register`, `login`, `me`, `logout` only. `EditProfileScreen` has no password field. | A signed-in user cannot change a password. A leaked password stays valid until the user is locked out. | P1 |
| M-02 | Regenerate household invite code | `invite_code` is set once in `HouseholdController@store`. No route changes it. | After an owner removes a member, the member keeps a working code and can rejoin. A shared code cannot be rotated. | P1 |
| M-03 | Safe household delete | `HouseholdController@destroy` calls `$household->delete()`. `bounties.household_id` is `restrictOnDelete`. | The call returns HTTP 500 when the household has chores. The app has no delete button, so the route is reachable only by direct API calls. | P1 (bug) |
| M-04 | Forgot password by email | `password_reset_tokens` table exists. No route, no screen. `.env.example` sets `MAIL_MAILER=log`. | Locked-out users cannot recover accounts. Needs a real mail transport. | P2 |
| M-05 | Delete account | No route. `bounties.created_by`, `bounty_claims.user_id` and `reward_redemptions.redeemed_by` are `restrictOnDelete`. | No way to remove personal data. Needs a retention rule (anonymize vs. delete). | P2 |
| M-06 | Spend tokens (rewards) | `reward_redemptions` rows are created on approval with status `unredeemed`. `GET /redemptions` and `PATCH /redemptions/{id}` exist. The app has no screen that calls them. | Tokens are a score only. The `redeemed` state is unreachable from the UI. Needs a product decision on what tokens buy. | P2 |
| M-07 | Recurring chores | `bounties` has no repeat fields. | Weekly chores must be re-posted by hand. | P2 |
| M-08 | Push notifications | Notifications are polled every 4 s while the app is open. | Nothing arrives when the app is closed. Needs a Firebase project. | P2 |
| M-09 | Email verification | `User` does not implement `MustVerifyEmail`. | Any address can register. | P2 |
| M-10 | Removed-member notification | `HouseholdUserController@destroy` dispatches no event. `leave` dispatches `member_left`. | Remaining members are not told when the owner removes someone. | P3 |
| M-11 | Notification paging | `NotificationController@index` returns `limit(100)`. | Older items are unreachable. | P3 |
| M-12 | Chore comments and history | No model. | Reviewers cannot discuss a submission except through redo notes. | P3 |

## 4. Decisions

| ID | Decision | Default |
| :-- | :-- | :-- |
| D1 | Implement P1 only (M-01, M-02, M-03). | Yes. P2 items each need an input from you (mail host, retention rule, reward catalog, Firebase). |
| D2 | M-01 revokes the user's other sessions and keeps the current one. | Yes. Standard practice after a password change. |
| D3 | M-02 invalidates the old code at once. Existing members are not affected. | Yes. |
| D4 | M-03 returns 422 with a clear message when the household still has chores or other members. The owner must remove chores and members first. | Yes. No cascade delete, because it would erase every member's earned-token history. |
| D5 | "Deployed version" is the local Laravel server on port 8000 and the Android emulator (`emulator-5554`), as in earlier runbooks. | Yes. |

## 5. Specifications (P1)

### M-01 Change password

**API**

- Route: `PUT /api/user/password`, inside `auth:sanctum`, `throttle:5,1`.
- Body: `current_password`, `password`, `password_confirmation`.
- Rules: `current_password` uses Laravel's `current_password` rule. `password` is `required|string|min:8|confirmed|different:current_password`.
- On success: update the hash, delete every token of the user except the current one, return `{ "message": "Password updated." }` with 200.
- Wrong current password returns 422 with an `errors.current_password` message.

**App**

- `AuthService.changePassword({currentPassword, newPassword, confirmation})`.
- New `ChangePasswordScreen` with three obscured fields, same card, field and button styles as `EditProfileScreen`.
- Entry point: a "Change Password" row under the details card in `EditProfileScreen`.
- Success: pop with a snackbar "Password updated." Failure: show `auth.error(e)` in the existing red error box.
- Client checks: all fields required, new password at least 8 characters, confirmation matches. The API remains the source of truth.

### M-02 Regenerate invite code

**API**

- Route: `POST /api/households/{household}/invite-code/regenerate`.
- Authorization: `Gate::authorize('manageMembers', $household)` (owner only).
- Behavior: generate `Str::upper(Str::random(8))`, retry while the value exists in `households.invite_code`, save, return `HouseholdResource` with 200.
- Response includes `invite_code`. Members and bounties are untouched.

**App**

- `HouseholdService.regenerateInviteCode(int id)` returns `Household`.
- `HouseholdView` shows a refresh icon button beside the copy chip, visible only to the owner when `onRegenerateInviteCode` is set.
- Tap opens `ConfirmActionDialog` ("Generate a new invite code? The current code stops working."). Confirm calls the callback.
- `HomeShell.handleRegenerateInviteCode` replaces the household in `myHouseholds` and `currentHousehold`, then shows a snackbar.

### M-03 Safe household delete

- `HouseholdController@destroy` aborts with 422 `Remove all chores and other members before deleting this household.` when `bounties()->withTrashed()->exists()` or another member remains.
- Otherwise it deletes in a transaction (memberships and notifications cascade).
- No app change.

## 6. Tests

**API (PHPUnit)**

- Change password: wrong current password gives 422. Short or unconfirmed password gives 422. Same password gives 422. Success gives 200, the new password logs in, the old one does not, other tokens are revoked, the current token still works.
- Regenerate code: non-owner gets 403. Owner gets 200 and a new 8-character code. The old code returns 404 on join. A member who joined earlier stays a member.
- Delete household: with chores returns 422 and the row remains. Empty single-member household returns 204.

**Flutter**

- `ChangePasswordScreen`: validation messages, success calls the service with the entered values, API error text is shown.
- `HouseholdView`: refresh button shows for the owner only, confirm calls the callback, cancel does not.

## 7. Implementation order

| Phase | Work | Check |
| :-- | :-- | :-- |
| 0 | `git pull origin main`. Baseline tests. | Done: 29/29 and 85/85. |
| 1 | API: M-01, M-02, M-03, routes, tests. | `php artisan test` passes. |
| 2 | App: service methods, `ChangePasswordScreen`, `HouseholdView` and `HomeShell` wiring, tests. | `flutter analyze` clean, `flutter test` passes. |
| 3 | Deploy: `php artisan optimize:clear`, build and install the debug APK. | App launches on the emulator. |
| 4 | Pull, commit, push. | `git push` succeeds. |

## 8. Files

**New:** `lib/screens/change_password_screen.dart`.
**Edited (API):** `routes/api.php`, `AuthController.php`, `HouseholdController.php`, `ChoreStateAndIntegrityTest.php` (or a new `AccountAndHouseholdTest.php`).
**Edited (app):** `services/auth_service.dart`, `services/household_service.dart`, `screens/edit_profile_screen.dart`, `screens/household_view.dart`, `screens/home_shell.dart`, `test/features_and_fixes_test.dart`.

## 9. Rollback

No migration is added. `git revert` the commit, run `php artisan optimize:clear`, and rebuild the APK.
