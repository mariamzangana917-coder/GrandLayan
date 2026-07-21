import 'chat_message.dart';

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.messages,
    this.lastMessage,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final List<ChatMessage> messages;
  final ChatMessage? lastMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final messages = _readMessages(json['messages']);

    return ChatConversation(
      id: _readInt(json['id']),
      title: _readString(json['title'], fallback: 'محادثة كراند ليان'),
      messages: messages,
      lastMessage: _readLastMessage(json['last_message'], messages),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  ChatConversation copyWith({
    String? title,
    List<ChatMessage>? messages,
    ChatMessage? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<ChatMessage> _readMessages(dynamic value) {
    dynamic normalizedValue = value;

    if (value is Map) {
      normalizedValue = value['data'];
    }

    if (normalizedValue is! List) {
      return const <ChatMessage>[];
    }

    return normalizedValue
        .whereType<Map>()
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static ChatMessage? _readLastMessage(
    dynamic value,
    List<ChatMessage> messages,
  ) {
    if (value is Map) {
      return ChatMessage.fromJson(Map<String, dynamic>.from(value));
    }

    if (messages.isNotEmpty) {
      return messages.last;
    }

    return null;
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value, {required String fallback}) {
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
