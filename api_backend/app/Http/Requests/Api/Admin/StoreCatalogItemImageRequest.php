<?php

namespace App\Http\Requests\Api\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreCatalogItemImageRequest extends FormRequest
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
            'images' => [
                'required',
                'array',
                'min:1',
                'max:10',
            ],

            'images.*' => [
                'required',
                'file',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:5120',
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'images.required' => 'يجب اختيار صورة واحدة على الأقل.',
            'images.array' => 'صيغة الصور غير صالحة.',
            'images.min' => 'يجب اختيار صورة واحدة على الأقل.',
            'images.max' => 'يمكن رفع 10 صور كحد أقصى في كل طلب.',

            'images.*.required' => 'ملف الصورة مطلوب.',
            'images.*.file' => 'الصورة المرفوعة غير صالحة.',
            'images.*.image' => 'الملف المرفوع يجب أن يكون صورة.',
            'images.*.mimes' => 'صيغة الصورة يجب أن تكون JPG أو JPEG أو PNG أو WEBP.',
            'images.*.max' => 'حجم الصورة يجب ألا يتجاوز 5 ميغابايت.',
        ];
    }
}
