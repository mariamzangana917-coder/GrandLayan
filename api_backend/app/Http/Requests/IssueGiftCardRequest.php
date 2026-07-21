<?php

namespace App\Http\Requests;

use App\Models\GiftCardOrder;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class IssueGiftCardRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Only electronic payments require a payment reference.
     */
    public function rules(): array
    {
        return [
            'payment_reference' => [
                Rule::requiredIf(function (): bool {
                    /** @var GiftCardOrder|null $order */
                    $order = $this->route('giftCardOrder');

                    if (! $order instanceof GiftCardOrder) {
                        return false;
                    }

                    return $order->payment_method
                        === GiftCardOrder::PAYMENT_METHOD_ELECTRONIC;
                }),
                'nullable',
                'string',
                'max:255',
            ],
        ];
    }

    public function attributes(): array
    {
        return [
            'payment_reference' => 'مرجع الدفع',
        ];
    }
}
