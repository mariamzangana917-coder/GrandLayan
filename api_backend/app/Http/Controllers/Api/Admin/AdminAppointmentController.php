<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\AdminAppointmentResource;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AdminAppointmentController extends Controller
{
    public function index(
        Request $request
    ): AnonymousResourceCollection {
        $validated = $request->validate([
            'search' => [
                'nullable',
                'string',
                'max:150',
            ],

            'status' => [
                'nullable',
                'string',
                'in:pending,confirmed,in_progress,completed,cancelled,no_show',
            ],

            'department_id' => [
                'nullable',
                'integer',
                'exists:departments,id',
            ],

            'date' => [
                'nullable',
                'date_format:Y-m-d',
            ],

            'from_date' => [
                'nullable',
                'date_format:Y-m-d',
            ],

            'to_date' => [
                'nullable',
                'date_format:Y-m-d',
                'after_or_equal:from_date',
            ],

            'per_page' => [
                'nullable',
                'integer',
                'min:1',
                'max:50',
            ],
        ]);

        $query = Appointment::query()
            ->with([
                'customer',
                'department',
                'items.services',
            ]);

        if (! empty($validated['search'])) {
            $search = trim($validated['search']);

            $query->where(function ($query) use ($search): void {
                $query
                    ->where(
                        'reference',
                        'ilike',
                        "%{$search}%"
                    )
                    ->orWhereHas(
                        'customer',
                        function ($customerQuery) use ($search): void {
                            $customerQuery
                                ->where(
                                    'name',
                                    'ilike',
                                    "%{$search}%"
                                )
                                ->orWhere(
                                    'phone',
                                    'ilike',
                                    "%{$search}%"
                                )
                                ->orWhere(
                                    'email',
                                    'ilike',
                                    "%{$search}%"
                                );
                        }
                    );
            });
        }

        if (! empty($validated['status'])) {
            $query->where(
                'status',
                $validated['status']
            );
        }

        if (! empty($validated['department_id'])) {
            $query->where(
                'department_id',
                $validated['department_id']
            );
        }

        if (! empty($validated['date'])) {
            $query->whereDate(
                'requested_start_at',
                $validated['date']
            );
        }

        if (! empty($validated['from_date'])) {
            $query->whereDate(
                'requested_start_at',
                '>=',
                $validated['from_date']
            );
        }

        if (! empty($validated['to_date'])) {
            $query->whereDate(
                'requested_start_at',
                '<=',
                $validated['to_date']
            );
        }

        $appointments = $query
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
            ->paginate(
                $validated['per_page'] ?? 15
            )
            ->withQueryString();

        return AppointmentResource::collection(
            $appointments
        );
    }

    
        public function show(
    Appointment $appointment
): AdminAppointmentResource {
    $appointment->load([
        'customer',
        'department',
        'items.services',
    ]);

    return new AdminAppointmentResource(
        $appointment
    );
}
}