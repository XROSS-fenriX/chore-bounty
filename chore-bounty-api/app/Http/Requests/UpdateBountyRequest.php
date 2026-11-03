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
