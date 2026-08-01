<?php

namespace App\Services\Notifications;

use App\Models\Appointment;
use App\Models\DeviceToken;
use App\Models\User;
use App\Services\FirebaseMessagingService;
use App\Support\Notifications\NotificationType;
use Illuminate\Support\Facades\Log;
use Throwable;

final class AppointmentNotificationService
{
    public function __construct(
        private readonly CreateAppNotificationService $createNotificationService,
        private readonly FirebaseMessagingService $firebaseMessagingService,
    ) {
    }

    public function appointmentCreated(Appointment $appointment): void
    {
        try {
            $appointment->loadMissing([
                'customer',
                'department',
            ]);

            $managers = User::role('manager')
                ->where('is_active', true)
                ->get();

            foreach ($managers as $manager) {
                $this->notifyUser(
                    user: $manager,
                    app: 'admin',
                    type: NotificationType::APPOINTMENT_CREATED,
                    title: 'طلب حجز جديد',
                    body: sprintf(
                        'قدمت %s طلب حجز جديد برقم %s.',
                        $appointment->customer->name,
                        $appointment->reference,
                    ),
                    appointment: $appointment,
                    deduplicationKey: sprintf(
                        'appointment:%d:created:manager:%d',
                        $appointment->id,
                        $manager->id,
                    ),
                );
            }
        } catch (Throwable $exception) {
            Log::error('Failed to notify managers about new appointment.', [
                'appointment_id' => $appointment->id,
                'error' => $exception->getMessage(),
            ]);
        }
    }

    public function appointmentStatusChanged(Appointment $appointment): void
    {
        try {
            $appointment->loadMissing([
                'customer',
                'department',
            ]);

            if (
                $appointment->status === Appointment::STATUS_CANCELLED
                && $appointment->cancelled_by === 'customer'
            ) {
                $this->notifyManagersAboutCustomerCancellation($appointment);

                return;
            }

            $message = $this->customerStatusMessage($appointment);

            if ($message === null) {
                return;
            }

            $customer = $appointment->customer;

            if (! $customer instanceof User) {
                return;
            }

            $this->notifyUser(
                user: $customer,
                app: 'customer',
                type: $message['type'],
                title: $message['title'],
                body: $message['body'],
                appointment: $appointment,
                deduplicationKey: sprintf(
                    'appointment:%d:status:%s:customer:%d',
                    $appointment->id,
                    $appointment->status,
                    $customer->id,
                ),
            );
        } catch (Throwable $exception) {
            Log::error('Failed to notify about appointment status.', [
                'appointment_id' => $appointment->id,
                'status' => $appointment->status,
                'error' => $exception->getMessage(),
            ]);
        }
    }

    private function notifyManagersAboutCustomerCancellation(
        Appointment $appointment
    ): void {
        $managers = User::role('manager')
            ->where('is_active', true)
            ->get();

        foreach ($managers as $manager) {
            $this->notifyUser(
                user: $manager,
                app: 'admin',
                type: NotificationType::APPOINTMENT_CANCELLED,
                title: 'إلغاء حجز من الزبونة',
                body: sprintf(
                    'ألغت %s الحجز رقم %s.',
                    $appointment->customer->name,
                    $appointment->reference,
                ),
                appointment: $appointment,
                deduplicationKey: sprintf(
                    'appointment:%d:cancelled-by-customer:manager:%d',
                    $appointment->id,
                    $manager->id,
                ),
            );
        }
    }

    /**
     * @return array{type: string, title: string, body: string}|null
     */
    private function customerStatusMessage(
        Appointment $appointment
    ): ?array {
        return match ($appointment->status) {
            Appointment::STATUS_CONFIRMED => [
                'type' => NotificationType::APPOINTMENT_CONFIRMED,
                'title' => 'تم تأكيد موعدك',
                'body' => sprintf(
                    'تم تأكيد حجزك رقم %s.',
                    $appointment->reference,
                ),
            ],

            Appointment::STATUS_IN_PROGRESS => [
                'type' => NotificationType::APPOINTMENT_UPDATED,
                'title' => 'بدأ موعدك',
                'body' => sprintf(
                    'بدأ تنفيذ موعدك رقم %s.',
                    $appointment->reference,
                ),
            ],

            Appointment::STATUS_COMPLETED => [
                'type' => NotificationType::APPOINTMENT_UPDATED,
                'title' => 'اكتمل موعدك',
                'body' => sprintf(
                    'تم إكمال موعدك رقم %s بنجاح.',
                    $appointment->reference,
                ),
            ],

            Appointment::STATUS_CANCELLED => [
                'type' => NotificationType::APPOINTMENT_CANCELLED,
                'title' => 'تم إلغاء موعدك',
                'body' => sprintf(
                    'تم إلغاء حجزك رقم %s.',
                    $appointment->reference,
                ),
            ],

            default => null,
        };
    }

    private function notifyUser(
        User $user,
        string $app,
        string $type,
        string $title,
        string $body,
        Appointment $appointment,
        string $deduplicationKey,
    ): void {
        $data = [
            'type' => $type,
            'screen' => $app === 'admin'
                ? 'admin_appointment_details'
                : 'customer_appointment_details',
            'appointment_id' => $appointment->id,
            'reference' => $appointment->reference,
            'status' => $appointment->status,
        ];

        $notification = $this->createNotificationService->create(
            user: $user,
            type: $type,
            title: $title,
            body: $body,
            data: $data,
            deduplicationKey: $deduplicationKey,
        );

        $tokens = DeviceToken::query()
            ->where('user_id', $user->id)
            ->where('app', $app)
            ->where('is_active', true)
            ->where('notifications_enabled', true)
            ->get();

        foreach ($tokens as $deviceToken) {
            try {
                $this->firebaseMessagingService->sendToToken(
                    token: $deviceToken->token,
                    title: $title,
                    body: $body,
                    data: [
                        ...$data,
                        'notification_id' => $notification->id,
                    ],
                );
            } catch (Throwable $exception) {
                Log::warning('Firebase appointment notification failed.', [
                    'appointment_id' => $appointment->id,
                    'device_token_id' => $deviceToken->id,
                    'user_id' => $user->id,
                    'error' => $exception->getMessage(),
                ]);
            }
        }
    }
}