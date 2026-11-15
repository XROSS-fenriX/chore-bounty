# ChoreBounty: Audit, Feature, and Fix Runbook

**Date:** November 15, 2026
**Status:** Plan only. No source files are changed by this document.
**Scope:** Laravel API (`chore-bounty-api`) and Flutter app (`chore_bounty_application`)

Review this document, answer the decisions in section 1, then approve implementation. Section 7 is the deployment procedure.

---

## 1. Decisions to confirm before implementation

Each row has a default. If you do not object, I implement the default.

| ID | Question | Default |
| :-- | :-- | :-- |
| D1 | Your request lists actions per state. I read it as: **Available** = Edit + Delete, **Taken** = Edit + Cancel, **Cancelled / Expired** = Delete only. Is that right? | Yes. If you also want Cancel on Available, it is a one-line UI change. The API already permits it. |
| D2 | "Expired" means an open chore whose due date has passed. The app labels this state **Past Due** today. | Keep the label "Past Due". |
| D3 | Due dates are saved and shown with the wrong timezone (finding B-03). Fixing it moves existing due dates by the user's UTC offset. | Fix the code. Run a one-time SQL shift of -8 hours on existing rows, which is correct only if every user is in UTC+8. Skip the shift if users are in mixed zones. |
| D4 | Leaderboard "section that contributes": I add a **Household summary** card and a **contribution share** bar on each member row. Both use data the API already returns. | Yes. Alternatives: weekly activity chart, recent awards feed. |
| D5 | The approved user gets a new `approved` notification. Other members keep `awarded`. The approved user no longer receives `awarded` for the same event. | Yes, to avoid two notifications for one event. |
| D6 | The repo has no hosting config. Earlier runbooks deploy to a local MySQL database and an Android emulator (`emulator-5554`). I treat that as the "deployed version". | Yes. Tell me if a remote host exists. |

---

## 2. Baseline

- `git status` is clean on `main` (`0b4eb9d`). Remote: `https://github.com/XROSS-fenriX/chore-bounty.git`.
- I could not capture a test baseline during analysis. PHPUnit reports `Cannot open bootstrap script ...\vendor/autoload.php` inside the analysis sandbox, although `vendor/autoload.php` exists and loads with `php -r`. The Flutter toolchain check also did not finish. Phase 0 in section 6 captures both baselines before any edit.
- No database schema change is needed for this plan.

### What already exists (no rebuild needed)

| Capability | Where |
| :-- | :-- |
| Edit / Cancel / Delete row for creator on Available and Taken chores | `bounty_detail_screen.dart` `_buildActionButton` (case 2) |
| Approver dialog "Chore Approved!" | `bounty_detail_screen.dart` `_handleVerify` |
| Persistent notifications, 4 s polling, unread badge | `BountyNotification`, `home_shell.dart` |
| `period` filter (`week`, `month`, `all`) on leaderboard API | `LeaderboardService` |

### Gap against your request

| Request | Today | Change |
| :-- | :-- | :-- |
| Congratulations modal for the approved user | Only the approver sees a dialog. The approved user gets a snackbar and a notification row. | F1 |
| Taken: Edit + Cancel | Shows Edit + Cancel + **Delete**. The API also allows deleting a Taken chore. | F2 |
| Available: Edit + Delete | Shows Edit + **Cancel** + Delete. | F2 |
| Cancelled / Expired: Delete only | Shows a status banner only. The API returns 403 on delete. | F2 |
| Minimalist leaderboard, no crowns, extra section | Podium with crowns, flat list, no period control. | F3 |
| Minimalist chore detail block | Three bordered cards with nested bordered boxes. | F4 |

---

## 3. Audit findings

Severity: **H** = wrong data or lost access, **M** = wrong behavior in a normal flow, **L** = cleanup. "Plan" = fixed by this runbook. "Backlog" = recorded, not changed.

### 3.1 Bugs

