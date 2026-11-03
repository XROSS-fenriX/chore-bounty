# ChoreBounty: Architectural Implementation Plan
**Gamified Roommate Task Board System**

---

## 1. System Architecture & High-Level Flow

### 1.1 Executive Overview
**ChoreBounty** transforms mundane shared-apartment responsibilities into a cooperative RPG-styled quest board. Household members post tasks as "Bounties" backed by tangible incentives (e.g., *"Take out recycling ➔ Free Oat Milk Latte"* or *"$10 Chore Credit"*). Roommates claim bounties, upload proof of completion, earn XP/points, and climb the household leaderboard.

The platform is architected as a decoupled, multi-tenant mobile-first solution:
* **Backend API**: Laravel 11/12+ RESTful service with Sanctum token authentication, Route Model Binding, granular Policy authorization, and Eloquent aggregates.
* **Frontend Mobile App**: Flutter 3.x cross-platform client featuring an RPG "Quest Board" design language, reactive state management, and a robust Dio network layer.

```
                      +---------------------------------------+
                      |         Flutter Mobile App            |
                      |  (Quest Board UI / RPG Theme / Dio)   |
                      +-------------------+-------------------+
                                          |
                                          | HTTPS / JSON
                                          | Bearer Token (Sanctum)
                                          v
                      +---------------------------------------+
                      |          Laravel 11+ REST API         |
                      |  - Sanctum Auth Middleware            |
                      |  - Route Model Binding ({bounty})     |
                      |  - BountyPolicy Authorization         |
                      |  - Eloquent ORM & Aggregates          |
                      +-------------------+-------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |          Relational Database          |
                      | (MySQL / PostgreSQL / SQLite in Dev)  |
                      +---------------------------------------+
```

---

### 1.2 End-to-End Bounty Lifecycle State Machine

A Bounty progresses through a strictly validated state machine. Every state change is protected by Route Model Binding and Laravel Policies.

```
 [Draft / Creation]
         |
         v
     +-------+         Claim Task
     | OPEN  | ------------------------+
     +-------+                         |
         |                             v
         | Cancel (Creator)     +-------------+
         |                      |   CLAIMED   | <---------------+
         v                      | (In Progress)                 |
   +-----------+                +-------------+                 |
   | CANCELLED |                       |                        |
   +-----------+                       | Submit Proof           | Reject Proof
                                       v                        | (With Feedback)
                                +-------------+                 |
                                |  SUBMITTED  | ----------------+
                                | (Under Rev) |
                                +-------------+
                                       |
                                       | Verify / Approve (Creator)
                                       v
                                +-------------+
                                |  COMPLETED  |
                                |  (Rewarded) |
                                +-------------+
```

#### State Definitions & Transition Rules
| Status Enum | Description | Permitted Actor | Allowed Next States |
| :--- | :--- | :--- | :--- |
| `open` | Bounty posted on household board, available for any roommate to accept. | Creator | `claimed`, `cancelled`, `expired` |
| `claimed` | Roommate has claimed the quest; lock is active so others cannot claim. | Assignee / Creator | `submitted`, `open` (abandoned/released) |
| `submitted` | Assignee completed chore, submitted optional notes/photo proof; awaiting review. | Assignee | `completed` (approved), `claimed` (rejected/redo) |
| `completed` | Creator verified work; reward redemption recorded and XP awarded. | Creator / Admin | *Terminal state* (Archived) |
| `cancelled` | Creator withdrew the bounty before completion. | Creator | *Terminal state* |
| `expired` | Due date passed without completion; automatically marked stale. | System Cron | `open` (relisted), `cancelled` |

---

### 1.3 Authentication & Multi-Tenancy Strategy

Roommates live in isolated "Households". Data from Household A must never be accessible or visible to members of Household B.

```
+-------------------------------------------------------------------------+
|                              Multi-Tenancy                              |
|                                                                         |
|   +-----------------------+              +--------------------------+   |
|   |   User (Sanctum Auth) |              |      Household Model     |   |
|   |   id: 42              | <==========> |      id: 7               |   |
|   |   name: "Alex"        |  belongsTo-  |      name: "Apt 4B"      |   |
|   +-----------------------+   Many (via  |      invite_code: "B4CK" |   |
|                               pivot)     +-------------+------------+   |
|                                                        |                |
|                                             hasMany    | (Scope:        |
|                                                        |  household_id) |
|                                                        v                |
|                                          +--------------------------+   |
|                                          |       Bounties           |   |
|                                          |   household_id = 7       |   |
|                                          +--------------------------+   |
+-------------------------------------------------------------------------+
```

