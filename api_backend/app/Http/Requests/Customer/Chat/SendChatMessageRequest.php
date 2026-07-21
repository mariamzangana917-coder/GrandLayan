<?php

namespace App\Http\Requests\Customer\Chat;

use Illuminate\Foundation\Http\FormRequest;

class SendChatMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->hasRole('customer') === true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'conversation_id' => [
                'nullable',
                'integer',
                'exists:chat_conversations,id',
            ],
            'message' => [
                'required',
                'string',
                'min:1',
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
            'conversation_id.integer' =>
                'رقم المحادثة غير صالح.',

            'conversation_id.exists' =>
                'المحادثة المطلوبة غير موجودة.',

            'message.required' =>
                'يرجى كتابة الرسالة.',

            'message.string' =>
                'نص الرسالة غير صالح.',

            'message.min' =>
                'يرجى كتابة الرسالة.',

            'message.max' =>
                'يجب ألا تتجاوز الرسالة 2000 حرف.',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('message')) {
            $this->merge([
                'message' => trim(
                    (string) $this->input('message'),
                ),
            ]);
        }
    }
}