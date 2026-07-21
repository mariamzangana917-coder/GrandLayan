<?php

namespace App\Http\Controllers\Api\Customer\Chat;

use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\Chat\SendChatMessageRequest;
use App\Http\Resources\Customer\Chat\ChatConversationResource;
use App\Http\Resources\Customer\Chat\ChatMessageResource;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Services\Chat\GrandLayanAssistantService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CustomerChatController extends Controller
{
    public function __construct(
        private readonly GrandLayanAssistantService $assistant,
    ) {
    }

    public function index(Request $request)
    {
        $conversations = ChatConversation::query()
            ->where('customer_id', $request->user()->id)
            ->latest('last_message_at')
            ->paginate(20);

        return ChatConversationResource::collection($conversations);
    }

    public function show(Request $request, ChatConversation $conversation)
    {
        abort_unless(
            $conversation->customer_id === $request->user()->id,
            404
        );

        $conversation->load('messages');

        return new ChatConversationResource($conversation);
    }

    public function send(
        SendChatMessageRequest $request,
    ): JsonResponse {
        return DB::transaction(function () use ($request) {

            $conversation = $request->filled('conversation_id')
                ? ChatConversation::query()
                    ->whereKey($request->integer('conversation_id'))
                    ->where('customer_id', $request->user()->id)
                    ->firstOrFail()
                : ChatConversation::create([
                    'customer_id' => $request->user()->id,
                    'last_message_at' => now(),
                ]);

            $customerMessage = ChatMessage::create([
                'chat_conversation_id' => $conversation->id,
                'sender' => ChatMessage::SENDER_CUSTOMER,
                'content' => $request->string('message'),
            ]);

            $assistant = $this->assistant->reply(
                $request->string('message')->toString(),
            );

            $assistantMessage = ChatMessage::create([
                'chat_conversation_id' => $conversation->id,
                'sender' => ChatMessage::SENDER_ASSISTANT,
                'content' => $assistant['answer'],
                'metadata' => [
    'in_scope' => $assistant['in_scope'],
    'provider' => $assistant['provider'],
],
            ]);

            $conversation->update([
                'last_message_at' => now(),
            ]);

            return response()->json([
                'conversation' => new ChatConversationResource(
                    $conversation->fresh(),
                ),
                'customer_message' => new ChatMessageResource(
                    $customerMessage,
                ),
                'assistant_message' => new ChatMessageResource(
                    $assistantMessage,
                ),
            ]);
        });
    }
}