<?php

namespace App\Http\Requests\Api\Appointments;

use App\Models\CatalogItem;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreAppointmentRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        if ($this->has('coupon_code')) {
            $couponCode = trim((string) $this->input('coupon_code'));

            $this->merge([
                'coupon_code' => $couponCode !== ''
                    ? strtoupper($couponCode)
                    : null,
            ]);
        }
    }

    /**
     * Only an active customer may create an appointment.
     */
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null
            && (bool) $user->is_active
            && $user->hasRole('customer');
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'department_id' => [
                'required',
                'integer',
                Rule::exists('departments', 'id')
                    ->where(
                        fn ($query) => $query->where(
                            'is_active',
                            true
                        )
                    ),
            ],

            'requested_start_at' => [
                'required',
                'date',
                'after:now',
            ],

            'customer_notes' => [
                'nullable',
                'string',
                'max:1000',
            ],

            'coupon_code' => [
                'nullable',
                'string',
                'max:50',
                'alpha_dash:ascii',
            ],

            'items' => [
                'required',
                'array',
                'min:1',
                'max:20',
            ],

            'items.*.catalog_item_id' => [
                'required',
                'integer',
                'distinct:strict',
                Rule::exists('catalog_items', 'id')
                    ->where(
                        fn ($query) => $query
                            ->where('is_active', true)
                            ->whereNull('deleted_at')
                    ),
            ],

            'items.*.quantity' => [
                'required',
                'integer',
                'min:1',
                'max:20',
            ],
        ];
    }

    /**
     * Perform booking-specific validation after basic validation.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }

            $departmentId = (int) $this->input('department_id');
            $submittedItems = $this->input('items', []);

            foreach ($submittedItems as $submittedItem) {
                $catalogItem = CatalogItem::query()
                    ->with('category')
                    ->find((int) $submittedItem['catalog_item_id']);

                if ($catalogItem === null) {
                    continue;
                }

                if (
                    (int) $catalogItem->category->department_id
                    !== $departmentId
                ) {
                    $validator->errors()->add(
                        'items',
                        'يجب أن تكون جميع الخدمات والبكجات من القسم المحدد نفسه.'
                    );

                    return;
                }

                if (
                    $catalogItem->isService()
                    && $catalogItem->duration_minutes === null
                ) {
                    $validator->errors()->add(
                        'items',
                        'لا يمكن حجز خدمة لا تحتوي على مدة زمنية.'
                    );

                    return;
                }

                if ($catalogItem->isPackage()) {
                    $packageServices = DB::table('package_items')
                        ->join(
                            'catalog_items',
                            'catalog_items.id',
                            '=',
                            'package_items.service_id'
                        )
                        ->join(
                            'categories',
                            'categories.id',
                            '=',
                            'catalog_items.category_id'
                        )
                        ->where(
                            'package_items.package_id',
                            $catalogItem->id
                        )
                        ->select([
                            'catalog_items.id',
                            'catalog_items.type',
                            'catalog_items.is_active',
                            'catalog_items.deleted_at',
                            'catalog_items.duration_minutes',
                            'categories.department_id',
                        ])
                        ->get();

                    if ($packageServices->isEmpty()) {
                        $validator->errors()->add(
                            'items',
                            'لا يمكن حجز باكج لا يحتوي على خدمات.'
                        );

                        return;
                    }

                    foreach ($packageServices as $service) {
                        $isInvalidService =
                            $service->type !== CatalogItem::TYPE_SERVICE
                            || ! (bool) $service->is_active
                            || $service->deleted_at !== null
                            || $service->duration_minutes === null
                            || (int) $service->duration_minutes <= 0
                            || (int) $service->department_id
                                !== $departmentId;

                        if ($isInvalidService) {
                            $validator->errors()->add(
                                'items',
                                'يحتوي الباكج على خدمة غير متاحة أو غير صالحة للحجز.'
                            );

                            return;
                        }
                    }
                }
            }
        });
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'department_id.required' => 'القسم مطلوب.',
            'department_id.exists' => 'القسم غير موجود أو غير فعال.',

            'requested_start_at.required' => 'تاريخ ووقت الحجز مطلوبان.',
            'requested_start_at.date' => 'تاريخ ووقت الحجز غير صالحين.',
            'requested_start_at.after' => 'يجب اختيار موعد في المستقبل.',

            'customer_notes.max' => 'ملاحظات الحجز طويلة جدًا.',

            'coupon_code.string' => 'رمز الكوبون غير صالح.',
            'coupon_code.max' => 'رمز الكوبون طويل جدًا.',
            'coupon_code.alpha_dash' => 'رمز الكوبون يجب أن يحتوي على أحرف إنجليزية وأرقام وشرطة فقط.',

            'items.required' => 'يجب اختيار خدمة أو باكج واحد على الأقل.',
            'items.array' => 'قائمة الخدمات غير صالحة.',
            'items.min' => 'يجب اختيار خدمة أو باكج واحد على الأقل.',
            'items.max' => 'لا يمكن اختيار أكثر من 20 عنصرًا في الحجز.',

            'items.*.catalog_item_id.required' => 'الخدمة أو الباكج مطلوب.',
            'items.*.catalog_item_id.exists' => 'الخدمة أو الباكج غير موجود أو غير فعال.',
            'items.*.catalog_item_id.distinct' => 'لا يمكن تكرار الخدمة أو الباكج داخل الحجز.',

            'items.*.quantity.required' => 'الكمية مطلوبة.',
            'items.*.quantity.integer' => 'الكمية يجب أن تكون رقمًا صحيحًا.',
            'items.*.quantity.min' => 'الكمية يجب أن تكون أكبر من صفر.',
            'items.*.quantity.max' => 'الكمية المسموحة بحد أقصى 20.',
        ];
    }
}
