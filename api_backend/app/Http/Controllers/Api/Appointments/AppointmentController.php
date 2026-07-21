<?php

namespace App\Http\Controllers\Api\Appointments;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Appointments\StoreAppointmentRequest;
use App\Http\Resources\AppointmentResource;
use App\Services\Appointments\CreateAppointmentService;
use Illuminate\Http\JsonResponse;

class AppointmentController extends Controller
{
    /**
     * Store a newly created customer appointment.
     */
    public function store(
        StoreAppointmentRequest $request,
        CreateAppointmentService $service
    ): JsonResponse {
        $appointment = $service->create(
            customer: $request->user(),
            data: $request->validated(),
        );

        return response()->json([
            'message' => 'تم إرسال طلب الحجز بنجاح.',
            'data' => new AppointmentResource($appointment),
        ], 201);
    }
}
