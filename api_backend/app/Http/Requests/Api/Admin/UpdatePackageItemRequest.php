<?php

namespace App\Http\Requests\Api\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePackageItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'quantity' => [
                'sometimes',
                'required',
                'integer',
                'min:1',
                'max:100',
            ],

            'notes' => [
                'sometimes',
                'nullable',
                'string',
                'max:2000',
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'quantity.required' => 'الكمية مطلوبة.',
            'quantity.integer' => 'الكمية يجب أن تكون عددًا صحيحًا.',
            'quantity.min' => 'الكمية يجب أن تكون واحدًا على الأقل.',
            'quantity.max' => 'الكمية أكبر من الحد المسموح.',

            'notes.string' => 'الملاحظات غير صالحة.',
            'notes.max' => 'الملاحظات يجب ألا تتجاوز 2000 حرف.',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('notes')) {
            $notes = trim((string) $this->input('notes'));

            $this->merge([
                'notes' => $notes !== '' ? $notes : null,
            ]);
        }
    }
}