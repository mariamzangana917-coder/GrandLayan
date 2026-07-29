<?php

namespace App\Http\Requests\Api\Offers;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Validator;

class StoreOfferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $values = [];

        if ($this->has('is_active')) {
            $boolean = filter_var(
                $this->input('is_active'),
                FILTER_VALIDATE_BOOLEAN,
                FILTER_NULL_ON_FAILURE,
            );

            if ($boolean !== null) {
                $values['is_active'] = $boolean;
            }
        }

        if ($this->has('sort_order')) {
            $values['sort_order'] = (int) $this->input('sort_order');
        }

        if ($values !== []) {
            $this->merge($values);
        }
    }

    public function rules(): array
    {
        return [
            'department_id' => [
                'required',
                'integer',
                'exists:departments,id',
            ],
            'catalog_item_id' => [
                'nullable',
                'integer',
                'exists:catalog_items,id',
            ],
            'title' => [
                'required',
                'string',
                'min:3',
                'max:150',
            ],
            'description' => [
                'nullable',
                'string',
                'max:3000',
            ],
            'badge_text' => [
                'nullable',
                'string',
                'max:50',
            ],
            'value_text' => [
                'nullable',
                'string',
                'max:100',
            ],
            'details_text' => [
                'nullable',
                'string',
                'max:150',
            ],
            'image' => [
                'required',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:5120',
            ],
            'starts_at' => [
                'required',
                'date',
            ],
            'ends_at' => [
                'required',
                'date',
                'after:starts_at',
            ],
            'is_active' => [
                'required',
                'boolean',
            ],
            'sort_order' => [
                'required',
                'integer',
                'min:0',
                'max:1000000',
            ],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $catalogItemId = $this->input('catalog_item_id');

            if ($catalogItemId === null || $catalogItemId === '') {
                return;
            }

            $matchesDepartment = DB::table('catalog_items')
                ->join(
                    'categories',
                    'categories.id',
                    '=',
                    'catalog_items.category_id',
                )
                ->where('catalog_items.id', (int) $catalogItemId)
                ->where(
                    'categories.department_id',
                    (int) $this->input('department_id'),
                )
                ->exists();

            if (! $matchesDepartment) {
                $validator->errors()->add(
                    'catalog_item_id',
                    'الخدمة أو البكج يجب أن ينتمي إلى قسم العرض نفسه.',
                );
            }
        });
    }
}
