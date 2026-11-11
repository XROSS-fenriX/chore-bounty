<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateBountyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $merge = [];

        // Support category input to map to difficulty
        if (! $this->has('difficulty') && $this->has('category')) {
            $cat = strtolower((string) $this->input('category'));
            $merge['difficulty'] = match ($cat) {
                'hard', 'epic' => 'hard',
                'medium', 'moderate' => 'medium',
                default => 'easy',
            };
        }

        // Support points as reward_value
        if (! $this->has('reward_value') && $this->has('points')) {
            $merge['reward_value'] = (float) $this->input('points');
        }

        // Align xp_reward to reward_value
        if ($this->has('points') && ! $this->has('xp_reward')) {
            $merge['xp_reward'] = (int) $this->input('points');
        }

        if ($this->has('reward_value') && ! $this->has('reward_description')) {
            $merge['reward_description'] = (int) $this->input('reward_value').' Tokens';
        }

        if ($merge) {
            $this->merge($merge);
        }
    }

    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:1000'],
            'difficulty' => ['sometimes', 'required', Rule::in(['easy', 'medium', 'hard', 'epic'])],
            'xp_reward' => ['nullable', 'integer', 'min:10', 'max:1000'],
            'reward_value' => ['nullable', 'numeric', 'min:0'],
            'reward_description' => ['sometimes', 'required', 'string', 'max:255'],
            'due_at' => ['nullable', 'date'],
        ];
    }
}
