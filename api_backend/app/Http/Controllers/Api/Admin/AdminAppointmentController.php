<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Admin\CancelAdminAppointmentRequest;
use App\Http\Requests\Api\Admin\ConfirmAdminAppointmentRequest;
use App\Http\Requests\Api\Admin\IndexAdminAppointmentRequest;
use App\Http\Requests\Api\Admin\UpdateAdminAppointmentRequest;
use App\Http\Requests\Api\Admin\UpdateAdminAppointmentStatusRequest;
use App\Http\Resources\AdminAppointmentResource;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use App\Models\Department;
use App\Services\Appointments\ManageAppointmentService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AdminAppointmentController extends Controller
{
    public function index(
        IndexAdminAppointmentRequest $request
    ): AnonymousResourceCollection {
        $validated = $request->validated();

        $appointments = Appointment::query()
            ->with([
                'customer',
                'department',
                'coupon',
                'items.services',
            ])
            ->when(
                $validated['search'] ?? null,
                function (Builder $query, string $search): void {
                    $search = trim($search);

                    $query->where(function (Builder $query) use ($search): void {
                        $query
                            ->where('reference', 'ilike', "%{$search}%")
                            ->orWhereHas(
                                'customer',
                                function (Builder $customerQuery) use ($search): void {
                                    $customerQuery
                                        ->where('name', 'ilike', "%{$search}%")
                                        ->orWhere('phone', 'ilike', "%{$search}%")
                                        ->orWhere('email', 'ilike', "%{$search}%");
                                }
                            );
                    });
                }
            )
            ->when(
                $validated['status'] ?? null,
                fn (Builder $query, string $status) => $query->where('status', $status)
            )
            ->when(
                $validated['department_id'] ?? null,
                fn (Builder $query, int $departmentId) => $query->where('department_id', $departmentId)
            )
            ->when(
                $validated['date'] ?? null,
                fn (Builder $query, string $date) => $query->whereDate('requested_start_at', $date)
            )
            ->when(
                $validated['from_date'] ?? null,
                fn (Builder $query, string $date) => $query->whereDate('requested_start_at', '>=', $date)
            )
            ->when(
                $validated['to_date'] ?? null,
                fn (Builder $query, string $date) => $query->whereDate('requested_start_at', '<=', $date)
            )
            ->orderByRaw(
                "CASE
                    WHEN status = 'pending' THEN 1
                    WHEN status = 'confirmed' THEN 2
                    WHEN status = 'in_progress' THEN 3
                    WHEN status = 'completed' THEN 4
                    WHEN status = 'cancelled' THEN 5
                    WHEN status = 'no_show' THEN 6
                    ELSE 7
                END"
            )
            ->orderBy('requested_start_at')
            ->paginate($validated['per_page'] ?? 15)
            ->withQueryString();

        return AppointmentResource::collection($appointments)
            ->additional([
                'filters' => [
                    'departments' => Department::query()
                        ->orderBy('sort_order')
                        ->get(['id', 'code', 'name']),
                ],
            ]);
    }

    public function show(
        Appointment $appointment
    ): AdminAppointmentResource {
        return new AdminAppointmentResource(
            $this->load($appointment)
        );
    }

    public function update(
        UpdateAdminAppointmentRequest $request,
        Appointment $appointment,
        ManageAppointmentService $service
    ): AdminAppointmentResource {
        return new AdminAppointmentResource(
            $service->update($appointment, $request->validated())
        );
    }

    public function confirm(
        ConfirmAdminAppointmentRequest $request,
        Appointment $appointment,
        ManageAppointmentService $service
    ): AdminAppointmentResource {
        return new AdminAppointmentResource(
            $service->confirm($appointment, $request->validated())
        );
    }

    public function start(
        UpdateAdminAppointmentStatusRequest $request,
        Appointment $appointment,
        ManageAppointmentService $service
    ): AdminAppointmentResource {
        return new AdminAppointmentResource(
            $service->start($appointment, $request->validated())
        );
    }

    public function complete(
        UpdateAdminAppointmentStatusRequest $request,
        Appointment $appointment,
        ManageAppointmentService $service
    ): AdminAppointmentResource {
        return new AdminAppointmentResource(
            $service->complete($appointment, $request->validated())
        );
    }

    public function cancel(
        CancelAdminAppointmentRequest $request,
        Appointment $appointment,
        ManageAppointmentService $service
    ): AdminAppointmentResource {
        return new AdminAppointmentResource(
            $service->cancel($appointment, $request->validated())
        );
    }

    public function noShow(
        UpdateAdminAppointmentStatusRequest $request,
        Appointment $appointment,
        ManageAppointmentService $service
    ): AdminAppointmentResource {
        return new AdminAppointmentResource(
            $service->markNoShow($appointment, $request->validated())
        );
    }

    private function load(Appointment $appointment): Appointment
    {
        return $appointment->load([
            'customer',
            'department',
            'coupon',
            'items.services',
        ]);
    }
}