| ID | Sev | Location | Finding | Fix | Plan |
| :-- | :-: | :-- | :-- | :-- | :-: |
| B-01 | H | `BountyActionController@claim` | `Gate::authorize` runs before the row lock, and the transaction does not re-check `status`. Two roommates who tap Claim together both pass. The second overwrites `assignee_id` and creates a second `active` claim. | Re-check `status === 'open'` and "not expired" on the locked row. Abort with 422. | Plan |
| B-02 | M | `BountyPolicy@claim` | Only checks `status === 'open'`. The API accepts claims on expired chores although the UI hides the button. | Add the "not expired" check through the shared `Bounty::isAvailable()`. | Plan |
| B-03 | M | `create_bounty_screen.dart:105`, `bounty.dart:220`, `config/app.php` | The app sends `due_at` as a local time string with no offset. The API stores it as UTC. The app parses it back as UTC and never calls `toLocal()`. The text on screen looks right, but the real deadline moves by the user's UTC offset. In UTC+8, chores expire 8 hours late. Server `isFuture()` has the same shift. | Send `toUtc().toIso8601String()`. Parse with `.toLocal()`. See D3 for existing rows. | Plan |
| B-04 | H | `auth_gate.dart` `_restore` | `catch (_)` clears the token on any error. Opening the app offline signs the user out. | Clear storage only on HTTP 401. Keep the token on network errors and show a retry state. | Plan |
| B-05 | M | `BountyActionController@cancel` | No transaction or lock. The active claim stays `active` and a pending completion stays `pending` after cancel. | In a transaction: set the claim to `released`, set a pending completion to `rejected`, then set the bounty to `cancelled`. | Plan |
| B-06 | M | `BountyActionController@reject` | The "Request Redo" note is sent (`feedback`) but never stored. No notification goes to the assignee, so the assignee cannot see the redo request. | Send a `redo` notification to the assignee. Put the note in the description. | Plan |
| B-07 | M | `notifications_screen.dart` | `onSelectBounty` is required but never called. Tapping a card only marks it read. | Open the chore on tap. If the API returns 404 (deleted), show "This chore was deleted." | Plan |
| B-08 | M | `HouseholdController@leave` | Active claims of the leaving user stay `claimed` and block the chore. The UI text says "You will forfeit active quests", but the API does nothing. When the last member leaves, `$household->delete()` throws a foreign key error (`bounties.household_id` is `restrictOnDelete`, and `Household` has no soft deletes), which returns HTTP 500. | In a transaction, release the user's active claims in that household. Do not delete a household that still has chores. | Plan |
| B-09 | L | `BountyCompletionController@update` (legacy reject) | Sets the bounty to `open` but keeps `assignee_id`. | Also set `assignee_id` and `claimed_at` to `null`. | Plan |
| B-10 | M | `LeaderboardService` | `rank = index + 1`. Members with equal tokens get different ranks, and their order is not stable between requests. | Competition ranking (1, 1, 3) and a fixed tie-break: tokens desc, chores desc, name asc, id asc. | Plan |
| B-11 | L | `UpdateBountyRequest` | When `category` is sent without `difficulty`, the request rewrites `difficulty` to `easy`. The app always sends both, so only direct API callers are affected. | Remove the category-to-difficulty merge from update. | Plan |
| B-12 | L | `bounty_detail_screen.dart` `_handleCancel` | Cancel has no confirmation. One tap cancels a Taken chore and notifies the assignee. | Add a confirm dialog, like Delete has. | Plan |
| B-13 | L | `BountyActionController` (4 places) | The token amount `reward_value ?: xp_reward ?: 50` is repeated. `verify` and `complete` are copies of each other. | Add `Bounty::tokens()`. Merge `verify` and `complete` into one private `approve()` method. | Plan |

### 3.2 Improvements