1. **Authentication (Laravel Sanctum)**:
   * Stateful/token-based API authentication issuing personal access tokens via `POST /api/auth/login` and `POST /api/auth/register`.
   * Flutter securely persists the token in platform-native keychain/keystore via `flutter_secure_storage`.
   * Mobile requests include header: `Authorization: Bearer <token>`.

2. **Tenant Boundary (Household Group Isolation)**:
   * Every Bounty, Claim, and Leaderboard stat is strictly bound by `household_id`.
   * Users can belong to one or more households via the `household_user` pivot table with assigned roles (`admin`, `member`).
   * **Active Household Context**: Mobile clients pass `X-Household-Id: {id}` header.
   * **Middleware Enforcement**: An `EnsureBelongsToHousehold` middleware validates that the authenticated `request()->user()` possesses an active membership in the requested household before executing any controller logic.

---

## 2. Laravel Backend Architecture

### 2.1 Database Schema & Migrations

#### A. `users` Table
```sql
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->timestamp('email_verified_at')->nullable();
    $table->string('password');
    $table->string('avatar_url')->nullable();
    $table->rememberToken();
    $table->timestamps();
});
```

#### B. `households` Table
```sql
Schema::create('households', function (Blueprint $table) {
    $table->id();
    $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
    $table->string('name', 100);
    $table->string('invite_code', 16)->unique();
    $table->timestamps();
});
```

#### C. `household_user` (Pivot Table)
```sql
Schema::create('household_user', function (Blueprint $table) {
    $table->id();
    $table->foreignId('household_id')->constrained('households')->cascadeOnDelete();
    $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
    $table->enum('role', ['admin', 'member'])->default('member');
    $table->timestamp('joined_at')->useCurrent();
    $table->timestamps();

    $table->unique(['household_id', 'user_id']);
    $table->index(['user_id', 'household_id']);
});
```

#### D. `bounties` Table
```sql
Schema::create('bounties', function (Blueprint $table) {
    $table->id();
    $table->foreignId('household_id')->constrained('households')->cascadeOnDelete();
    $table->foreignId('creator_id')->constrained('users')->cascadeOnDelete();
    $table->foreignId('assignee_id')->nullable()->constrained('users')->nullOnDelete();
    
    // Core Quest Attributes
    $table->string('title', 150);
    $table->text('description')->nullable();
    $table->enum('difficulty', ['easy', 'medium', 'hard', 'epic'])->default('easy');
    $table->unsignedInteger('xp_reward')->default(50);
    
    // Real-World Reward
    $table->decimal('reward_value', 8, 2)->nullable(); // e.g. 10.00 (dollars)
    $table->string('reward_description', 255);          // e.g. "Free venti oat milk latte"
    
    // State Tracking
    $table->enum('status', ['open', 'claimed', 'submitted', 'completed', 'cancelled', 'expired'])
          ->default('open');
    $table->text('submission_proof')->nullable();        // Notes or image/receipt URL
    $table->timestamp('claimed_at')->nullable();
    $table->timestamp('submitted_at')->nullable();
    $table->timestamp('completed_at')->nullable();
    $table->timestamp('due_at')->nullable();
    
    $table->timestamps();
    $table->softDeletes();

    $table->index(['household_id', 'status']);
    $table->index(['assignee_id', 'status']);
    $table->index(['creator_id']);
});
```

---

### 2.2 Eloquent Models & Relationships

#### Model: `App\Models\User`
```php
namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = ['name', 'email', 'password', 'avatar_url'];
    protected $hidden = ['password', 'remember_token'];

    public function households(): BelongsToMany
    {
        return $this->belongsToMany(Household::class, 'household_user')
            ->withPivot(['id', 'role', 'joined_at'])
            ->withTimestamps();
    }

    public function createdBounties(): HasMany
    {
        return $this->hasMany(Bounty::class, 'creator_id');
    }

    public function assignedBounties(): HasMany
    {
        return $this->hasMany(Bounty::class, 'assignee_id');
    }

    public function completedBounties(): HasMany
    {
        return $this->hasMany(Bounty::class, 'assignee_id')
            ->where('status', 'completed');
    }
}
```

#### Model: `App\Models\Household`
```php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Household extends Model
{
    protected $fillable = ['created_by', 'name', 'invite_code'];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function members(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'household_user')
            ->withPivot(['id', 'role', 'joined_at'])
            ->withTimestamps();
    }

    public function bounties(): HasMany
    {
        return $this->hasMany(Bounty::class);
    }
}
```

