import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/customer_auth_provider.dart';
import '../data/models/chat_conversation.dart';
import '../data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(apiClient: ref.watch(apiClientProvider));
});

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

class ChatState {
  const ChatState({
    this.conversations = const [],
    this.activeConversation,
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
  });

  final List<ChatConversation> conversations;
  final ChatConversation? activeConversation;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  ChatState copyWith({
    List<ChatConversation>? conversations,
    ChatConversation? activeConversation,
    bool keepActiveConversation = true,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      activeConversation: keepActiveConversation
          ? activeConversation ?? this.activeConversation
          : activeConversation,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  ChatRepository get _repository {
    return ref.read(chatRepositoryProvider);
  }

  @override
  ChatState build() {
    return const ChatState();
  }

  Future<void> loadConversations() async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final conversations = await _repository.getConversations();

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readErrorMessage(error),
      );
    }
  }

  Future<void> openConversation(int conversationId) async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final conversation = await _repository.getConversation(conversationId);

      state = state.copyWith(
        activeConversation: conversation,
        conversations: _replaceConversation(state.conversations, conversation),
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readErrorMessage(error),
      );
    }
  }

  Future<bool> sendMessage(String message) async {
    final normalizedMessage = message.trim();

    if (normalizedMessage.isEmpty || state.isSending) {
      return false;
    }

    state = state.copyWith(isSending: true, clearError: true);

    try {
      final conversation = await _repository.sendMessage(
        conversationId: state.activeConversation?.id,
        message: normalizedMessage,
      );

      state = state.copyWith(
        activeConversation: conversation,
        conversations: _replaceConversation(state.conversations, conversation),
        isSending: false,
        clearError: true,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: _readErrorMessage(error),
      );

      return false;
    }
  }

  void startNewConversation() {
    state = state.copyWith(
      activeConversation: null,
      keepActiveConversation: false,
      clearError: true,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  List<ChatConversation> _replaceConversation(
    List<ChatConversation> current,
    ChatConversation conversation,
  ) {
    final updated = current
        .where((item) => item.id != conversation.id)
        .toList();

    updated.insert(0, conversation);

    return List<ChatConversation>.unmodifiable(updated);
  }

  String _readErrorMessage(Object error) {
    try {
      final dynamic dynamicError = error;
      final dynamic message = dynamicError.message;

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    } catch (_) {
      // نستخدم الرسالة العامة أدناه.
    }

    return 'حدث خطأ أثناء الاتصال بمساعد كراند ليان.';
  }
}