| ID | Sev | Finding | Action | Plan |
| :-- | :-: | :-- | :-- | :-: |
| I-01 | M | The leaderboard only refreshes on pull-to-refresh or tab actions. Polling updates bounties but not rankings, so a new award is not visible until a manual refresh. | Refresh the leaderboard in the poll when the count of completed chores changes. | Plan |
| I-02 | L | Dead code: `core/constants/rpg_theme.dart`, `BountyTile` and `_icon` in `widgets/ui.dart`, `leaderboard_decorations.dart` and `leaderboard_podium.dart` (after F3). | Delete. | Plan |
| I-03 | L | `bounty_detail_screen.dart` is 1,409 lines. | Extract `BountyInfoCard`, `BountyStatusChip`, `CreatorActionBar` while doing F2 and F4. Do not split further. | Plan |
| I-04 | L | `ChoresView` "Completed" filter shows every completed chore not posted by me, not the chores I completed. | Filter by `assigneeId == me`. | Backlog |
| I-05 | L | `HomeShell` and `NotificationsScreen` each poll `/bounties` and `/notifications` every 4 s. Two timers run at once on the notifications page. | Single poller, 10 s interval, pause when the app is in the background. | Backlog |
| I-06 | L | `xp_reward` and `reward_value` both store the token amount. | Merge into one column. Needs a migration, so defer. | Backlog |
| I-07 | L | `DashboardView._tasksOngoing` falls back to the household count when the user has none. The label then misreports. | Return 0. | Backlog |
| I-08 | L | `main.dart` creates `ApiClient` and services inside `build()`. Safe today (the root never rebuilds) but fragile. | Move to `initState` of a `StatefulWidget`. | Backlog |
| I-09 | L | `google_fonts` downloads Nunito at runtime on the auth screens. Offline, they fall back to the default font. | Bundle the font as an asset. | Backlog |
| I-10 | L | `.env.example` ships `APP_DEBUG=true`. | Set `APP_DEBUG=false` on any non-local host. | Backlog |

Already fixed by earlier work and verified in code: logout revokes tokens, token expiry is set (`SANCTUM_EXPIRATION` = 43200), login and register are throttled, household member routes use a policy, avatar assets are small (about 30 KB each).

---

## 4. Rules shared by F1 to F4

### 4.1 Chore state and allowed actions

One definition, used by the policy, the API tests, and the Flutter model.

| State | Condition | Creator can | Other members can |
| :-- | :-- | :-- | :-- |
| Available | `status = open` and (no due date or due date in the future) | Edit, Delete (Cancel by API only) | Claim |
| Taken | `status` is `claimed` or `in_progress` | Edit, Cancel | Assignee: Submit, Abandon |
| Pending review | `status = submitted` | Approve, Request Redo | Assignee: wait |
| Completed | `status = completed` | none | none |
| Cancelled | `status = cancelled` | Delete | none |
| Expired | `status = open` and due date passed | Delete | none |

A Taken chore can be past due. It stays Taken: Edit and Cancel remain, so the creator can extend the date (the case in your screenshot).

### 4.2 Backend

- `Bounty` model gains `isAvailable()`, `isExpired()`, `isTaken()`, `isCancelled()` and `tokens()`. `BountyPolicy` and the controllers call these. Nothing else defines the states.
- Policy changes:
  - `update`: creator and (Available or Taken). Unchanged in effect.
  - `delete`: creator and (Available or Cancelled or Expired). **Taken is no longer deletable.** The creator must cancel first.
  - `cancel`: creator and (Available or Taken). Expired chores can no longer be cancelled. They are deleted.
  - `claim`: adds the Available check (B-02).
- There is no `after:now` rule on `due_at`. A Taken chore can keep a past date when edited.

---

## 5. Features

### F1. Congratulations modal for the approved user

**Trigger.** The API creates an `approved` notification for the assignee when the creator approves (`verify` or `complete`). The app shows the modal when it receives an unread `approved` notification. This happens on the 4 s poll and on app start (covers an assignee who was offline).

**Wireframe**

```
        ( ✓ )            scale-in, 250 ms
    Congratulations!
 Your chore "Buy water" was approved.
        🪙 +10 Tokens
   Approved by Sheldon Cooper
 [      View Leaderboard      ]
            Close
```

Several unread approvals at once show one modal: "3 chores approved", the total tokens, and up to 3 chore titles.

**Style.** White dialog, radius 24, green `#1B8354` check in a `#DCFCE7` circle, token pill `#FEF3C7` with `BountyCoinWidget`. Reuses the look of the existing approver dialog. No confetti and no new package.

**Backend**

