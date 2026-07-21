<?php

namespace App\Http\Requests\Api\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCatalogItemImageRequest extends FormRequest
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
            'alt_text' => [
                'sometimes',
                'nullable',
                'string',
                'max:255',
            ],

            'sort_order' => [
                'sometimes',
                'integer',
                'min:0',
                'max:65535',
            ],

            'is_primary' => [
                'sometimes',
                'boolean',
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'alt_text.string' => 'النص البديل للصورة غير صالح.',
            'alt_text.max' => 'النص البديل يجب ألا يتجاوز 255 حرفًا.',

            'sort_order.integer' => 'ترتيب الصورة يجب أن يكون عددًا صحيحًا.',
            'sort_order.min' => 'ترتيب الصورة لا يمكن أن يكون سالبًا.',
            'sort_order.max' => 'ترتيب الصورة أكبر من الحد المسموح.',

            'is_primary.boolean' => 'قيمة الصورة الرئيسية غير صالحة.',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('alt_text')) {
            $altText = trim(
                (string) $this->input('alt_text')
            );

            $this->merge([
                'alt_text' => $altText !== ''
                    ? $altText
                    : null,
            ]);
        }
    }
}
