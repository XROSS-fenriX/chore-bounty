<?php

namespace Database\Seeders;

use App\Models\Bounty;
use App\Models\Household;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class Apartment4AChoresSeeder extends Seeder
{
    /**
     * Ensure Apartment 4A exists and seed 3 available tasks posted by each member.
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
        $choreSets = $this->choreTemplates();

        foreach ($members as $memberIndex => $creator) {
            $templates = $choreSets[$memberIndex % count($choreSets)];

            foreach ($templates as $offset => $spec) {
                $dueAt = now()->addDays($offset + 2)->setTime(18, 0);

                Bounty::updateOrCreate(
                    [
                        'household_id' => $household->id,
                        'created_by' => $creator->id,
                        'title' => $spec['title'],
                    ],
                    [
                        'assignee_id' => null,
                        'description' => $spec['description'],
                        'category' => $spec['category'],
                        'difficulty' => $spec['difficulty'],
                        'xp_reward' => $spec['tokens'],
                        'reward_value' => $spec['tokens'],
                        'reward_description' => "{$spec['tokens']} Tokens",
                        'status' => 'open',
                        'submission_proof' => null,
                        'submission_images' => null,
                        'claimed_at' => null,
                        'submitted_at' => null,
                        'completed_at' => null,
                        'due_at' => $dueAt,
                    ]
                );
            }
        }
    }

    /**
     * Distinct 3-chore templates per user—all sensible and available (open).
     *
     * @return array<int, array<int, array<string, mixed>>>
     */
    private function choreTemplates(): array
    {
        return [
            [
                [
                    'title' => 'Wipe down kitchen microwave & toaster',
                    'description' => 'Clean food splatters inside the microwave, wipe the turntable, and empty the toaster crumb tray.',
                    'category' => 'Kitchen',
                    'difficulty' => 'hard',
                    'tokens' => 30,
                ],
                [
                    'title' => 'Sort mail & recycle cardboard boxes',
                    'description' => 'Flatten delivery boxes in the entryway and place sorted mail neatly on the hallway console.',
                    'category' => 'Cleaning',
                    'difficulty' => 'medium',
                    'tokens' => 20,
                ],
                [
                    'title' => 'Restock dishwasher pods & rinse aid',
                    'description' => 'Pick up a fresh tub of dishwasher detergent pods and a bottle of rinse aid from the store.',
                    'category' => 'Groceries',
                    'difficulty' => 'easy',
                    'tokens' => 25,
                ],
            ],
            [
                [
                    'title' => 'Mop kitchen & bathroom tile floors',
                    'description' => 'Sweep dust first, then mop both the kitchen and shared bathroom floors with floor cleaner.',
                    'category' => 'Cleaning',
                    'difficulty' => 'medium',
                    'tokens' => 35,
                ],
                [
                    'title' => 'Wash & dry shared bath towels',
                    'description' => 'Gather damp hand towels and bath towels, wash on warm cycle, and fold onto the linen shelf.',
                    'category' => 'Laundry',
                    'difficulty' => 'medium',
                    'tokens' => 25,
                ],
                [
                    'title' => 'Lubricate squeaky front door hinges',
                    'description' => 'Apply silicone lubricant to the Apartment 4A entry door hinges and wipe away any excess.',
                    'category' => 'Maintenance',
                    'difficulty' => 'hard',
                    'tokens' => 30,
                ],
            ],
            [
                [
                    'title' => 'Vacuum sofa cushions & living room rug',
                    'description' => 'Use the crevice tool under couch cushions and vacuum the central living room rug.',
                    'category' => 'Cleaning',
                    'difficulty' => 'medium',
                    'tokens' => 30,
                ],
                [
                    'title' => 'Restock fresh coffee beans & milk',
                    'description' => 'Grab a bag of medium-roast coffee beans and two cartons of milk for the apartment.',
                    'category' => 'Groceries',
                    'difficulty' => 'easy',
                    'tokens' => 25,
                ],
                [
                    'title' => 'Clean out sink drain & scrub basin',
                    'description' => 'Clear the kitchen sink strainer, scrub the stainless basin, and polish the faucet.',
                    'category' => 'Kitchen',
                    'difficulty' => 'hard',
                    'tokens' => 25,
                ],
            ],
            [
                [
                    'title' => 'Scrub shower glass & replace bath mat',
                    'description' => 'Remove soap film from the shower door, rinse tiles, and lay out a clean bath mat.',
                    'category' => 'Cleaning',
                    'difficulty' => 'medium',
                    'tokens' => 35,
                ],
                [
                    'title' => 'Organize pantry snacks & dry goods',
                    'description' => 'Check expiration dates on pasta, cereal, and tea, and group open bags with airtight clips.',
                    'category' => 'Kitchen',
                    'difficulty' => 'hard',
                    'tokens' => 25,
                ],
                [
                    'title' => 'Tighten loose dining chair screws',
                    'description' => 'Check all four wooden dining chairs and tighten any wobbly leg bolts with an Allen wrench.',
                    'category' => 'Maintenance',
                    'difficulty' => 'hard',
                    'tokens' => 30,
                ],
            ],
        ];
    }
}
