<?php

namespace App\Http\Requests\Api\Admin;

use App\Models\Appointment;
use Illuminate\Foundation\Http\FormRequest;

class UpdateAdminAppointmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        $appointment = $this->route('appointment');

        return $this->user()?->hasRole('manager') === true
            && $appointment instanceof Appointment
            && $appointment->canBeEdited();
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'requested_start_at' => [
                'sometimes',
                'required',
                'date',
                'after:now',
            ],
            'confirmed_start_at' => [
                'sometimes',
                'nullable',
                'date',
                'after:now',
            ],
            'admin_notes' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ];
    }
}
