<?php

namespace App\Http\Requests\Api\Customer\Auth;

use Illuminate\Foundation\Http\FormRequest;

class CustomerLoginRequest extends FormRequest
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
            'login' => [
                'required',
                'string',
                'max:255',
            ],

            'password' => [
                'required',
                'string',
            ],

            'device_name' => [
                'required',
                'string',
                'max:255',
            ],
        ];
    }
}