| File | Change |
| :-- | :-- |
| `Models/BountyNotification.php` | `dispatchForHousehold(..., array $exceptUserIds = [])`. New `dispatchToUser()`. |
| `BountyActionController.php` | Private `approve()` replaces `verify` and `complete` bodies. It sends `approved` to the assignee. It sends `awarded` to other members except the actor and the assignee. `reject` sends `redo` to the assignee (B-06). |
| `Resources/BountyNotificationResource.php` | Adds `bounty: { id, title, tokens }` when the relation is loaded. |
| `NotificationController.php` | `index` eager loads `bounty` with trashed rows, so a deleted chore still has a title. |

**Frontend**

| File | Change |
| :-- | :-- |
| `models/app_notification.dart` | Parse `bounty_title` and `tokens`. |
| `widgets/dialogs/congratulations_dialog.dart` (new) | Dialog for one or many approvals. |
| `screens/home_shell.dart` | In `_processNotifications`, collect unread `approved` items with numeric ids that are not in `_celebratedIds`. Show the dialog once. On close, call `markNotificationRead` for each id. "View Leaderboard" switches to tab 2. |
| `services/bounty_service.dart` | `markNotificationRead` returns success. The modal is not shown again for an id that is in `_celebratedIds` while the request is in flight or failed. |
| `screens/notifications_screen.dart` | Icon and color for `approved` and `redo`. |

**Rules.** Derived fallback notifications (non-numeric ids such as `bounty_5_awarded`) never trigger the modal. The approver never sees this modal, because the API does not create an `approved` row for the actor.

---

### F2. Edit, Cancel, Delete on the chore page

Follows the matrix in 4.1.

**Frontend**

| File | Change |
| :-- | :-- |
| `models/bounty.dart` | Getters `isTaken`, `isExpired` (same as `isPastDue`), `canEdit`, `canCancel`, `canDelete`. The creator check stays in the screen. |
| `widgets/bounty_detail/creator_action_bar.dart` (new) | Takes a `Bounty`. Renders the buttons for its state. |
| `screens/bounty_detail_screen.dart` | Uses `CreatorActionBar`. Removes banner cases 6 and 7 for the creator (the status chip already shows the state). Adds the Cancel confirm dialog (B-12). |

**Buttons by state (bottom bar, same sizes and colors as today)**

```
Available   [ ✎ Edit ] [ 🗑 Delete ]
Taken       [ ✎ Edit ] [ ✕ Cancel ]
Cancelled   [        🗑 Delete        ]
Expired     [        🗑 Delete        ]
```

Delete is red outline (`#FEF2F2` fill, `#DC2626` text). Cancel is neutral outline. Edit is solid green. Delete and Cancel ask for confirmation. Non-creators see no creator buttons.

**Backend.** Policy changes from 4.2. `cancel` also closes the claim (B-05).

---

### F3. Leaderboard redesign

**Direction.** Flat, quiet, scannable. No podium, no crowns, no medal colors. One white list card with hairline dividers replaces the separate bordered tiles.

**Wireframe**

```
☰  Leaderboard
   Apt 4A · 4 members

 [ Week | Month | All time ]           segmented control

┌──────────────────────────────────────────┐
│  TOKENS EARNED   CHORES DONE   IN PROGRESS │
│      340             28            3       │
│ ──────────────────────────────────────── │
│  You are 2nd · 20 tokens behind Penelope   │
└──────────────────────────────────────────┘

 RANKING
┌──────────────────────────────────────────┐
│ 1  (av)  Penelope Hofstadter     🪙 140   │
│          9 chores · 41%                   │
│          ████████████░░░░░░░░░░           │
│ ──────────────────────────────────────── │
│ 2  (av)  Leonard  [You]          🪙 120   │  row tint #F0FDF4
│          8 chores · 35%                   │
│          ██████████░░░░░░░░░░░░           │
└──────────────────────────────────────────┘
```

**Section that contributes (D4)**

- **Household summary:** total tokens, chores done, chores in progress. Computed from the entries the API returns.
- **Your standing line:** rank and the gap to the next rank up, "You lead by N tokens", or "Tied for 1st". Shows nothing when the user has no entry.
- **Contribution share:** each row shows the member's share of household tokens as a percentage and a 4 px bar.

