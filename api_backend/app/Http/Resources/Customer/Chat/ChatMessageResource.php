<?php

namespace App\Http\Resources\Customer\Chat;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\ChatMessage
 */
class ChatMessageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'conversation_id' =>
                $this->chat_conversation_id,
            'sender' => $this->sender,
            'content' => $this->content,
            'metadata' => $this->metadata,
            'created_at' =>
                $this->created_at?->toISOString(),
        ];
    }
}