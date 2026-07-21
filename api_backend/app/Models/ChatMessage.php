<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatMessage extends Model
{
    use HasFactory;

    public const SENDER_CUSTOMER = 'customer';
    public const SENDER_ASSISTANT = 'assistant';

    protected $fillable = [
        'chat_conversation_id',
        'sender',
        'content',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'metadata' => 'array',
        ];
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(
            ChatConversation::class,
            'chat_conversation_id',
        );
    }
}