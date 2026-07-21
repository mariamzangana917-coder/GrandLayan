<?php

namespace Tests\Feature\Api\Customer\Chat;

use App\Services\Chat\GrandLayanAssistantService;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class CustomerChatTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::findOrCreate('customer');
        Role::findOrCreate('manager');
    }

    public function test_guest_cannot_list_chat_conversations(): void
    {
        $response = $this->getJson(
            '/api/customer/auth/chat/conversations'
        );

        $response->assertUnauthorized();
    }

    public function test_manager_cannot_use_customer_chat_routes(): void
    {
        $manager = User::factory()->create();

        $manager->assignRole('manager');

        Sanctum::actingAs($manager);

        $response = $this->getJson(
            '/api/customer/auth/chat/conversations'
        );

        $response->assertForbidden();
    }

    public function test_customer_can_list_only_her_conversations(): void
    {
        $customer = $this->createCustomer();
        $otherCustomer = $this->createCustomer();

        $customerConversation = ChatConversation::query()->create([
            'customer_id' => $customer->id,
            'title' => 'محادثة الزبونة',
        ]);

        ChatConversation::query()->create([
            'customer_id' => $otherCustomer->id,
            'title' => 'محادثة زبونة أخرى',
        ]);

        Sanctum::actingAs($customer);

        $response = $this->getJson(
            '/api/customer/auth/chat/conversations'
        );

        $response
            ->assertOk()
            ->assertJsonFragment([
                'id' => $customerConversation->id,
            ])
            ->assertJsonMissing([
                'title' => 'محادثة زبونة أخرى',
            ]);
    }

    public function test_customer_can_open_her_own_conversation(): void
    {
        $customer = $this->createCustomer();

        $conversation = ChatConversation::query()->create([
              'customer_id' => $customer->id,
            'title' => 'استفسار عن الخدمات',
        ]);

  ChatMessage::query()->create([
    'chat_conversation_id' => $conversation->id,
    'sender' => 'customer',
    'content' => 'شكد سعر قص الشعر؟',
]);

ChatMessage::query()->create([
    'chat_conversation_id' => $conversation->id,
    'sender' => 'assistant',
    'content' => 'سعر الخدمة موجود ضمن خدمات المركز.',
]);

        Sanctum::actingAs($customer);

        $response = $this->getJson(
            "/api/customer/auth/chat/conversations/{$conversation->id}"
        );

        $response
            ->assertOk()
            ->assertJsonFragment([
                'id' => $conversation->id,
            ])
            ->assertJsonFragment([
                'content' => 'شكد سعر قص الشعر؟',
            ])
            ->assertJsonFragment([
                'content' => 'سعر الخدمة موجود ضمن خدمات المركز.',
            ]);
    }

    public function test_customer_cannot_open_another_customers_conversation(): void
    {
        $customer = $this->createCustomer();
        $otherCustomer = $this->createCustomer();

        $conversation = ChatConversation::query()->create([
             'customer_id' => $otherCustomer->id,
            'title' => 'محادثة خاصة',
        ]);

        Sanctum::actingAs($customer);

        $response = $this->getJson(
            "/api/customer/auth/chat/conversations/{$conversation->id}"
        );

        $response->assertNotFound();

    }

