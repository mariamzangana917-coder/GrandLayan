<?php

namespace App\Http\Requests;

use App\Models\GiftCardOrder;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreGiftCardOrderRequest extends FormRequest
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
            'gift_card_design_id' => [
                'required',
                'integer',
                Rule::exists('gift_card_designs', 'id'),
            ],

            'recipient_name' => [
                'required',
                'string',
                'max:255',
            ],

            'recipient_phone' => [
                'nullable',
                'string',
                'max:30',
            ],

            'gift_message' => [
                'nullable',
                'string',
                'max:1000',
            ],
            'payment_method' => [
                'required',
                Rule::in([
                    GiftCardOrder::PAYMENT_METHOD_CASH,
                    GiftCardOrder::PAYMENT_METHOD_ELECTRONIC,
                ]),
            ],
        ];
    }
}
