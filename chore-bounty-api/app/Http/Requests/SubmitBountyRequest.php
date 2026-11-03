<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SubmitBountyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'submission_proof' => ['nullable', 'string', 'max:1000'],
            'proof_url' => ['nullable', 'string', 'max:2048'],
            'note' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
