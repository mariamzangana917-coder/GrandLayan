<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RefundGiftCardRequest extends FormRequest
{
    /**
     * Determine whether the user is authorized.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'appointment_id' => [
                'required',
                'integer',
                'exists:appointments,id',
            ],

            'amount' => [
                'required',
                'numeric',
                'gt:0',
            ],

            'notes' => [
                'nullable',
                'string',
                'max:1000',
            ],
        ];
    }

    /**
     * Custom Arabic validation messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'appointment_id.required' => 'يجب تحديد الحجز.',
            'appointment_id.integer' => 'معرّف الحجز غير صحيح.',
            'appointment_id.exists' => 'الحجز المحدد غير موجود.',

            'amount.required' => 'يجب إدخال مبلغ الاسترجاع.',
            'amount.numeric' => 'مبلغ الاسترجاع يجب أن يكون رقمًا صحيحًا.',
            'amount.gt' => 'مبلغ الاسترجاع يجب أن يكون أكبر من صفر.',

            'notes.string' => 'الملاحظات يجب أن تكون نصًا.',
            'notes.max' => 'يجب ألا تتجاوز الملاحظات 1000 حرف.',
        ];
    }
}