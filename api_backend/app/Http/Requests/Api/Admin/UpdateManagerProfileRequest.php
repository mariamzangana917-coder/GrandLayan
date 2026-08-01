<?php

namespace App\Http\Requests\Api\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateManagerProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        $manager = $this->user();

        return $manager !== null
            && (bool) $manager->is_active
            && $manager->hasRole('manager');
    }

    protected function prepareForValidation(): void
    {
        $name = trim((string) $this->input('name', ''));
        $phone = preg_replace(
            '/[\s\-()]+/',
            '',
            (string) $this->input('phone', '')
        );
        $email = strtolower(trim((string) $this->input('email', '')));

        $this->merge([
            'name' => $name,
            'phone' => $phone,
            'email' => $email,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $managerId = $this->user()?->getKey();

        return [
            'name' => [
                'required',
                'string',
                'min:2',
                'max:120',
            ],
            'phone' => [
                'required',
                'string',
                'regex:/^\+?[0-9]{7,20}$/',
                Rule::unique('users', 'phone')->ignore($managerId),
            ],
            'email' => [
                'required',
                'string',
                'email:rfc',
                'max:255',
                Rule::unique('users', 'email')->ignore($managerId),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'اسم المديرة مطلوب.',
            'name.string' => 'اسم المديرة غير صالح.',
            'name.min' => 'اسم المديرة قصير جدًا.',
            'name.max' => 'اسم المديرة طويل جدًا.',

            'phone.required' => 'رقم الهاتف مطلوب.',
            'phone.string' => 'رقم الهاتف غير صالح.',
            'phone.regex' => 'صيغة رقم الهاتف غير صحيحة.',
            'phone.unique' => 'رقم الهاتف مستخدم في حساب آخر.',

            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.string' => 'البريد الإلكتروني غير صالح.',
            'email.email' => 'صيغة البريد الإلكتروني غير صحيحة.',
            'email.max' => 'البريد الإلكتروني طويل جدًا.',
            'email.unique' => 'البريد الإلكتروني مستخدم في حساب آخر.',
        ];
    }
}
