<?php

namespace App\Http\Controllers\Api\Admin;
use App\Models\Appointment;
use Illuminate\Http\JsonResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\CustomerResource;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CustomerController extends Controller
{
    /**
     * Display a listing of customers.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $customers = User::query()
            ->role('customer')
            ->when(
                $request->filled('search'),
                function (Builder $query) use ($request): void {
                    $search = trim(
                        $request->string('search')->toString()
                    );

                    $query->where(
                        function (Builder $searchQuery) use ($search): void {
                            $searchQuery
                                ->where('name', 'ILIKE', "%{$search}%")
                                ->orWhere('phone', 'ILIKE', "%{$search}%")
                                ->orWhere('email', 'ILIKE', "%{$search}%");
                        }
                    );
                }
            )
            ->when(
                $request->has('is_active'),
                function (Builder $query) use ($request): void {
                    $query->where(
                        'is_active',
                        filter_var(
                            $request->input('is_active'),
                            FILTER_VALIDATE_BOOLEAN
                        )
                    );
                }
            )
            ->orderBy('id')
            ->get();

        return CustomerResource::collection($customers);
    }
    public function show(User $customer): JsonResponse
{
    abort_unless(
        $customer->hasRole('customer'),
        404
    );

    $appointmentsQuery = Appointment::query()
        ->where('customer_id', $customer->id);

    $lastAppointment = (clone $appointmentsQuery)
        ->orderByDesc('requested_start_at')
        ->first();

    return response()->json([
        'data' => [
            'id' => $customer->id,
            'name' => $customer->name,
            'phone' => $customer->phone,
            'email' => $customer->email,
            'avatar' => $customer->avatar,
            'is_active' => $customer->is_active,
            'created_at' => $customer->created_at?->toISOString(),

            'appointments_count' =>
                (clone $appointmentsQuery)->count(),

            'last_appointment_at' =>
                $lastAppointment
                    ?->requested_start_at
                    ?->toISOString(),

            'appointments' => (clone $appointmentsQuery)
                ->orderByDesc('requested_start_at')
                ->limit(10)
                ->get([
                    'id',
                    'reference',
                    'status',
                    'department_id',
                    'requested_start_at',
                    'confirmed_start_at',
                ]),
        ],
    ]);
}
}