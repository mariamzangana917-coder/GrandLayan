<?php

namespace App\Http\Requests\Api\Admin;

use App\Models\CatalogItem;
use App\Models\PackageItem;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StorePackageItemRequest extends FormRequest
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
            'service_id' => [
                'required',
                'integer',
                'exists:catalog_items,id',
            ],

            'quantity' => [
                'required',
                'integer',
                'min:1',
                'max:100',
            ],

            'notes' => [
                'nullable',
                'string',
                'max:2000',
            ],
        ];
    }

    /**
     * @return array<int, callable>
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                if (
                    $validator->errors()->has('service_id')
                    || $validator->errors()->has('quantity')
                ) {
                    return;
                }

                /** @var CatalogItem $package */
                $package = $this->route('package');

                $service = CatalogItem::query()
                    ->with('category.department')
                    ->find($this->integer('service_id'));

                if ($service === null) {
                    return;
                }

                if (! $service->isService()) {
                    $validator->errors()->add(
                        'service_id',
                        'العنصر المحدد ليس خدمة.'
                    );

                    return;
                }

                if (! $service->is_active || $service->trashed()) {
                    $validator->errors()->add(
                        'service_id',
                        'الخدمة المحددة غير فعالة أو محذوفة.'
                    );

                    return;
                }

                $package->loadMissing('category.department');

                if (
                    $service->category->department_id
                    !== $package->category->department_id
                ) {
                    $validator->errors()->add(
                        'service_id',
                        'لا يمكن إضافة خدمة من قسم مختلف إلى الباكج.'
                    );

                    return;
                }

                $alreadyExists = PackageItem::query()
                    ->where('package_id', $package->id)
                    ->where('service_id', $service->id)
                    ->exists();

                if ($alreadyExists) {
                    $validator->errors()->add(
                        'service_id',
                        'هذه الخدمة مضافة مسبقًا إلى الباكج.'
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
            'service_id.required' => 'الخدمة مطلوبة.',
            'service_id.integer' => 'الخدمة غير صالحة.',
            'service_id.exists' => 'الخدمة المحددة غير موجودة.',

            'quantity.required' => 'الكمية مطلوبة.',
            'quantity.integer' => 'الكمية يجب أن تكون عددًا صحيحًا.',
            'quantity.min' => 'الكمية يجب أن تكون واحدًا على الأقل.',
            'quantity.max' => 'الكمية أكبر من الحد المسموح.',

            'notes.string' => 'الملاحظات غير صالحة.',
            'notes.max' => 'الملاحظات يجب ألا تتجاوز 2000 حرف.',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('notes')) {
            $notes = trim((string) $this->input('notes'));

            $this->merge([
                'notes' => $notes !== '' ? $notes : null,
            ]);
        }
    }
}