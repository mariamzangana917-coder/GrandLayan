<?php

namespace App\Http\Requests\Api\Admin;

use App\Models\CatalogItem;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UpdateCatalogItemRequest extends FormRequest
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
            'category_id' => [
                'sometimes',
                'required',
                'integer',
                Rule::exists('categories', 'id')
                    ->where(
                        fn ($query) => $query
                            ->where('is_active', true)
                            ->whereNull('deleted_at')
                    ),
            ],

            'type' => [
                'sometimes',
                'required',
                'string',
                Rule::in([
                    CatalogItem::TYPE_SERVICE,
                    CatalogItem::TYPE_PACKAGE,
                ]),
            ],

            'name' => [
                'sometimes',
                'required',
                'string',
                'max:150',
            ],

            'description' => [
                'sometimes',
                'nullable',
                'string',
                'max:5000',
            ],

            'instructions' => [
                'sometimes',
                'nullable',
                'string',
                'max:5000',
            ],

            'price_type' => [
                'sometimes',
                'required',
                'string',
                Rule::in([
                    CatalogItem::PRICE_TYPE_FIXED,
                    CatalogItem::PRICE_TYPE_INSPECTION,
                ]),
            ],

            'price' => [
                'sometimes',
                'nullable',
                'numeric',
                'min:0',
            ],

            'duration_minutes' => [
                'sometimes',
                'nullable',
                'integer',
                'min:1',
                'max:65535',
            ],

            'is_active' => [
                'sometimes',
                'boolean',
            ],
        ];
    }

    /**
     * Validate cross-field rules after basic validation.
     *
     * @return array<int, callable>
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                if ($validator->errors()->isNotEmpty()) {
                    return;
                }

                /** @var CatalogItem $catalogItem */
                $catalogItem = $this->route('catalog_item');

                $categoryId = $this->has('category_id')
                    ? $this->integer('category_id')
                    : $catalogItem->category_id;

                $name = $this->has('name')
                    ? (string) $this->input('name')
                    : $catalogItem->name;

                $priceType = $this->has('price_type')
                    ? (string) $this->input('price_type')
                    : $catalogItem->price_type;

                $price = $this->has('price')
                    ? $this->input('price')
                    : $catalogItem->price;

                /*
                 * Case-insensitive uniqueness inside the same category.
                 */
                $duplicateExists = DB::table('catalog_items')
                    ->where('category_id', $categoryId)
                    ->where('id', '<>', $catalogItem->id)
                    ->whereNull('deleted_at')
                    ->whereRaw(
                        'LOWER(name) = LOWER(?)',
                        [$name]
                    )
                    ->exists();

                if ($duplicateExists) {
                    $validator->errors()->add(
                        'name',
                        'هذا الاسم موجود مسبقًا داخل التصنيف نفسه.'
                    );
                }

                /*
                 * Fixed-price items must always have a price.
                 */
                if (
                    $priceType === CatalogItem::PRICE_TYPE_FIXED
                    && ($price === null || $price === '')
                ) {
                    $validator->errors()->add(
                        'price',
                        'السعر مطلوب عند اختيار السعر الثابت.'
                    );
                }

                /*
                 * Inspection-priced items must not store a price.
                 */
                if (
                    $priceType === CatalogItem::PRICE_TYPE_INSPECTION
                    && $price !== null
                    && $price !== ''
                ) {
                    $validator->errors()->add(
                        'price',
                        'لا يمكن إدخال سعر لخدمة يتحدد سعرها بعد المعاينة.'
                    );
                }
            },
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'category_id.required' => 'التصنيف مطلوب.',
            'category_id.integer' => 'التصنيف غير صالح.',
            'category_id.exists' => 'التصنيف المحدد غير موجود أو غير فعال.',

            'type.required' => 'نوع العنصر مطلوب.',
            'type.string' => 'نوع العنصر غير صالح.',
            'type.in' => 'نوع العنصر يجب أن يكون خدمة أو باكج.',

            'name.required' => 'اسم الخدمة أو الباكج مطلوب.',
            'name.string' => 'الاسم غير صالح.',
            'name.max' => 'الاسم يجب ألا يتجاوز 150 حرفًا.',

            'description.string' => 'الوصف غير صالح.',
            'description.max' => 'الوصف يجب ألا يتجاوز 5000 حرف.',

            'instructions.string' => 'التعليمات غير صالحة.',
            'instructions.max' => 'التعليمات يجب ألا تتجاوز 5000 حرف.',

            'price_type.required' => 'نوع السعر مطلوب.',
            'price_type.string' => 'نوع السعر غير صالح.',
            'price_type.in' => 'نوع السعر يجب أن يكون ثابتًا أو بعد المعاينة.',

            'price.numeric' => 'السعر يجب أن يكون رقمًا.',
            'price.min' => 'السعر لا يمكن أن يكون سالبًا.',

            'duration_minutes.integer' => 'مدة الخدمة يجب أن تكون عددًا صحيحًا.',
            'duration_minutes.min' => 'مدة الخدمة يجب أن تكون دقيقة واحدة على الأقل.',
            'duration_minutes.max' => 'مدة الخدمة المدخلة أكبر من الحد المسموح.',

            'is_active.boolean' => 'حالة التفعيل غير صالحة.',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('name')) {
            $this->merge([
                'name' => trim((string) $this->input('name')),
            ]);
        }

        foreach (['description', 'instructions'] as $field) {
            if (! $this->has($field)) {
                continue;
            }

            $value = trim((string) $this->input($field));

            $this->merge([
                $field => $value !== '' ? $value : null,
            ]);
        }
    }
}