#### Model: `App\Models\Bounty`
```php
namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Bounty extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'household_id',
        'creator_id',
        'assignee_id',
        'title',
        'description',
        'difficulty',
        'xp_reward',
        'reward_value',
        'reward_description',
        'status',
        'submission_proof',
        'claimed_at',
        'submitted_at',
        'completed_at',
        'due_at',
    ];

    protected function casts(): array
    {
        return [
            'reward_value' => 'decimal:2',
            'xp_reward' => 'integer',
            'claimed_at' => 'datetime',
            'submitted_at' => 'datetime',
            'completed_at' => 'datetime',
            'due_at' => 'datetime',
        ];
    }

    // Relationships
    public function household(): BelongsTo
    {
        return $this->belongsTo(Household::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assignee_id');
    }

    // Local Scopes
    public function scopeForHousehold(Builder $query, int $householdId): Builder
    {
        return $query->where('household_id', $householdId);
    }

    public function scopeOpen(Builder $query): Builder
    {
        return $query->where('status', 'open');
    }

    public function scopeClaimedBy(Builder $query, int $userId): Builder
    {
        return $query->where('assignee_id', $userId)->where('status', 'claimed');
    }
}
```

---

### 2.3 Leaderboard Statistics & Aggregations

To determine which roommate rules the leaderboard, we aggregate completed bounties, sum rewards, and calculate total XP earned using Eloquent query scopes.

```php
namespace App\Services;

use App\Models\Household;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class LeaderboardService
{
    /**
     * Fetch household leaderboard ranking with completed bounty count and accumulated XP/rewards.
     */
    public function getHouseholdLeaderboard(Household $household): Collection
    {
        return $household->members()
            ->withCount([
                'assignedBounties as completed_bounties_count' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                          ->where('status', 'completed');
                },
                'assignedBounties as active_bounties_count' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                          ->whereIn('status', ['claimed', 'submitted']);
                }
            ])
            ->withSum([
                'assignedBounties as total_xp_earned' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                          ->where('status', 'completed');
                }
            ], 'xp_reward')
            ->withSum([
                'assignedBounties as total_reward_value' => function ($query) use ($household) {
                    $query->where('household_id', $household->id)
                          ->where('status', 'completed');
                }
            ], 'reward_value')
            ->orderByDesc('completed_bounties_count')
            ->orderByDesc('total_xp_earned')
            ->get()
            ->map(function ($user, $index) {
                return [
                    'rank' => $index + 1,
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'avatar_url' => $user->avatar_url,
                    'completed_bounties_count' => (int) $user->completed_bounties_count,
                    'active_bounties_count' => (int) $user->active_bounties_count,
                    'total_xp' => (int) ($user->total_xp_earned ?? 0),
                    'total_reward_value' => (float) ($user->total_reward_value ?? 0.0),
                    'tier' => $this->calculateRpgTier((int) ($user->total_xp_earned ?? 0)),
                ];
            });
    }

    private function calculateRpgTier(int $xp): string
    {
        return match (true) {
            $xp >= 1000 => 'Grandmaster Roommate',
            $xp >= 500  => 'Chore Knight',
            $xp >= 200  => 'Apprentice Sweeper',
            default     => 'Household Novice',
        };
    }
}
```

---

### 2.4 API Routes & Route Model Binding

All bounty mutating operations leverage explicit/implicit Route Model Binding (`{bounty}`).

#### `routes/api.php`
```php
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BountyActionController;
use App\Http\Controllers\BountyController;
use App\Http\Controllers\HouseholdController;
use App\Http\Controllers\LeaderboardController;
use Illuminate\Support\Facades\Route;

// Public Auth Endpoints
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

// Protected Authenticated Endpoints
Route::middleware('auth:sanctum')->group(function () {
    // Current User Session
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Household Management
    Route::apiResource('households', HouseholdController::class);
    Route::post('households/join', [HouseholdController::class, 'joinByCode']);
    Route::get('households/{household}/leaderboard', [LeaderboardController::class, 'index']);

    // Core Bounty RESTful Resource
    Route::apiResource('bounties', BountyController::class);

    // Bounty Lifecycle Actions (Route Model Binding: {bounty})
    Route::prefix('bounties/{bounty}')->group(function () {
        Route::post('/claim', [BountyActionController::class, 'claim']);
        Route::post('/release', [BountyActionController::class, 'release']);
        Route::post('/submit', [BountyActionController::class, 'submit']);
        Route::post('/verify', [BountyActionController::class, 'verify']);
        Route::post('/reject', [BountyActionController::class, 'reject']);
        Route::post('/cancel', [BountyActionController::class, 'cancel']);
    });
});
```

