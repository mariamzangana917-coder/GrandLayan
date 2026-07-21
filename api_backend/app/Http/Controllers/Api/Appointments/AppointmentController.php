<?php

namespace App\Http\Controllers\Api\Appointments;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Appointments\CancelCustomerAppointmentRequest;
use App\Http\Requests\Api\Appointments\StoreAppointmentRequest;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use App\Services\Appointments\CreateAppointmentService;
use App\Services\Appointments\ManageAppointmentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AppointmentController extends Controller
{
    /**
     * Display the authenticated customer's appointments.
     */
    public function index(
        Request $request
    ): AnonymousResourceCollection {
        $appointments = Appointment::query()
            ->where('customer_id', $request->user()->id)
            ->with([
                'customer',
                'department',
                'items.services',
            ])
            ->orderByRaw(
                'COALESCE(confirmed_start_at, requested_start_at) DESC'
            )
            ->paginate(15)
            ->withQueryString();

        return AppointmentResource::collection($appointments);
    }

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

    /**
     * Display one appointment owned by the authenticated customer.
     */
    public function show(
        Request $request,
        int $appointment
    ): AppointmentResource {
        $customerAppointment = $this->findCustomerAppointment(
            customerId: (int) $request->user()->id,
            appointmentId: $appointment,
        );

        return new AppointmentResource($customerAppointment);
    }

    /**
     * Cancel one appointment owned by the authenticated customer.
     */
    public function cancel(
        CancelCustomerAppointmentRequest $request,
        int $appointment,
        ManageAppointmentService $service
    ): JsonResponse {
        $customerAppointment = $this->findCustomerAppointment(
            customerId: (int) $request->user()->id,
            appointmentId: $appointment,
        );

        $cancelledAppointment = $service->cancelByCustomer(
            appointment: $customerAppointment,
            reason: $request->validated('reason'),
        );

        return response()->json([
            'message' => 'تم إلغاء الموعد بنجاح.',
            'data' => new AppointmentResource($cancelledAppointment),
        ]);
    }

    /**
     * Find an appointment belonging only to the current customer.
     *
     * Using a customer-scoped query prevents IDOR attacks.
     */
    private function findCustomerAppointment(
        int $customerId,
        int $appointmentId
    ): Appointment {
        return Appointment::query()
            ->where('customer_id', $customerId)
            ->with([
                'customer',
                'department',
                'items.services',
            ])
            ->findOrFail($appointmentId);
    }
}