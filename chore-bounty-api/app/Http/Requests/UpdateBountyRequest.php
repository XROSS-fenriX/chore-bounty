<?php

namespace App\Http\Requests;

use Carbon\Carbon;
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
        $bounty = $this->route('bounty');
        $dueAtRules = ['nullable', 'date'];
        if ($this->filled('due_at')) {
            try {
                $incoming = Carbon::parse((string) $this->input('due_at'));
                $existing = $bounty?->due_at;
                if (! $existing || ! $incoming->equalTo($existing)) {
                    $dueAtRules[] = 'after:now';
                }
            } catch (\Throwable) {
                // Let the 'date' rule handle invalid date strings.
            }
        }

        return [
            'title' => ['sometimes', 'required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:1000'],
            'difficulty' => ['sometimes', 'required', Rule::in(['easy', 'medium', 'hard', 'epic'])],
            'category' => ['sometimes', 'nullable', 'string', 'max:50'],
            'xp_reward' => ['nullable', 'integer', 'min:1', 'max:100000'],
            'reward_value' => ['nullable', 'numeric', 'min:0', 'max:100000'],
            'points' => ['sometimes', 'nullable', 'integer', 'min:0', 'max:100000'],
            'reward_description' => ['sometimes', 'required', 'string', 'max:255'],
            'due_at' => $dueAtRules,
        ];
    }

    public function messages(): array
    {
        return [
            'due_at.after' => 'Due date and time must be in the future.',
        ];
    }
}