#### Route Matrix
| Verb | URI | Controller Action | Route Model Binding | Policy Check | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/bounties` | `BountyController@index` | - | `viewAny` | Paginated list of bounties for household |
| `POST` | `/api/bounties` | `BountyController@store` | - | `create` | Post a new chore bounty |
| `GET` | `/api/bounties/{bounty}` | `BountyController@show` | `Bounty $bounty` | `view` | Get quest details |
| `PUT` | `/api/bounties/{bounty}` | `BountyController@update` | `Bounty $bounty` | `update` | Edit bounty (title, reward, due date) |
| `DELETE`| `/api/bounties/{bounty}` | `BountyController@destroy`| `Bounty $bounty` | `delete` | Soft delete/withdraw bounty |
| `POST` | `/api/bounties/{bounty}/claim` | `BountyActionController@claim` | `Bounty $bounty` | `claim` | Roommate claims an open bounty |
| `POST` | `/api/bounties/{bounty}/release` | `BountyActionController@release`| `Bounty $bounty` | `release` | Assignee abandons task (back to open) |
| `POST` | `/api/bounties/{bounty}/submit`| `BountyActionController@submit`| `Bounty $bounty` | `submit` | Submit notes/photo proof |
| `POST` | `/api/bounties/{bounty}/verify`| `BountyActionController@verify`| `Bounty $bounty` | `verify` | Creator approves and releases reward |
| `POST` | `/api/bounties/{bounty}/reject`| `BountyActionController@reject`| `Bounty $bounty` | `verify` | Creator rejects proof back to claimed |
| `POST` | `/api/bounties/{bounty}/cancel`| `BountyActionController@cancel`| `Bounty $bounty` | `cancel` | Creator cancels task permanently |

---

### 2.5 Form Requests & Validation

#### `StoreBountyRequest`
```php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBountyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Authorized via Policy in controller
    }

    public function rules(): array
    {
        return [
            'household_id' => ['required', 'exists:households,id'],
            'title' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:1000'],
            'difficulty' => ['required', Rule::in(['easy', 'medium', 'hard', 'epic'])],
            'xp_reward' => ['nullable', 'integer', 'min:10', 'max:1000'],
            'reward_value' => ['nullable', 'numeric', 'min:0'],
            'reward_description' => ['required', 'string', 'max:255'],
            'due_at' => ['nullable', 'date', 'after:now'],
        ];
    }
}
```

#### `SubmitBountyRequest`
```php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SubmitBountyRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'submission_proof' => ['required', 'string', 'max:1000'], // Note, text, or hosted image link
        ];
    }
}
```

#### `ReviewBountyRequest`
```php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReviewBountyRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'feedback' => ['nullable', 'string', 'max:500'],
        ];
    }
}
```

---

### 2.6 Authorization & Policies (`BountyPolicy`)

```php
namespace App\Policies;