public function test_customer_can_send_message_and_create_new_conversation(): void
{
    $customer = $this->createCustomer();

    $this->mock(
        GrandLayanAssistantService::class,
        function ($mock): void {
            $mock->shouldReceive('reply')
                ->once()
                ->with('شكد سعر قص الشعر؟')
                ->andReturn([
                    'answer' => 'سعر قص الشعر 25 ألف دينار مع السشوار.',
                    'in_scope' => true,
                    'provider' => 'test',
                ]);
        }
    );

    Sanctum::actingAs($customer);

    $response = $this->postJson(
        '/api/customer/auth/chat/messages',
        [
            'message' => 'شكد سعر قص الشعر؟',
        ]
    );

    $response->assertSuccessful();

    $conversation = ChatConversation::query()
        ->where('customer_id', $customer->id)
        ->first();

    $this->assertNotNull($conversation);

    $this->assertDatabaseHas('chat_messages', [
        'chat_conversation_id' => $conversation->id,
        'sender' => 'customer',
        'content' => 'شكد سعر قص الشعر؟',
    ]);

    $this->assertDatabaseHas('chat_messages', [
        'chat_conversation_id' => $conversation->id,
        'sender' => 'assistant',
        'content' => 'سعر قص الشعر 25 ألف دينار مع السشوار.',
    ]);

    $this->assertDatabaseCount('chat_conversations', 1);
    $this->assertDatabaseCount('chat_messages', 2);
}
public function test_customer_can_send_message_to_existing_conversation(): void
{
    $customer = $this->createCustomer();

    $conversation = ChatConversation::query()->create([
        'customer_id' => $customer->id,
        'title' => 'استفسارات الخدمات',
    ]);

    $this->mock(
        GrandLayanAssistantService::class,
        function ($mock): void {
            $mock->shouldReceive('reply')
                ->once()
                ->with('وشكد مدتها؟')
                ->andReturn([
                    'answer' => 'مدة الخدمة موجودة ضمن تفاصيل الخدمة.',
                    'in_scope' => true,
                    'provider' => 'test',
                ]);
        }
    );

    Sanctum::actingAs($customer);

    $response = $this->postJson(
        '/api/customer/auth/chat/messages',
        [
            'conversation_id' => $conversation->id,
            'message' => 'وشكد مدتها؟',
        ]
    );

    $response->assertSuccessful();

    $this->assertDatabaseCount('chat_conversations', 1);

    $this->assertDatabaseHas('chat_messages', [
        'chat_conversation_id' => $conversation->id,
        'sender' => 'customer',
        'content' => 'وشكد مدتها؟',
    ]);

    $this->assertDatabaseHas('chat_messages', [
        'chat_conversation_id' => $conversation->id,
        'sender' => 'assistant',
        'content' => 'مدة الخدمة موجودة ضمن تفاصيل الخدمة.',
    ]);

    $this->assertDatabaseCount('chat_messages', 2);
}

public function test_customer_cannot_send_message_to_another_customers_conversation(): void
{
    $customer = $this->createCustomer();
    $otherCustomer = $this->createCustomer();

    $conversation = ChatConversation::query()->create([
        'customer_id' => $otherCustomer->id,
        'title' => 'محادثة خاصة',
    ]);

    Sanctum::actingAs($customer);

    $response = $this->postJson(
        '/api/customer/auth/chat/messages',
        [
            'conversation_id' => $conversation->id,
            'message' => 'أريد أرسل رسالة هنا',
        ]
    );

    $response->assertNotFound();

    $this->assertDatabaseCount('chat_messages', 0);
}


public function test_customer_cannot_send_empty_message(): void
{
    $customer = $this->createCustomer();

    Sanctum::actingAs($customer);

    $response = $this->postJson(
        '/api/customer/auth/chat/messages',
        [
            'message' => '',
        ]
    );

    $response
        ->assertUnprocessable()
        ->assertJsonValidationErrors([
            'message',
        ]);

    $this->assertDatabaseCount('chat_conversations', 0);
    $this->assertDatabaseCount('chat_messages', 0);
}


public function test_conversation_messages_are_returned_in_creation_order(): void
{
    $customer = $this->createCustomer();

    $conversation = ChatConversation::query()->create([
        'customer_id' => $customer->id,
        'title' => 'ترتيب الرسائل',
    ]);

    ChatMessage::query()->create([
        'chat_conversation_id' => $conversation->id,
        'sender' => 'customer',
        'content' => 'الرسالة الأولى',
        'created_at' => now()->subMinutes(2),
        'updated_at' => now()->subMinutes(2),
    ]);

    ChatMessage::query()->create([
        'chat_conversation_id' => $conversation->id,
        'sender' => 'assistant',
        'content' => 'الرسالة الثانية',
        'created_at' => now()->subMinute(),
        'updated_at' => now()->subMinute(),
    ]);

    Sanctum::actingAs($customer);

    $response = $this->getJson(
        "/api/customer/auth/chat/conversations/{$conversation->id}"
    );

    $response->assertOk();

    $messages = $response->json('data.messages')
        ?? $response->json('messages');

    $this->assertIsArray($messages);
    $this->assertCount(2, $messages);
    $this->assertSame('الرسالة الأولى', $messages[0]['content']);
    $this->assertSame('الرسالة الثانية', $messages[1]['content']);
}

public function test_customer_receives_not_found_for_missing_conversation(): void
{
    $customer = $this->createCustomer();

    Sanctum::actingAs($customer);

    $response = $this->getJson(
        '/api/customer/auth/chat/conversations/999999'
    );

    $response->assertNotFound();
}


    private function createCustomer(): User
    {
        $customer = User::factory()->create();

        $customer->assignRole('customer');

        return $customer;
    }
}