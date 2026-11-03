<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBountyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $merge = [];

        if (! $this->has('household_id') || empty($this->input('household_id'))) {
            $headerId = $this->header('X-Household-Id');
            if ($headerId) {
                $merge['household_id'] = (int) $headerId;
            } elseif ($this->user()) {
                $firstHousehold = $this->user()->households()->first();
                if ($firstHousehold) {
                    $merge['household_id'] = $firstHousehold->id;
                }
            }
        }

        // Support both category and difficulty inputs
        if (! $this->has('difficulty') && $this->has('category')) {
            $cat = strtolower((string) $this->input('category'));
            $merge['difficulty'] = match ($cat) {
                'hard', 'epic' => 'hard',
                'medium', 'moderate' => 'medium',
                default => 'easy',
            };
        } elseif (! $this->has('difficulty')) {
            $merge['difficulty'] = 'easy';
        }

        // Support points as xp_reward or reward_value
        if (! $this->has('xp_reward')) {
            $difficulty = $this->input('difficulty') ?? ($merge['difficulty'] ?? 'easy');
            $merge['xp_reward'] = match ($difficulty) {
                'epic' => 500,
                'hard' => 200,
                'medium' => 100,
                default => 50,
            };
        }

        if (! $this->has('reward_value') && $this->has('points')) {
            $merge['reward_value'] = (float) $this->input('points');
        }

        if ($merge) {
            $this->merge($merge);
        }
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
            'due_at' => ['nullable', 'date'],
        ];
    }
}