use App\Models\Bounty;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class BountyPolicy
{
    private function isHouseholdMember(User $user, int $householdId): bool
    {
        return $user->households()->where('households.id', $householdId)->exists();
    }

    public function view(User $user, Bounty $bounty): Response
    {
        return $this->isHouseholdMember($user, $bounty->household_id)
            ? Response::allow()
            : Response::deny('You are not a member of this household.');
    }

    public function create(User $user, int $householdId): Response
    {
        return $this->isHouseholdMember($user, $householdId)
            ? Response::allow()
            : Response::deny('You must belong to this household to create bounties.');
    }

    public function update(User $user, Bounty $bounty): Response
    {
        if ($bounty->creator_id !== $user->id) {
            return Response::deny('Only the bounty creator can update this quest.');
        }

        if ($bounty->status !== 'open') {
            return Response::deny('Cannot edit a bounty that is already in progress or completed.');
        }

        return Response::allow();
    }

    public function delete(User $user, Bounty $bounty): Response
    {
        return $bounty->creator_id === $user->id && $bounty->status === 'open'
            ? Response::allow()
            : Response::deny('Only open bounties can be deleted by their creator.');
    }

    public function claim(User $user, Bounty $bounty): Response
    {
        if (!$this->isHouseholdMember($user, $bounty->household_id)) {
            return Response::deny('You must be a roommate in this household to claim.');
        }

        if ($bounty->creator_id === $user->id) {
            return Response::deny('You cannot claim your own bounty.');
        }

        if ($bounty->status !== 'open') {
            return Response::deny('This bounty is no longer available for claiming.');
        }

        return Response::allow();
    }

    public function release(User $user, Bounty $bounty): Response
    {
        return $bounty->assignee_id === $user->id && $bounty->status === 'claimed'
            ? Response::allow()
            : Response::deny('Only the assigned roommate can forfeit this quest.');
    }

    public function submit(User $user, Bounty $bounty): Response
    {
        return $bounty->assignee_id === $user->id && $bounty->status === 'claimed'
            ? Response::allow()
            : Response::deny('Only the active assignee can submit completion proof.');
    }

    public function verify(User $user, Bounty $bounty): Response
    {
        if ($bounty->creator_id !== $user->id) {
            return Response::deny('Only the creator can verify quest completion.');
        }

        if ($bounty->status !== 'submitted') {
            return Response::deny('Bounty must be submitted for review before verification.');
        }

        return Response::allow();
    }

    public function cancel(User $user, Bounty $bounty): Response
    {
        return $bounty->creator_id === $user->id && in_array($bounty->status, ['open', 'claimed'])
            ? Response::allow()
            : Response::deny('Only the quest creator can cancel active bounties.');
    }
}
```

---

### 2.7 Bounty Action Controller Implementation

```php
namespace App\Http\Controllers;

