import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/chat_conversation.dart';

class ChatRepository {
  const ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String _basePath = '/customer/auth/chat';

  Future<List<ChatConversation>> getConversations() async {
    final response = await _apiClient.get('$_basePath/conversations');

    final conversationsData = _extractList(
      response,
      possibleKeys: const ['conversations', 'items'],
    );

    return conversationsData
        .whereType<Map>()
        .map(
          (conversation) => ChatConversation.fromJson(
            Map<String, dynamic>.from(conversation),
          ),
        )
        .where((conversation) => conversation.id > 0)
        .toList(growable: false);
  }

  Future<ChatConversation> getConversation(int conversationId) async {
    final response = await _apiClient.get(
      '$_basePath/conversations/$conversationId',
    );

    final conversationData = _extractConversationMap(response);

    final conversation = ChatConversation.fromJson(conversationData);

    if (conversation.id <= 0) {
      throw const ApiException(
        message: 'تعذر قراءة بيانات المحادثة من الخادم.',
      );
    }

    return conversation;
  }

  Future<ChatConversation> sendMessage({
    int? conversationId,
    required String message,
  }) async {
    final normalizedMessage = message.trim();

    if (normalizedMessage.isEmpty) {
      throw const ApiException(message: 'اكتبي رسالتك أولًا.', statusCode: 422);
    }

    final requestData = <String, dynamic>{'message': normalizedMessage};

    if (conversationId != null) {
      requestData['conversation_id'] = conversationId;
    }

    final response = await _apiClient.post(
      '$_basePath/messages',
      data: requestData,
    );

    final resolvedConversationId = _extractConversationId(
      response,
      fallback: conversationId,
    );

    if (resolvedConversationId == null || resolvedConversationId <= 0) {
      throw const ApiException(
        message: 'تم إرسال الرسالة، لكن تعذر تحديد المحادثة.',
      );
    }

    return getConversation(resolvedConversationId);
  }

  List<dynamic> _extractList(
    Map<String, dynamic> response, {
    required List<String> possibleKeys,
  }) {
    final data = response['data'];

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final normalizedData = Map<String, dynamic>.from(data);

      for (final key in possibleKeys) {
        final value = normalizedData[key];

        if (value is List) {
          return value;
        }

        if (value is Map && value['data'] is List) {
          return value['data'] as List;
        }
      }
    }

    for (final key in possibleKeys) {
      final value = response[key];

      if (value is List) {
        return value;
      }

      if (value is Map && value['data'] is List) {
        return value['data'] as List;
      }
    }

    return const <dynamic>[];
  }

  Map<String, dynamic> _extractConversationMap(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map) {
      final normalizedData = Map<String, dynamic>.from(data);

      final conversation = normalizedData['conversation'];

      if (conversation is Map) {
        return Map<String, dynamic>.from(conversation);
      }

      if (normalizedData['id'] != null) {
        return normalizedData;
      }
    }

    final conversation = response['conversation'];

    if (conversation is Map) {
      return Map<String, dynamic>.from(conversation);
    }

    if (response['id'] != null) {
      return response;
    }

    throw const ApiException(
      message: 'استجابة المحادثة القادمة من الخادم غير صالحة.',
    );
  }

  int? _extractConversationId(Map<String, dynamic> response, {int? fallback}) {
    final data = response['data'];

    if (data is Map) {
      final normalizedData = Map<String, dynamic>.from(data);

      final conversation = normalizedData['conversation'];

      if (conversation is Map) {
        final id = _readInt(conversation['id']);

        if (id != null) {
          return id;
        }
      }

      final directId = _readInt(normalizedData['conversation_id']);

      if (directId != null) {
        return directId;
      }

      final dataId = _readInt(normalizedData['id']);

      if (dataId != null) {
        return dataId;
      }
    }

    final responseConversation = response['conversation'];

    if (responseConversation is Map) {
      final id = _readInt(responseConversation['id']);

      if (id != null) {
        return id;
      }
    }

    return _readInt(response['conversation_id']) ?? fallback;
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }
}
