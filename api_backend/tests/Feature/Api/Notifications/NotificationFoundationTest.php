<?php

namespace Tests\Feature\Api\Notifications;

use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\NotificationPreference;
use App\Models\User;
use App\Services\Notifications\CreateAppNotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class NotificationFoundationTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;

    private User $manager;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer', 'web');
        Role::findOrCreate('manager', 'web');

        $this->customer = User::factory()->create(['is_active' => true]);
        $this->customer->assignRole('customer');

        $this->manager = User::factory()->create(['is_active' => true]);
        $this->manager->assignRole('manager');
    }

    public function test_guest_cannot_access_notification_endpoints(): void
    {
        $this->getJson('/api/customer/notifications')->assertUnauthorized();
        $this->getJson('/api/admin/notifications')->assertUnauthorized();
    }

    public function test_customer_can_only_list_own_notifications(): void
    {
        AppNotification::query()->create([
            'user_id' => $this->customer->id,
            'type' => 'appointment_confirmed',
            'title' => 'تم تأكيد الحجز',
            'body' => 'تم تأكيد موعدچ.',
        ]);

        AppNotification::query()->create([
            'user_id' => $this->manager->id,
            'type' => 'appointment_created',
            'title' => 'حجز جديد',
            'body' => 'وصل حجز جديد.',
        ]);

        Sanctum::actingAs($this->customer);

        $this->getJson('/api/customer/notifications')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'تم تأكيد الحجز');
    }

    public function test_customer_cannot_use_admin_notification_routes(): void
    {
        Sanctum::actingAs($this->customer);

        $this->getJson('/api/admin/notifications')->assertForbidden();
    }

    public function test_unread_count_and_read_operations_are_scoped_to_user(): void
    {
        $own = AppNotification::query()->create([
            'user_id' => $this->customer->id,
            'type' => 'general',
            'title' => 'إشعار',
            'body' => 'تفاصيل الإشعار.',
        ]);

        $other = AppNotification::query()->create([
            'user_id' => $this->manager->id,
            'type' => 'general',
            'title' => 'إشعار مدير',
            'body' => 'تفاصيل.',
        ]);

        Sanctum::actingAs($this->customer);

        $this->getJson('/api/customer/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 1);

        $this->patchJson("/api/customer/notifications/{$other->id}/read")
            ->assertNotFound();

        $this->patchJson("/api/customer/notifications/{$own->id}/read")
            ->assertOk()
            ->assertJsonPath('data.is_read', true);

        $this->getJson('/api/customer/notifications/unread-count')
            ->assertJsonPath('data.unread_count', 0);
    }

    public function test_mark_all_read_only_updates_current_user(): void
    {
        AppNotification::query()->create([
            'user_id' => $this->customer->id,
            'type' => 'general',
            'title' => 'الأول',
            'body' => 'الأول',
        ]);

        AppNotification::query()->create([
            'user_id' => $this->customer->id,
            'type' => 'general',
            'title' => 'الثاني',
            'body' => 'الثاني',
        ]);

        $managerNotification = AppNotification::query()->create([
            'user_id' => $this->manager->id,
            'type' => 'general',
            'title' => 'للمديرة',
            'body' => 'للمديرة',
        ]);

        Sanctum::actingAs($this->customer);

        $this->postJson('/api/customer/notifications/read-all')
            ->assertOk()
            ->assertJsonPath('data.updated_count', 2);

        $this->assertDatabaseHas('app_notifications', [
            'id' => $managerNotification->id,
            'read_at' => null,
        ]);

        $this->assertNull($managerNotification->refresh()->read_at);
    }

    public function test_customer_can_register_update_and_disable_device_token(): void
    {
        Sanctum::actingAs($this->customer);

        $payload = [
            'token' => 'customer-device-token',
            'platform' => 'android',
            'device_id' => 'device-1',
            'device_name' => 'Samsung',
            'timezone' => 'Asia/Baghdad',
        ];

        $created = $this->postJson('/api/customer/device-tokens', $payload)
            ->assertCreated()
            ->assertJsonPath('data.app', 'customer')
            ->assertJsonPath('data.is_active', true);

        $deviceTokenId = (int) $created->json('data.id');

        $this->postJson('/api/customer/device-tokens', [
            ...$payload,
            'device_name' => 'Samsung Updated',
        ])
            ->assertOk()
            ->assertJsonPath('data.device_name', 'Samsung Updated');

        $this->assertDatabaseCount('device_tokens', 1);

        $this->deleteJson("/api/customer/device-tokens/{$deviceTokenId}")
            ->assertNoContent();

        $this->assertDatabaseHas('device_tokens', [
            'id' => $deviceTokenId,
            'is_active' => false,
            'notifications_enabled' => false,
        ]);
    }

    public function test_user_cannot_disable_another_users_device_token(): void
    {
        $token = DeviceToken::query()->create([
            'user_id' => $this->manager->id,
            'app' => 'admin',
            'platform' => 'android',
            'token' => 'manager-token',
            'notifications_enabled' => true,
            'is_active' => true,
        ]);

        Sanctum::actingAs($this->customer);

        $this->deleteJson("/api/customer/device-tokens/{$token->id}")
            ->assertNotFound();
    }

    public function test_notification_preferences_have_defaults_and_can_be_updated(): void
    {
        Sanctum::actingAs($this->customer);

        $this->getJson('/api/customer/notification-preferences')
            ->assertOk()
            ->assertJsonPath('data.push_enabled', true)
            ->assertJsonPath('data.offers', true)
            ->assertJsonPath(
                'data.security_notifications_always_enabled',
                true,
            );

        $this->putJson('/api/customer/notification-preferences', [
            'offers' => false,
            'chat_messages' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.offers', false)
            ->assertJsonPath('data.chat_messages', false)
            ->assertJsonPath('data.appointment_updates', true);

        $this->assertDatabaseHas('notification_preferences', [
            'user_id' => $this->customer->id,
            'offers' => false,
            'chat_messages' => false,
        ]);
    }

    public function test_create_notification_service_prevents_duplicates(): void
    {
        $service = app(CreateAppNotificationService::class);

        $first = $service->create(
            user: $this->customer,
            type: 'appointment_reminder',
            title: 'تذكير بالموعد',
            body: 'موعدچ غدًا.',
            data: ['appointment_id' => 55],
            deduplicationKey: 'appointment:55:reminder:day-before',
        );

        $second = $service->create(
            user: $this->customer,
            type: 'appointment_reminder',
            title: 'تذكير بالموعد',
            body: 'موعدچ غدًا.',
            data: ['appointment_id' => 55],
            deduplicationKey: 'appointment:55:reminder:day-before',
        );

        $this->assertSame($first->id, $second->id);
        $this->assertDatabaseCount('app_notifications', 1);
    }

    public function test_manager_device_token_is_marked_as_admin_app(): void
    {
        Sanctum::actingAs($this->manager);

        $this->postJson('/api/admin/device-tokens', [
            'token' => 'admin-device-token',
            'platform' => 'ios',
        ])
            ->assertCreated()
            ->assertJsonPath('data.app', 'admin');

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $this->manager->id,
            'app' => 'admin',
            'platform' => 'ios',
        ]);
    }
}