use App\Http\Requests\ReviewBountyRequest;
use App\Http\Requests\SubmitBountyRequest;
use App\Http\Resources\BountyResource;
use App\Models\Bounty;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class BountyActionController extends Controller
{
    public function claim(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('claim', $bounty);

        $bounty->update([
            'assignee_id' => $request->user()->id,
            'status' => 'claimed',
            'claimed_at' => now(),
        ]);

        return response()->json([
            'message' => 'Quest accepted! Best of luck, adventurer.',
            'data' => new BountyResource($bounty->load(['creator', 'assignee'])),
        ]);
    }

    public function release(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('release', $bounty);

        $bounty->update([
            'assignee_id' => null,
            'status' => 'open',
            'claimed_at' => null,
        ]);

        return response()->json([
            'message' => 'Quest abandoned and returned to the board.',
            'data' => new BountyResource($bounty),
        ]);
    }

    public function submit(SubmitBountyRequest $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('submit', $bounty);

        $bounty->update([
            'submission_proof' => $request->validated('submission_proof'),
            'status' => 'submitted',
            'submitted_at' => now(),
        ]);

        return response()->json([
            'message' => 'Completion proof submitted for roommate verification.',
            'data' => new BountyResource($bounty->load(['creator', 'assignee'])),
        ]);
    }

    public function verify(ReviewBountyRequest $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('verify', $bounty);

        $bounty->update([
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        return response()->json([
            'message' => 'Bounty approved! Reward and XP disbursed to assignee.',
            'data' => new BountyResource($bounty->load(['creator', 'assignee'])),
        ]);
    }

    public function reject(ReviewBountyRequest $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('verify', $bounty);

        $bounty->update([
            'status' => 'claimed', // Revert to claimed so roommate can redo
            'submitted_at' => null,
        ]);

        return response()->json([
            'message' => 'Proof was not approved. Task returned to in-progress.',
            'data' => new BountyResource($bounty->load(['creator', 'assignee'])),
        ]);
    }

    public function cancel(Request $request, Bounty $bounty): JsonResponse
    {
        Gate::authorize('cancel', $bounty);

        $bounty->update(['status' => 'cancelled']);

        return response()->json([
            'message' => 'Bounty cancelled.',
            'data' => new BountyResource($bounty),
        ]);
    }
}
```

---

## 3. Flutter Frontend Architecture

### 3.1 Recommended State Management & Domain Structure

We implement a **Feature-Driven, Domain-Oriented Modular Architecture** using **Riverpod** (or reactive ChangeNotifier/StateNotifier). This architecture cleanly separates:
1. **Data Layer**: DTO models and raw REST requests.
2. **Domain Layer**: Repository abstractions and entity state.
3. **Presentation Layer**: Widgets, dialogs, and UI views.

```
chore_bounty_application/lib/
|-- core/
|   |-- constants/
|   |   |-- api_endpoints.dart
|   |   +-- rpg_theme.dart          # Palette, quest card borders, typography
|   |-- network/
|   |   |-- api_client.dart         # Dio singleton with auth interceptor
|   |   |-- api_exception.dart
|   |   +-- token_storage.dart      # FlutterSecureStorage wrapper
|   +-- widgets/
|       |-- quest_badge.dart
|       |-- rpg_button.dart
|       +-- state_handlers.dart     # Shimmer loaders, empty states, error banners
|-- features/
|   |-- auth/
|   |   |-- data/auth_repository.dart
|   |   |-- presentation/login_screen.dart
|   |   +-- presentation/register_screen.dart
|   |-- bounties/
|   |   |-- data/bounty_repository.dart
|   |   |-- domain/bounty_model.dart
|   |   |-- state/bounty_board_controller.dart
|   |   |-- presentation/quest_board_screen.dart
|   |   |-- presentation/bounty_detail_sheet.dart
|   |   |-- presentation/create_bounty_dialog.dart
|   |   +-- presentation/widgets/quest_card.dart
|   |-- leaderboard/
|   |   |-- data/leaderboard_repository.dart
|   |   |-- domain/leaderboard_entry.dart
|   |   |-- presentation/leaderboard_screen.dart
|   |   +-- presentation/widgets/podium_widget.dart
|   +-- household/
|       |-- data/household_repository.dart
|       |-- domain/household_model.dart
|       +-- presentation/household_switch_dialog.dart
+-- main.dart
```

---

### 3.2 UI/UX & Gamification Layout: Digital Quest Board

The application interface is styled as a fantasy guild's **Digital Quest Noticeboard**.

```
+-----------------------------------------------------------+
| [Avatar]  Apt 4B - Guild Hall                 [Rank #1 👑] |
| Current XP: 850 XP  |  Gold Balance: $25.00               |
+-----------------------------------------------------------+
| [ All Quests ]  [ ⭐ Available ]  [ ⚔️ In Progress ]  [ 📜 Completed ] |
+-----------------------------------------------------------+
|                                                           |
|  +-----------------------------------------------------+  |
|  | [EPIC] Take Out Heavy Garbage & Sort Glass         |  |
|  | Posted by: Sarah  *  Due in 4 hours                 |  |
|  |                                                     |  |
|  | Reward: [ ☕ Free Starbucks Coffee + 100 XP ]      |  |
|  |                                                     |  |
|  | [ ACCEPT BOUNTY (⚔️) ]                               |  |
|  +-----------------------------------------------------+  |
|                                                           |
|  +-----------------------------------------------------+  |
|  | [MED] Scrub Kitchen Counters & Empty Dishwasher    |  |
|  | Assigned to: You  *  STATUS: SUBMITTED (⏳)         |  |
|  |                                                     |  |
|  | Proof: "Ran the cycle, wiped granite counters"     |  |
|  | Awaiting Sarah's review...                          |  |
|  +-----------------------------------------------------+  |
|                                                           |
+-----------------------------------------------------------+
|  [ 📜 Quests ]      [ 🏆 Leaderboard ]      [ ➕ Post Quest ] |
+-----------------------------------------------------------+
```

#### Theme Palette & Gamified Styling Tokens
```dart
// lib/core/constants/rpg_theme.dart
import 'package:flutter/material.dart';

class RpgTheme {
  // Guild Colors
  static const Color boardBackground = Color(0xFF1A1A24);     // Deep Obsidian Slate
  static const Color cardSurface     = Color(0xFF242436);     // Dark Iron Plate
  static const Color parchmentGold   = Color(0xFFFFD166);     // Reward Accent
  static const Color legendaryPurple = Color(0xFFA855F7);     // Epic Quests
  static const Color emeraldVictory  = Color(0xFF10B981);     // Completed Quests
  static const Color crimsonAlert    = Color(0xFFEF4444);     // Urgent Due Dates
  static const Color textMuted       = Color(0xFF9CA3AF);     // Secondary Text

  // Difficulty Badges
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'epic':   return const Color(0xFFA855F7);
      case 'hard':   return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      case 'easy':
      default:       return const Color(0xFF10B981);
    }
  }
}
```

#### Quest Card Widget Component
```dart
// lib/features/bounties/presentation/widgets/quest_card.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/rpg_theme.dart';
import '../../domain/bounty_model.dart';

class QuestCard extends StatelessWidget {
  final BountyModel bounty;
  final VoidCallback onTap;
  final VoidCallback? onClaim;

  const QuestCard({
    super.key,
    required this.bounty,
    required this.onTap,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = RpgTheme.getDifficultyColor(bounty.difficulty);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RpgTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: bounty.status == 'open'
                ? diffColor.withValues(alpha: 0.4)
                : Colors.white10,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Difficulty Tag & Reward Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: diffColor),
                  ),
                  child: Text(
                    bounty.difficulty.toUpperCase(),
                    style: TextStyle(
                      color: diffColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RpgTheme.parchmentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: RpgTheme.parchmentGold),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: RpgTheme.parchmentGold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${bounty.xpReward} XP',
                        style: const TextStyle(
                          color: RpgTheme.parchmentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quest Title
            Text(
              bounty.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Tangible Reward Notice
            Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: Colors.amberAccent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bounty.rewardDescription,
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Actions & Assignee Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Posted by ${bounty.creatorName}',
                  style: const TextStyle(color: RpgTheme.textMuted, fontSize: 12),
                ),
                if (bounty.status == 'open' && onClaim != null)
                  ElevatedButton.icon(
                    onPressed: onClaim,
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('Claim Quest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: diffColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                else
                  _buildStatusPill(bounty.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    String text;
    switch (status) {
      case 'claimed':
        color = Colors.blueAccent;
        text = 'In Progress';
        break;
      case 'submitted':
        color = Colors.orangeAccent;
        text = 'Pending Review';
        break;
      case 'completed':
        color = RpgTheme.emeraldVictory;
        text = 'Completed';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
```

---

### 3.3 Network Layer & Model Serialization

#### `ApiClient` with Dio and Sanctum Interceptor
```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({required String baseUrl, required this.tokenStorage})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final householdId = await tokenStorage.getHouseholdId();
          if (householdId != null) {
            options.headers['X-Household-Id'] = householdId.toString();
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            // Trigger token eviction and auth redirect
            tokenStorage.clear();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
```

#### `BountyModel` Serialization
```dart
// lib/features/bounties/domain/bounty_model.dart
class BountyModel {
  final int id;
  final int householdId;
  final int creatorId;
  final String creatorName;
  final int? assigneeId;
  final String? assigneeName;
  final String title;
  final String? description;
  final String difficulty;
  final int xpReward;
  final double? rewardValue;
  final String rewardDescription;
  final String status;
  final String? submissionProof;
  final DateTime? dueAt;

  BountyModel({
    required this.id,
    required this.householdId,
    required this.creatorId,
    required this.creatorName,
    this.assigneeId,
    this.assigneeName,
    required this.title,
    this.description,
    required this.difficulty,
    required this.xpReward,
    this.rewardValue,
    required this.rewardDescription,
    required this.status,
    this.submissionProof,
    this.dueAt,
  });

  factory BountyModel.fromJson(Map<String, dynamic> json) {
    return BountyModel(
      id: json['id'],
      householdId: json['household_id'],
      creatorId: json['creator_id'],
      creatorName: json['creator']?['name'] ?? 'Roommate',
      assigneeId: json['assignee_id'],
      assigneeName: json['assignee']?['name'],
      title: json['title'],
      description: json['description'],
      difficulty: json['difficulty'] ?? 'easy',
      xpReward: json['xp_reward'] ?? 50,
      rewardValue: json['reward_value'] != null
          ? double.tryParse(json['reward_value'].toString())
          : null,
      rewardDescription: json['reward_description'] ?? '',
      status: json['status'],
      submissionProof: json['submission_proof'],
      dueAt: json['due_at'] != null ? DateTime.parse(json['due_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'household_id': householdId,
    'title': title,
    'description': description,
    'difficulty': difficulty,
    'xp_reward': xpReward,
    'reward_value': rewardValue,
    'reward_description': rewardDescription,
    'due_at': dueAt?.toIso8601String(),
  };
}
```

---

## 4. Step-by-Step Implementation Roadmap

### Phase 1: Backend Scaffolding & DB Models
* [ ] **Task 1.1: Database Migrations Alignment**
  * Update `bounties` migration table to include `creator_id`, `assignee_id`, `xp_reward`, `reward_description`, `reward_value`, and state timestamp columns (`claimed_at`, `submitted_at`, `completed_at`).
  * Ensure `household_user` pivot migration contains `role` (`admin`/`member`) and appropriate unique constraints.
  * Execute `php artisan migrate:fresh --seed`.
* [ ] **Task 1.2: Eloquent Models & Relationship Wiring**
  * In `User.php`: Define `createdBounties()`, `assignedBounties()`, `completedBounties()`, and `households()`.
  * In `Bounty.php`: Wire `creator()`, `assignee()`, `household()`, and casts for `reward_value` and date objects.
  * In `Household.php`: Wire `members()` and `bounties()`.
* [ ] **Task 1.3: Factory & Seeder Creation**
  * Build `HouseholdSeeder`, `UserSeeder`, and `BountySeeder` with realistic RPG chores ("Defeat Mount Dishmore", "Vanquish the Dust Bunnies") for rapid testing.

---

### Phase 2: API Endpoints & Route Model Binding Logic
* [ ] **Task 2.1: Policies & Authorization Rules**
  * Create `BountyPolicy.php` using `php artisan make:policy BountyPolicy --model=Bounty`.
  * Implement claim, submit, verify, cancel, and edit access checks.
  * Register Policy in `App\Providers\AuthServiceProvider` (or Laravel 11 automatic policy discovery).
* [ ] **Task 2.2: Form Request Validation Classes**
  * Create `StoreBountyRequest`, `UpdateBountyRequest`, `SubmitBountyRequest`, and `ReviewBountyRequest`.
* [ ] **Task 2.3: Controllers with Route Model Binding**
  * Refactor `BountyController.php` using `Bounty $bounty` route model binding for `show`, `update`, and `destroy`.
  * Create `BountyActionController.php` for `{bounty}/claim`, `{bounty}/release`, `{bounty}/submit`, `{bounty}/verify`, and `{bounty}/reject`.
* [ ] **Task 2.4: API Resources & Route Testing**
  * Build `BountyResource` and `LeaderboardResource` with formatted output.
  * Write automated Feature tests (`tests/Feature/BountyLifecycleTest.php`) verifying 200/201 responses and 403 Forbidden scenarios.

---

### Phase 3: Flutter Project Setup & Theme/Quest UI Kit
* [ ] **Task 3.1: RPG Design System Tokens**
  * Set up `RpgTheme` with custom colors (Obsidian Slate, Parchment Gold, Legendary Purple).
  * Configure Google Fonts (`Cinzel` for RPG headers, `Outfit` or `Inter` for crisp body copy).
* [ ] **Task 3.2: Reusable Quest Widgets**
  * Build `QuestCard` with status badges, difficulty glow, and claim buttons.
  * Build `QuestBoardFilterBar` with filter chips (`All`, `Available`, `Claimed`, `Completed`).
  * Build `XpProgressBar` and `RpgAvatarBadge` components.
* [ ] **Task 3.3: Interactive Screens & Dialogs**
  * Design `CreateBountyDialog` with difficulty selector and real-world reward input.
  * Design `BountyDetailSheet` for submitting task proof and creator verification.

---

### Phase 4: API Integration & State Management Flow
* [ ] **Task 4.1: Network Layer Hardening**
  * Configure Dio `ApiClient` with Sanctum Bearer token and `X-Household-Id` interceptor.
  * Implement `BountyRepository` and `AuthRepository`.
* [ ] **Task 4.2: Reactive State Management**
  * Wire `BountyBoardNotifier` / State management:
    * Fetch bounties by filter.
    * Optimistic UI update upon claiming or submitting.
    * Pull-to-refresh quest board functionality.
* [ ] **Task 4.3: Authentication & Multi-Household Gate**
  * Implement `AuthGate` to redirect between `LoginScreen`, `HouseholdSelectionScreen`, and `QuestBoardScreen`.

---

### Phase 5: Polishing, Leaderboard Aggregation & Testing
* [ ] **Task 5.1: Leaderboard & Hall of Fame Screen**
  * Integrate `LeaderboardService` on Laravel to calculate completed counts and XP.
  * Build Flutter `LeaderboardScreen` with podium top-3 visual (Crowns/Medals) and tier badges.
* [ ] **Task 5.2: Edge Case Handling & Animations**
  * Micro-animations for quest completion (confetti or level-up particle banner).
  * Handle edge cases: expiration dates, network timeouts, offline retry indicators.
* [ ] **Task 5.3: End-to-End Verification**
  * Execute full verification flow:
    1. Roommate A posts bounty "Mow the front lawn" ($15 + 150 XP).
    2. Roommate B claims quest on mobile device.
    3. Roommate B submits completion note with lawn photo.
    4. Roommate A verifies and approves on device.
    5. Roommate B is awarded 150 XP and rises to #1 on the leaderboard.
