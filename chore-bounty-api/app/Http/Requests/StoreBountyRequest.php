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

        // Support tokens/points as reward_value
        if (! $this->has('reward_value') && $this->has('points')) {
            $merge['reward_value'] = (float) $this->input('points');
        } elseif (! $this->has('reward_value')) {
            $merge['reward_value'] = 50.0;
        }

        // Align xp_reward to reward_value for backward compatibility
        if (! $this->has('xp_reward')) {
            $merge['xp_reward'] = (int) ($merge['reward_value'] ?? 50);
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
            'category' => ['nullable', 'string', 'max:50'],
            'xp_reward' => ['nullable', 'integer', 'min:1', 'max:100000'],
            'reward_value' => ['nullable', 'numeric', 'min:0'],
            'reward_description' => ['required', 'string', 'max:255'],
            'due_at' => ['nullable', 'date'],
        ];
    }
}
