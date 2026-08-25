<?php

namespace App\Http\Requests\Admin\Banners;

use App\Enums\BannerActionType;
use App\Models\Banner;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\File;
use Illuminate\Validation\Validator;
use Throwable;

abstract class BannerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    abstract protected function imageIsRequired(): bool;

    abstract protected function fieldsAreRequired(): bool;

    protected function prepareForValidation(): void
    {
        $payload = [];

        if ($this->exists('action_target_id')) {
            $payload['action_target_id'] = $this->blankToNull(
                $this->input('action_target_id'),
            );
        }

        if ($this->exists('external_url')) {
            $payload['external_url'] = $this->blankToNull(
                $this->input('external_url'),
            );
        }

        if ($payload !== []) {
            $this->merge($payload);
        }
    }

    public function rules(): array
    {
        $required = $this->fieldsAreRequired() ? 'required' : 'sometimes';
        $imagePresence = $this->imageIsRequired() ? 'required' : 'sometimes';

        return [
            'title' => ['sometimes', 'nullable', 'string', 'max:120'],
            'subtitle' => ['sometimes', 'nullable', 'string', 'max:220'],
            'image' => [
                $imagePresence,
                File::image()
                    ->types(['jpg', 'jpeg', 'png', 'webp'])
                    ->max('2mb'),
            ],
            'placement' => [$required, Rule::in(['home', 'salon', 'clinic'])],
            'action_type' => [$required, Rule::in(BannerActionType::values())],
            'action_target_id' => ['sometimes', 'nullable', 'integer', 'min:1'],
            'external_url' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'starts_at' => ['sometimes', 'nullable', 'date'],
            'ends_at' => ['sometimes', 'nullable', 'date'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:10000'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $banner = $this->route('banner');
            $banner = $banner instanceof Banner ? $banner : null;

            $actionTypeProvided = $this->exists('action_type');
            $actionTypeValue = $this->input(
                'action_type',
                $banner?->action_type?->value ?? BannerActionType::None->value,
            );

            $actionType = BannerActionType::tryFrom((string) $actionTypeValue);

            if ($actionType === null) {
                return;
            }

            $targetId = $this->resolveActionTargetId(
                banner: $banner,
                actionType: $actionType,
                actionTypeProvided: $actionTypeProvided,
            );

            $externalUrl = $this->resolveExternalUrl(
                banner: $banner,
                actionType: $actionType,
                actionTypeProvided: $actionTypeProvided,
            );

            $this->validateActionPayload(
                validator: $validator,
                actionType: $actionType,
                targetId: $targetId,
                externalUrl: $externalUrl,
            );

            $this->validateDateRange($validator, $banner);
        });
    }

    /**
     * FormData often omits null fields. When switching to a screen-only action,
     * do not inherit a leftover target from the existing banner row.
     */
    private function resolveActionTargetId(
        ?Banner $banner,
        BannerActionType $actionType,
        bool $actionTypeProvided,
    ): mixed {
        if ($this->exists('action_target_id')) {
            return $this->blankToNull($this->input('action_target_id'));
        }

        if ($actionTypeProvided && ! $actionType->requiresTarget()) {
            return null;
        }

        return $banner?->action_target_id;
    }

    private function resolveExternalUrl(
        ?Banner $banner,
        BannerActionType $actionType,
        bool $actionTypeProvided,
    ): mixed {
        if ($this->exists('external_url')) {
            return $this->blankToNull($this->input('external_url'));
        }

        if ($actionTypeProvided && ! $actionType->requiresExternalUrl()) {
            return null;
        }

        return $banner?->external_url;
    }

    private function blankToNull(mixed $value): mixed
    {
        if ($value === null || $value === '' || $value === 'null') {
            return null;
        }

        return $value;
    }

    private function validateActionPayload(
        Validator $validator,
        BannerActionType $actionType,
        mixed $targetId,
        mixed $externalUrl,
    ): void {
        if ($actionType->requiresTarget()) {
            if ($targetId === null || $targetId === '') {
                $validator->errors()->add(
                    'action_target_id',
                    'يجب تحديد العنصر المرتبط بهذا البانر.',
                );

                return;
            }

            $table = match ($actionType) {
                BannerActionType::Department => 'departments',
                BannerActionType::Category => 'categories',
                BannerActionType::CatalogItem => 'catalog_items',
                default => null,
            };

            if ($table !== null && ! DB::table($table)->where('id', $targetId)->exists()) {
                $validator->errors()->add(
                    'action_target_id',
                    'العنصر المرتبط غير موجود.',
                );
            }

            if ($externalUrl !== null && $externalUrl !== '') {
                $validator->errors()->add(
                    'external_url',
                    'الرابط الخارجي غير مسموح مع هذا النوع من الإجراءات.',
                );
            }

            return;
        }

        if ($actionType->requiresExternalUrl()) {
            if (! is_string($externalUrl) || trim($externalUrl) === '') {
                $validator->errors()->add(
                    'external_url',
                    'يجب إدخال رابط خارجي آمن.',
                );

                return;
            }

            $url = trim($externalUrl);

            if (! str_starts_with(strtolower($url), 'https://') || filter_var($url, FILTER_VALIDATE_URL) === false) {
                $validator->errors()->add(
                    'external_url',
                    'الرابط الخارجي يجب أن يكون صحيحًا ويبدأ بـ https://.',
                );
            }

            if ($targetId !== null && $targetId !== '') {
                $validator->errors()->add(
                    'action_target_id',
                    'لا يمكن تحديد عنصر مرتبط مع رابط خارجي.',
                );
            }

            return;
        }

        if ($targetId !== null && $targetId !== '') {
            $validator->errors()->add(
                'action_target_id',
                'هذا النوع من الإجراءات لا يقبل عنصرًا مرتبطًا.',
            );
        }

        if ($externalUrl !== null && $externalUrl !== '') {
            $validator->errors()->add(
                'external_url',
                'هذا النوع من الإجراءات لا يقبل رابطًا خارجيًا.',
            );
        }
    }

    private function validateDateRange(Validator $validator, ?Banner $banner): void
    {
        $startsAt = $this->has('starts_at')
            ? $this->input('starts_at')
            : $banner?->starts_at;

        $endsAt = $this->has('ends_at')
            ? $this->input('ends_at')
            : $banner?->ends_at;

        if ($startsAt === null || $startsAt === '' || $endsAt === null || $endsAt === '') {
            return;
        }

        try {
            $start = CarbonImmutable::parse($startsAt);
            $end = CarbonImmutable::parse($endsAt);
        } catch (Throwable) {
            return;
        }

        if ($end->lessThan($start)) {
            $validator->errors()->add(
                'ends_at',
                'تاريخ انتهاء البانر يجب أن يكون بعد تاريخ البداية أو مساويًا له.',
            );
        }
    }

    public function messages(): array
    {
        return [
            'image.required' => 'صورة البانر مطلوبة.',
            'image.image' => 'الملف المرفوع يجب أن يكون صورة صالحة.',
            'action_type.required' => 'نوع إجراء البانر مطلوب.',
            'action_type.in' => 'نوع إجراء البانر غير مدعوم.',
            'sort_order.integer' => 'ترتيب البانر يجب أن يكون رقمًا صحيحًا.',
            'is_active.boolean' => 'حالة البانر يجب أن تكون صحيحة.',
        ];
    }
}