**Style.** Background `#FAF8F5`. Card white, radius 20, border 1 px `#E2E8F0`. Rank is plain text (14/w700, `#64748B`), identical for all places. A member with 0 tokens shows "–" as rank. The current user's row uses a soft green tint instead of a green border. Tokens are right-aligned, bold, with `BountyCoinWidget` 16 px. Share bar uses green `#1B8354` on `#EEF2F6`. Empty state keeps the existing message and the member list.

**Frontend**

| File | Change |
| :-- | :-- |
| `screens/leaderboard_view.dart` | New layout. Stateful for the selected period. Calls `onPeriodChanged`. |
| `widgets/leaderboard/leaderboard_summary_card.dart` (new) | Summary stats and standing line. |
| `widgets/leaderboard/leaderboard_row.dart` (new) | Replaces `leaderboard_list_tile.dart`. Row with share bar. |
| `widgets/leaderboard/leaderboard_podium.dart`, `leaderboard_decorations.dart`, `leaderboard_list_tile.dart` | Deleted. |
| `screens/home_shell.dart` | Keeps `_leaderboardPeriod`. Passes it to `getLeaderboard` in `refresh()` and in the poll (I-01). |

**Backend.** `LeaderboardService`: tie-aware rank and stable order (B-10). `LeaderboardController`: validate `period` as `in:all,week,month` (default `all`). The response format does not change.

---

### F4. Chore details: top block redesign

This replaces the area in the orange square of your screenshot: the header card, the Description card, and the Details card. "Claimed by" stays a separate card with matching type styles.

**Wireframe**

```
┌──────────────────────────────────────────┐
│ [icon]  Buy water                ● Taken  │
│  56     🪙 10 Tokens · (av) Leonard       │
│ ──────────────────────────────────────── │
│ DESCRIPTION                               │
│ Buy a bottle of water.                    │
│ ──────────────────────────────────────── │
│ DUE                      CATEGORY         │
│ ◷ Nov 13, 8:00 PM        ⌗ Groceries      │
│   Past due                                │
└──────────────────────────────────────────┘
```

**Changes from today**

- Three cards with nested boxes become one card with two hairline dividers.
- The 96 px icon box with a 1.5 px border becomes a 56 px icon on `#F8FAFC`, no border.
- The status badge becomes a small chip: tinted background, 11.5/w600 text, no border. Colors stay as they are now.
- Token amount and poster share one muted meta line.
- Due date and category sit side by side. A past due date shows "Past due" in red `#DC2626` under the date.
- The Description section is hidden when empty. The text "No special instructions." is removed.
- Section labels: 11/w700, uppercase, letter-spacing 0.6, `#94A3B8`. Values: 14/w600, `#1E293B`. Body: 14/w500, `#475569`, line height 1.5.

**Frontend**

| File | Change |
| :-- | :-- |
| `widgets/bounty_detail/bounty_info_card.dart` (new) | The single card. |
| `widgets/bounty_detail/bounty_status_chip.dart` (new) | Chip. Replaces `_buildStatusBadge`. |
| `screens/bounty_detail_screen.dart` | Uses both widgets. Removes the three card blocks and `_buildStatusBadge`. |

---

### Included fixes (no UI change)

| ID | File | Change |
| :-- | :-- | :-- |
| B-01, B-02, B-05 | `BountyActionController`, `BountyPolicy` | Locked re-checks, claim check, cancel closes claim. |
| B-03 | `create_bounty_screen.dart`, `models/bounty.dart` | `toUtc()` on send, `toLocal()` on parse (all five date fields). |
| B-04 | `auth_gate.dart` | Clear token on 401 only. |
| B-07 | `notifications_screen.dart`, `home_shell.dart` | Tap opens the chore. Handle 404. |
| B-08 | `HouseholdController@leave` | Release claims. Never delete a household with chores. |
| B-09, B-11, B-13 | legacy controller, request, `Bounty` model | As in the table. |

---

## 6. Implementation order

Each phase ends with a check. I stop and report if a check fails.

