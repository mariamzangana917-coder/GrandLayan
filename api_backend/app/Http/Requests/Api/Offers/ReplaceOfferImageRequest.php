<?php

namespace App\Http\Requests\Api\Offers;

use Illuminate\Foundation\Http\FormRequest;

class ReplaceOfferImageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'image' => [
                'required',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:5120',
            ],
        ];
    }
}
