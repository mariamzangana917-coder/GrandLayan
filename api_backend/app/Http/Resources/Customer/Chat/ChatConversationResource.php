<?php

namespace App\Http\Resources\Customer\Chat;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\ChatConversation
 */
class ChatConversationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'last_message_at' =>
                $this->last_message_at?->toISOString(),
            'created_at' =>
                $this->created_at?->toISOString(),

            'messages' => ChatMessageResource::collection(
                $this->whenLoaded('messages'),
            ),
        ];
    }
}