| Phase | Work | Check |
| :-- | :-- | :-- |
| 0 | `git pull origin main`. Run `php artisan test`, `flutter analyze`, `flutter test`. Record results. | Baseline recorded. |
| 1 | Backend: model helpers, policy, `approve()`, notifications, `cancel`, `claim` locks, household leave, legacy reject, update request, leaderboard service. Update existing tests and add the new ones from section 8. | `php artisan test` passes. |
| 2 | Flutter shared: `Bounty` model getters and date parsing, `AppNotification` fields, `BountyService`, `AuthGate`. | `flutter analyze` is clean. |
| 3 | F4 and F2: new `bounty_detail` widgets, detail screen, confirm dialogs. | Widget tests pass. |
| 4 | F1: dialog, `HomeShell` hook, notification styles and tap. | Widget tests pass. |
| 5 | F3: leaderboard widgets and view, period handling, delete old files. | Widget tests pass. |
| 6 | Dead code removal (I-02). Full `flutter analyze` and `flutter test`. | Clean. |
| 7 | Deploy (section 7). Manual QA (section 9). | QA passes. |

---

## 7. Deployment

Based on the procedure in `SYSTEM_ANALYSIS_AND_RUNBOOK.md` (section 5.3). Adjust if D6 differs.

1. **Pull first.**
   ```powershell
   cd d:\www\chore-bounty
   git pull origin main
   ```
   The analysis sandbox cannot write `.git/FETCH_HEAD`, so this step needs a normal (non-sandboxed) shell.
2. **Back up the database** (only if D3 data shift is approved).
   ```powershell
   mysqldump -u root chore_bounty_db > d:\www\chore-bounty-backup-2026-11-15.sql
   ```
3. **API.** No new migrations.
   ```powershell
   cd d:\www\chore-bounty\chore-bounty-api
   php artisan test
   php artisan migrate --force
   php artisan optimize:clear
   ```
   Restart the API process (`php artisan serve --host=0.0.0.0 --port=8000` if that is how it runs now).
4. **D3 data shift** (optional, UTC+8 users only).
   ```sql
   UPDATE bounties SET due_at = DATE_SUB(due_at, INTERVAL 8 HOUR) WHERE due_at IS NOT NULL;
   ```
   Reverse with `DATE_ADD` if needed.
5. **App build and install.**
   ```powershell
   cd d:\www\chore-bounty\chore_bounty_application
   flutter analyze
   flutter test
   flutter build apk --debug --target-platform android-x64 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
   adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
   adb -s emulator-5554 shell am start -n com.example.chore_bounty_application/.MainActivity
   ```
6. **Commit and push.** Pull again, then push. Conventional commits, one per concern:
   - `feat(api): approved and redo notifications, chore state rules`
   - `fix(api): claim and cancel integrity, household leave, leaderboard ranking`
   - `feat(app): congratulations modal, chore actions by state, minimalist details and leaderboard`
   - `fix(app): due date timezone, offline sign-out`
   - `docs: add feature and fix runbook`
   ```powershell
   git pull --rebase origin main
   git push origin main
   ```

**Rollback.** `git revert` the commits and rebuild the APK. There is no schema change. Undo the D3 shift with the reverse SQL, or restore the backup.

---

## 8. Test plan

### 8.1 Existing tests to update

File: `tests/Feature/SecurityAndIntegrityTest.php`, test `test_notifications_lifecycle_and_edit_delete_when_available_or_taken`.

| Lines | Today | After |
| :-- | :-- | :-- |
| 297 | Delete a Taken chore returns 204. | Returns 403. Cancel returns 200, then delete returns 204. |
| 311 to 315 | Delete a Cancelled chore returns 403. | Returns 204. Edit still returns 403. |
| 322 to 328 | The assignee sees `awarded`. | The assignee sees `approved` and not `awarded`. Other members see `awarded`. Unread count updated. |

### 8.2 New backend tests (PHPUnit feature)

