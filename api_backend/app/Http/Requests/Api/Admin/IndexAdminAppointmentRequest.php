<?php

namespace App\Http\Requests\Api\Admin;

use App\Models\Appointment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class IndexAdminAppointmentRequest extends FormRequest
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
            'search' => ['nullable', 'string', 'max:150'],
            'status' => [
                'nullable',
                'string',
                Rule::in(Appointment::STATUSES),
            ],
            'department_id' => [
                'nullable',
                'integer',
                'exists:departments,id',
            ],
            'date' => ['nullable', 'date_format:Y-m-d'],
            'from_date' => ['nullable', 'date_format:Y-m-d'],
            'to_date' => [
                'nullable',
                'date_format:Y-m-d',
                'after_or_equal:from_date',
            ],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ];
    }
}
