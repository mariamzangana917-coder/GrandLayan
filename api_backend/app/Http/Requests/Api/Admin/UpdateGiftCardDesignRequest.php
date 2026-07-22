<?php

namespace App\Http\Requests\Api\Admin;

use App\Models\GiftCardDesign;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateGiftCardDesignRequest extends FormRequest
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
        /** @var GiftCardDesign $giftCardDesign */
         $giftCardDesign = $this->route('giftCardDesign')
    ?? $this->route('gift_card_design');

        return [
            'name' => [
                'sometimes',
                'string',
                'max:255',
                Rule::unique('gift_card_designs', 'name')
                    ->ignore($giftCardDesign),
            ],

            'description' => [
                'nullable',
                'string',
                'max:5000',
            ],

            'image' => [
                'nullable',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:5120',
            ],

            'amount' => [
                'sometimes',
                'numeric',
                'min:1',
            ],

            'validity_days' => [
                'sometimes',
                'integer',
                'min:1',
                'max:3650',
            ],

            'is_active' => [
                'sometimes',
                'boolean',
            ],

            'sort_order' => [
                'sometimes',
                'integer',
                'min:0',
            ],
        ];
    }
}