- State matrix: for each state in 4.1 and for creator and a non-creator member, assert edit, cancel, delete and claim return the expected status.
- Expired chore: claim returns 403, delete returns 204.
- Taken and past due: edit returns 200 with an unchanged past `due_at`.
- Cancel a Taken chore: the claim becomes `released` and the pending completion becomes `rejected`.
- Second claim on a claimed chore returns 403 or 422, and only one `active` claim exists.
- Approve: the assignee gets one `approved` row, other members get `awarded`, the creator gets none. Payload contains `bounty.title` and `bounty.tokens`.
- Reject with feedback: the assignee gets a `redo` row that contains the note.
- Household leave: the user's claim returns to `open`. Last member leaves a household that has chores: returns 200, household remains.
- Leaderboard: ties share a rank and the order is stable. `period=bogus` returns data for `all`.
- Legacy completion reject clears `assignee_id`.

### 8.3 Flutter tests

- Model: `canEdit`, `canCancel`, `canDelete` for every row of the 4.1 table. `dueAt` is returned in local time.
- `CreatorActionBar`: renders the exact buttons for Available, Taken, Cancelled and Expired.
- `CongratulationsDialog`: single approval and three approvals. Close and "View Leaderboard" both call the read callback.
- `HomeShell`: an unread `approved` notification shows the dialog once. A derived notification does not.
- `LeaderboardView`: no crown widgets, period tap calls the callback, "–" rank for 0 tokens, current user highlighted.
- `AuthGate`: network error keeps the token. 401 clears it.

### 8.4 Gate

`php artisan test`, `flutter analyze` and `flutter test` all pass before deployment.

---

## 9. Manual QA (two accounts: A creates, B claims)

1. A posts a chore. A sees Edit and Delete. B sees Claim.
2. B claims. A sees Edit and Cancel, with no Delete. B sees Submit and Abandon.
3. A edits the due date of the Taken chore to a past time. The chore stays Taken with Edit and Cancel. The date shows "Past due" in red.
4. B submits. A taps Approve. A sees the existing approver dialog. B sees the Congratulations modal within 4 s (or on next app open). Closing it clears the unread badge.
5. A posts a second chore and sets a due time that has passed. It shows Past Due with Delete only. B cannot claim it. Delete removes it.
6. A posts a third chore, B claims it, A cancels. A asks for confirmation. The chore shows Cancelled with Delete only. B gets the cancel notification and tapping it opens the chore.
7. A deletes a chore that B has a notification for. B taps the notification and sees "This chore was deleted."
8. Leaderboard: no crowns. Period control changes the numbers. Summary totals equal the sum of the rows. B's row is tinted. Ties show the same rank.
9. Sign in, put the emulator offline, restart the app. The user stays signed in.
10. Set a due date of "today 8:00 PM". The chore expires at 8:00 PM local time, not 4:00 AM next day.

---

## 10. Files

**New (6 source files):** `lib/widgets/dialogs/congratulations_dialog.dart`, `lib/widgets/bounty_detail/bounty_info_card.dart`, `lib/widgets/bounty_detail/bounty_status_chip.dart`, `lib/widgets/bounty_detail/creator_action_bar.dart`, `lib/widgets/leaderboard/leaderboard_summary_card.dart`, `lib/widgets/leaderboard/leaderboard_row.dart`, plus the new test files.

**Deleted (5):** `lib/widgets/leaderboard/leaderboard_podium.dart`, `leaderboard_decorations.dart`, `leaderboard_list_tile.dart`, `lib/core/constants/rpg_theme.dart`, and `BountyTile` with `_icon` inside `lib/widgets/ui.dart`.

**Edited (API):** `Bounty.php`, `BountyNotification.php`, `BountyPolicy.php`, `BountyActionController.php`, `BountyCompletionController.php`, `HouseholdController.php`, `NotificationController.php`, `LeaderboardController.php`, `LeaderboardService.php`, `BountyNotificationResource.php`, `UpdateBountyRequest.php`, `SecurityAndIntegrityTest.php`, new feature tests.

**Edited (app):** `models/bounty.dart`, `models/app_notification.dart`, `services/bounty_service.dart`, `screens/auth_gate.dart`, `screens/bounty_detail_screen.dart`, `screens/create_bounty_screen.dart`, `screens/home_shell.dart`, `screens/leaderboard_view.dart`, `screens/notifications_screen.dart`, `test/*`.
