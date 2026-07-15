<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function __invoke(): JsonResponse
    {
        $todayAppointments = Appointment::query()
            ->whereDate('requested_start_at', now()->toDateString());

        $nextPendingAppointment = Appointment::query()
            ->with([
                'customer',
                'department',
                'items.services',
            ])
            ->where('status', Appointment::STATUS_PENDING)
            ->where('requested_start_at', '>=', now())
            ->orderBy('requested_start_at')
            ->first();

        return response()->json([
            'data' => [
                'summary' => [
                    'today' => (clone $todayAppointments)->count(),

                    'pending' => (clone $todayAppointments)
                        ->where(
                            'status',
                            Appointment::STATUS_PENDING
                        )
                        ->count(),

                    'in_progress' => (clone $todayAppointments)
                        ->where(
                            'status',
                            Appointment::STATUS_IN_PROGRESS
                        )
                        ->count(),

                    'completed' => (clone $todayAppointments)
                        ->where(
                            'status',
                            Appointment::STATUS_COMPLETED
                        )
                        ->count(),
                ],

                'follow_up' => $nextPendingAppointment
                    ? new AppointmentResource(
                        $nextPendingAppointment
                    )
                    : null,
            ],
        ]);
    }
}