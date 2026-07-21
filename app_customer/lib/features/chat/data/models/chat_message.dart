class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    this.conversationId,
    this.createdAt,
  });

  final int id;
  final int? conversationId;
  final String sender;
  final String content;
  final DateTime? createdAt;

  bool get isCustomer => sender == 'customer';

  bool get isAssistant => sender == 'assistant';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _readInt(json['id']),
      conversationId: _readNullableInt(
        json['chat_conversation_id'] ?? json['conversation_id'],
      ),
      sender: _readString(json['sender'], fallback: 'assistant'),
      content: _readString(json['content'] ?? json['message']),
      createdAt: _readDateTime(json['created_at']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final normalizedValue = value.toString().trim();

    if (normalizedValue.isEmpty) {
      return fallback;
    }

    return normalizedValue;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
