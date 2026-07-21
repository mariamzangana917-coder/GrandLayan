<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RefundGiftCardRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'gift_card_id' => [
                'required',
                'integer',
                'exists:gift_cards,id',
            ],

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
}
