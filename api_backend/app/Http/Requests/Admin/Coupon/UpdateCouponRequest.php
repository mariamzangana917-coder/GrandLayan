<?php

namespace App\Http\Requests\Admin\Coupon;

use App\Models\Coupon;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateCouponRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('code')) {
            $this->merge([
                'code' => strtoupper(trim((string) $this->input('code'))),
            ]);
        }

        if ($this->has('catalog_item_ids')) {
            $catalogItemIds = collect($this->input('catalog_item_ids', []))
                ->filter(fn ($id) => $id !== null && $id !== '')
                ->map(fn ($id) => (int) $id)
                ->unique()
                ->values()
                ->all();

            $this->merge([
                'catalog_item_ids' => $catalogItemIds,
            ]);
        }
    }

    public function rules(): array
    {
        $coupon = $this->route('coupon');

        $couponId = $coupon instanceof Coupon
            ? $coupon->id
            : $coupon;

        return [
            'name' => [
                'required',
                'string',
                'max:150',
            ],

            'code' => [
                'required',
                'string',
                'max:50',
                'alpha_dash:ascii',
                Rule::unique('coupons', 'code')->ignore($couponId),
            ],

            'discount_type' => [
                'required',
                Rule::in([
                    Coupon::TYPE_PERCENTAGE,
                    Coupon::TYPE_FIXED,
                ]),
            ],

            'discount_value' => [
                'required',
                'numeric',
                'gt:0',
                Rule::when(
                    $this->input('discount_type') === Coupon::TYPE_PERCENTAGE,
                    ['lte:100']
                ),
            ],

            'minimum_order_amount' => [
                'nullable',
                'numeric',
                'gte:0',
            ],

            'maximum_discount_amount' => [
                'nullable',
                'numeric',
                'gt:0',
                Rule::prohibitedIf(
                    $this->input('discount_type') === Coupon::TYPE_FIXED
                ),
            ],

            'department_id' => [
                'nullable',
                'integer',
                Rule::exists('departments', 'id'),
            ],

            'maximum_total_uses' => [
                'nullable',
                'integer',
                'min:1',
            ],

            'maximum_uses_per_customer' => [
                'required',
                'integer',
                'min:1',
            ],

            'starts_at' => [
                'nullable',
                'date',
            ],

            'expires_at' => [
                'nullable',
                'date',
                'after:starts_at',
            ],

            'is_active' => [
                'required',
                'boolean',
            ],

            'notes' => [
                'nullable',
                'string',
                'max:2000',
            ],

            'catalog_item_ids' => [
                'sometimes',
                'array',
            ],

            'catalog_item_ids.*' => [
                'integer',
                'distinct',
                Rule::exists('catalog_items', 'id'),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'اسم الكوبون مطلوب.',
            'name.max' => 'اسم الكوبون طويل جدًا.',

            'code.required' => 'رمز الكوبون مطلوب.',
            'code.unique' => 'رمز الكوبون مستخدم مسبقًا.',
            'code.alpha_dash' => 'رمز الكوبون يجب أن يحتوي على أحرف إنجليزية وأرقام وشرطة فقط.',

            'discount_type.required' => 'نوع الخصم مطلوب.',
            'discount_type.in' => 'نوع الخصم غير صحيح.',

            'discount_value.required' => 'قيمة الخصم مطلوبة.',
            'discount_value.gt' => 'قيمة الخصم يجب أن تكون أكبر من صفر.',
            'discount_value.lte' => 'نسبة الخصم لا يمكن أن تتجاوز 100%.',

            'minimum_order_amount.gte' => 'الحد الأدنى للحجز لا يمكن أن يكون سالبًا.',

            'maximum_discount_amount.gt' => 'الحد الأعلى للخصم يجب أن يكون أكبر من صفر.',
            'maximum_discount_amount.prohibited' => 'الحد الأعلى للخصم يستخدم فقط مع الخصم النسبي.',

            'department_id.exists' => 'القسم المحدد غير موجود.',

            'maximum_total_uses.min' => 'الحد الكلي للاستخدام يجب أن يكون مرة واحدة على الأقل.',
            'maximum_uses_per_customer.required' => 'عدد مرات الاستخدام لكل زبونة مطلوب.',
            'maximum_uses_per_customer.min' => 'يجب السماح باستخدام واحد على الأقل لكل زبونة.',

            'expires_at.after' => 'تاريخ انتهاء الكوبون يجب أن يكون بعد تاريخ البداية.',

            'is_active.boolean' => 'حالة الكوبون غير صحيحة.',

            'catalog_item_ids.array' => 'قائمة الخدمات أو البكجات غير صحيحة.',
            'catalog_item_ids.*.exists' => 'إحدى الخدمات أو البكجات المحددة غير موجودة.',
            'catalog_item_ids.*.distinct' => 'لا يمكن تكرار نفس الخدمة أو البكج.',
        ];
    }
}
