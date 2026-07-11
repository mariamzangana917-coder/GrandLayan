<?php

namespace App\Http\Requests\Api\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreCategoryRequest extends FormRequest
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
            'department_id' => [
                'required',
                'integer',
                Rule::exists('departments', 'id')
                    ->where(
                        fn ($query) => $query->where('is_active', true)
                    ),
            ],

            'name' => [
                'required',
                'string',
                'max:100',
            ],

            'description' => [
                'nullable',
                'string',
                'max:2000',
            ],

            'is_active' => [
                'sometimes',
                'boolean',
            ],
        ];
    }

    /**
     * Additional validation after the basic rules.
     *
     * @return array<int, callable>
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                if (
                    $validator->errors()->has('department_id')
                    || $validator->errors()->has('name')
                ) {
                    return;
                }

                $exists = DB::table('categories')
                    ->where(
                        'department_id',
                        $this->integer('department_id')
                    )
                    ->whereNull('deleted_at')
                    ->whereRaw(
                        'LOWER(name) = LOWER(?)',
                        [(string) $this->input('name')]
                    )
                    ->exists();

                if ($exists) {
                    $validator->errors()->add(
                        'name',
                        'هذا التصنيف موجود مسبقًا داخل القسم نفسه.'
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
            'department_id.required' => 'القسم مطلوب.',
            'department_id.integer' => 'القسم غير صالح.',
            'department_id.exists' => 'القسم المحدد غير موجود أو غير فعال.',

            'name.required' => 'اسم التصنيف مطلوب.',
            'name.string' => 'اسم التصنيف غير صالح.',
            'name.max' => 'اسم التصنيف يجب ألا يتجاوز 100 حرف.',

            'description.string' => 'وصف التصنيف غير صالح.',
            'description.max' => 'وصف التصنيف يجب ألا يتجاوز 2000 حرف.',

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

        if ($this->has('description')) {
            $description = trim(
                (string) $this->input('description')
            );

            $this->merge([
                'description' => $description !== ''
                    ? $description
                    : null,
            ]);
        }
    }
}