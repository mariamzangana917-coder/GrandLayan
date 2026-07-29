<?php

namespace App\Http\Requests\Api\Offers;

use App\Models\Offer;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Validator;

class UpdateOfferRequest extends FormRequest
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
                'sometimes',
                'required',
                'integer',
                'exists:departments,id',
            ],
            'catalog_item_id' => [
                'sometimes',
                'nullable',
                'integer',
                'exists:catalog_items,id',
            ],
            'title' => [
                'sometimes',
                'required',
                'string',
                'min:3',
                'max:150',
            ],
            'description' => [
                'sometimes',
                'nullable',
                'string',
                'max:3000',
            ],
            'badge_text' => [
                'sometimes',
                'nullable',
                'string',
                'max:50',
            ],
            'value_text' => [
                'sometimes',
                'nullable',
                'string',
                'max:100',
            ],
            'details_text' => [
                'sometimes',
                'nullable',
                'string',
                'max:150',
            ],
            'starts_at' => [
                'sometimes',
                'required',
                'date',
            ],
            'ends_at' => [
                'sometimes',
                'required',
                'date',
            ],
            'is_active' => [
                'sometimes',
                'required',
                'boolean',
            ],
            'sort_order' => [
                'sometimes',
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
            $offer = $this->route('offer');

            if (! $offer instanceof Offer) {
                return;
            }

            $departmentId = (int) $this->input(
                'department_id',
                $offer->department_id,
            );

            $catalogItemId = $this->has('catalog_item_id')
                ? $this->input('catalog_item_id')
                : $offer->catalog_item_id;

            if ($catalogItemId !== null && $catalogItemId !== '') {
                $matchesDepartment = DB::table('catalog_items')
                    ->join(
                        'categories',
                        'categories.id',
                        '=',
                        'catalog_items.category_id',
                    )
                    ->where('catalog_items.id', (int) $catalogItemId)
                    ->where('categories.department_id', $departmentId)
                    ->exists();

                if (! $matchesDepartment) {
                    $validator->errors()->add(
                        'catalog_item_id',
                        'الخدمة أو البكج يجب أن ينتمي إلى قسم العرض نفسه.',
                    );
                }
            }

            try {
                $startsAt = CarbonImmutable::parse(
                    $this->input('starts_at', $offer->starts_at),
                );

                $endsAt = CarbonImmutable::parse(
                    $this->input('ends_at', $offer->ends_at),
                );

                if ($endsAt->lessThanOrEqualTo($startsAt)) {
                    $validator->errors()->add(
                        'ends_at',
                        'تاريخ نهاية العرض يجب أن يكون بعد تاريخ البداية.',
                    );
                }
            } catch (\Throwable) {
                // Date format errors are already handled by the date rules.
            }
        });
    }
}
