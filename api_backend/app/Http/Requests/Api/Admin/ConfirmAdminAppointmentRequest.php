<?php

namespace App\Http\Requests\Api\Admin;

use Illuminate\Foundation\Http\FormRequest;

class ConfirmAdminAppointmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->hasRole('manager') === true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'confirmed_start_at' => [
                'nullable',
                'date',
                'after:now',
            ],
            'admin_notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
