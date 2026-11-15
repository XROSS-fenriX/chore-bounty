<?php

namespace Database\Seeders;

use App\Models\Bounty;
use App\Models\BountyClaim;
use App\Models\BountyCompletion;
use App\Models\Household;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class Apartment4AChoresSeeder extends Seeder
{
    /**
     * Create Amy Farrah Fowler, add her to Apartment 4A, and seed 5 chores from each member.
     */
    public function run(): void
    {
        $household = Household::query()
            ->where('name', 'Apartment 4A')
            ->first();

        if (! $household) {
            $owner = User::firstOrCreate(
                ['email' => 'leonard@gmail.com'],
                [
                    'first_name' => 'Leonard',
                    'last_name' => 'Hofstadter',
                    'gender' => 'male',
                    'avatar' => 'guy_2',
                    'password' => Hash::make('password'),
                ]
            );

            $household = Household::firstOrCreate(
                ['invite_code' => 'BDVAUBRV'],
                [
                    'name' => 'Apartment 4A',
                    'created_by' => $owner->id,
                ]
            );

            $household->members()->syncWithoutDetaching([
                $owner->id => ['role' => 'owner', 'joined_at' => now()],
            ]);
        }

        $amy = User::updateOrCreate(
            ['email' => 'amy.fowler@gmail.com'],
            [
                'first_name' => 'Amy',
                'middle_name' => 'Farrah',
                'last_name' => 'Fowler',
                'gender' => 'female',
                'avatar' => 'gal_2',
                'password' => Hash::make('password'),
            ]
        );

        $household->members()->syncWithoutDetaching([
            $amy->id => [
                'role' => 'member',
                'joined_at' => now(),
            ],
        ]);

        $members = $household->members()->orderBy('users.id')->get()->values();
        $memberCount = $members->count();

        $choreSets = $this->choreTemplates();

        foreach ($members as $memberIndex => $creator) {
            $templates = $choreSets[$memberIndex % count($choreSets)];
            $assignee = $memberCount > 1
                ? $members[($memberIndex + 1) % $memberCount]
                : null;

            foreach ($templates as $offset => $spec) {
                $status = $spec['status'];
                $hasAssignee = $assignee !== null && in_array($status, ['claimed', 'submitted'], true);
                $dueAt = now()->addDays($offset + 1)->setTime(18, 0);

                $bounty = Bounty::firstOrCreate(
                    [
                        'household_id' => $household->id,
                        'created_by' => $creator->id,
                        'title' => $spec['title'],
                    ],
                    [
                        'assignee_id' => $hasAssignee ? $assignee->id : null,
                        'description' => $spec['description'],
                        'category' => $spec['category'],
                        'difficulty' => $spec['difficulty'],
                        'xp_reward' => $spec['tokens'],
                        'reward_value' => $spec['tokens'],
                        'reward_description' => "{$spec['tokens']} Tokens",
                        'status' => $status,
                        'submission_proof' => $status === 'submitted'
                            ? ($spec['proof'] ?? 'Completed and ready for review.')
                            : null,
                        'claimed_at' => $hasAssignee ? now()->subHours(4) : null,
                        'submitted_at' => $status === 'submitted' ? now()->subHour() : null,
                        'due_at' => $dueAt,
                    ]
                );

                if ($hasAssignee && $bounty->wasRecentlyCreated) {
                    $claim = BountyClaim::create([
                        'bounty_id' => $bounty->id,
                        'user_id' => $assignee->id,
                        'status' => 'active',
                        'claimed_at' => $bounty->claimed_at ?? now()->subHours(4),
                    ]);

                    if ($status === 'submitted') {
                        BountyCompletion::create([
                            'bounty_claim_id' => $claim->id,
                            'submission_note' => $bounty->submission_proof,
                            'status' => 'pending',
                            'submitted_at' => $bounty->submitted_at ?? now()->subHour(),
                        ]);
                    }
                }
            }
        }
    }

    /**
     * Distinct 5-chore templates per user across categories and lifecycle states.
     */
    private function choreTemplates(): array
    {
        return [
            [
                [
                    'title' => 'Disinfect whiteboard & desk markers',
                    'description' => 'Wipe down the main living room whiteboards and cap all dry-erase markers.',
                    'category' => 'Cleaning',
                    'difficulty' => 'easy',
                    'tokens' => 20,
                    'status' => 'open',
                ],
                [
                    'title' => 'Restock sparkling water & chamomile tea',
                    'description' => 'Pick up 2 packs of sparkling water and herbal tea bags from the grocery store.',
                    'category' => 'Groceries',
                    'difficulty' => 'easy',
                    'tokens' => 25,
                    'status' => 'open',
                ],
                [
                    'title' => 'Organize refrigerator shelf labels',
                    'description' => 'Discard expired condiments and align labeled bins on each fridge shelf.',
                    'category' => 'Kitchen',
                    'difficulty' => 'medium',
                    'tokens' => 35,
                    'status' => 'claimed',
                ],
                [
                    'title' => 'Take out recycling & compost bins',
                    'description' => 'Sort paper, glass, and compost and bring all bags down to the curb.',
                    'category' => 'Trash',
                    'difficulty' => 'easy',
                    'tokens' => 20,
                    'status' => 'submitted',
                    'proof' => 'All recycling and compost bins emptied and relined.',
                ],
                [
                    'title' => 'Wash & fold living room throw blankets',
                    'description' => 'Run gentle cycle with mild detergent and fold blankets onto the couch.',
                    'category' => 'Laundry',
                    'difficulty' => 'medium',
                    'tokens' => 30,
                    'status' => 'open',
                ],
            ],
            [
                [
                    'title' => 'Clean espresso machine & drip tray',
                    'description' => 'Descale the group head, rinse the carafe, and empty coffee grounds.',
                    'category' => 'Kitchen',
                    'difficulty' => 'medium',
                    'tokens' => 30,
                    'status' => 'open',
                ],
                [
                    'title' => 'Replace flickering hallway LED bulb',
                    'description' => 'Swap out the dim hallway ceiling bulb using spare warm-white LEDs.',
                    'category' => 'Maintenance',
                    'difficulty' => 'easy',
                    'tokens' => 20,
                    'status' => 'open',
                ],
                [
                    'title' => 'Vacuum hallway & entryway rug',
                    'description' => 'Vacuum along baseboards and shake out the doormat outside Apartment 4A.',
                    'category' => 'Cleaning',
                    'difficulty' => 'medium',
                    'tokens' => 35,
                    'status' => 'claimed',
                ],
                [
                    'title' => 'Buy olive oil, garlic, and sourdough',
                    'description' => 'Grab cooking essentials from Trader Joe\'s before dinner prep.',
                    'category' => 'Groceries',
                    'difficulty' => 'easy',
                    'tokens' => 25,
                    'status' => 'submitted',
                    'proof' => 'Groceries stored in pantry and receipt placed on counter.',
                ],
                [
                    'title' => 'Clear & wipe dining table surface',
                    'description' => 'Stack mail neatly in the tray and sanitize the wooden dining table.',
                    'category' => 'Cleaning',
                    'difficulty' => 'easy',
                    'tokens' => 15,
                    'status' => 'open',
                ],
            ],
            [
                [
                    'title' => 'Scrub bathroom sink & polish mirror',
                    'description' => 'Clean faucet hardware, wipe vanity counter, and remove water spots from mirror.',
                    'category' => 'Cleaning',
                    'difficulty' => 'medium',
                    'tokens' => 30,
                    'status' => 'open',
                ],
                [
                    'title' => 'Wash kitchen dish towels & aprons',
                    'description' => 'Launder used dish cloths and hang clean towels on the oven bar.',
                    'category' => 'Laundry',
                    'difficulty' => 'easy',
                    'tokens' => 20,
                    'status' => 'open',
                ],
                [
                    'title' => 'Pick up oat milk & fresh fruit',
                    'description' => 'Get two cartons of oat milk, bananas, and berries for breakfast.',
                    'category' => 'Groceries',
                    'difficulty' => 'easy',
                    'tokens' => 25,
                    'status' => 'claimed',
                ],
                [
                    'title' => 'Empty bathroom & study trash cans',
                    'description' => 'Collect small wastebasket liners and tie up with main kitchen trash.',
                    'category' => 'Trash',
                    'difficulty' => 'easy',
                    'tokens' => 15,
                    'status' => 'submitted',
                    'proof' => 'Replaced all trash liners across bathroom and study.',
                ],
                [
                    'title' => 'Tighten loose kitchen cabinet hinge',
                    'description' => 'Use a Phillips screwdriver to level and secure the spice cabinet door.',
                    'category' => 'Maintenance',
                    'difficulty' => 'medium',
                    'tokens' => 35,
                    'status' => 'open',
                ],
            ],
            [
                [
                    'title' => 'Sanitize kitchen counters & stovetop',
                    'description' => 'Degrease burner grates, wipe backsplash, and clear crumb trays.',
                    'category' => 'Kitchen',
                    'difficulty' => 'medium',
                    'tokens' => 35,
                    'status' => 'open',
                ],
                [
                    'title' => 'Sweep balcony & water potted herbs',
                    'description' => 'Sweep dried leaves off the balcony and water basil and rosemary.',
                    'category' => 'Cleaning',
                    'difficulty' => 'easy',
                    'tokens' => 20,
                    'status' => 'open',
                ],
                [
                    'title' => 'Sort & wash shared bath mats',
                    'description' => 'Wash bath mats on warm cycle and tumble dry on low heat.',
                    'category' => 'Laundry',
                    'difficulty' => 'easy',
                    'tokens' => 25,
                    'status' => 'claimed',
                ],
                [
                    'title' => 'Restock paper towels & hand soap',
                    'description' => 'Pick up a 6-pack of paper towels and lavender liquid soap refills.',
                    'category' => 'Groceries',
                    'difficulty' => 'easy',
                    'tokens' => 25,
                    'status' => 'submitted',
                    'proof' => 'Soap dispensers refilled and spare rolls stacked under sink.',
                ],
                [
                    'title' => 'Check smoke detector batteries',
                    'description' => 'Test hallway and kitchen alarms and replace any low 9V batteries.',
                    'category' => 'Maintenance',
                    'difficulty' => 'medium',
                    'tokens' => 40,
                    'status' => 'open',
                ],
            ],
        ];
    }
}
