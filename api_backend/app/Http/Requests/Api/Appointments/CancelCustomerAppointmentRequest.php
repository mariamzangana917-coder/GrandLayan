<?php

namespace App\Http\Requests\Api\Appointments;

use Illuminate\Foundation\Http\FormRequest;

class CancelCustomerAppointmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null
            && (bool) $user->is_active
            && $user->hasRole('customer');
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'reason' => [
                'nullable',
                'string',
                'max:1000',
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'reason.string' => 'سبب الإلغاء غير صالح.',
            'reason.max' => 'سبب الإلغاء طويل جدًا.',
        ];
    }
}