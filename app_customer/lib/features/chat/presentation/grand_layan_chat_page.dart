import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_notifier.dart';
import '../data/models/chat_message.dart';
import '../providers/chat_provider.dart';

class GrandLayanChatPage extends ConsumerStatefulWidget {
  const GrandLayanChatPage({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  ConsumerState<GrandLayanChatPage> createState() {
    return _GrandLayanChatPageState();
  }
}

class _GrandLayanChatPageState extends ConsumerState<GrandLayanChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final FocusNode _messageFocusNode = FocusNode();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _sendSuggestedMessage(String message) async {
    if (ref.read(chatProvider).isSending) {
      return;
    }

    FocusScope.of(context).unfocus();

    final sent = await ref.read(chatProvider.notifier).sendMessage(message);

    if (!mounted) {
      return;
    }

    if (!sent) {
      _showError(ref.read(chatProvider).errorMessage ?? 'تعذر إرسال الرسالة.');

      return;
    }

    _scrollToBottom();
  }

  Future<void> _initializeChat() async {
    if (_initialized || !mounted) {
      return;
    }

    _initialized = true;

    final notifier = ref.read(chatProvider.notifier);

    await notifier.loadConversations();

    if (!mounted) {
      return;
    }

    final conversations = ref.read(chatProvider).conversations;

    if (conversations.isNotEmpty) {
      await notifier.openConversation(conversations.first.id);
    }

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      _messageFocusNode.requestFocus();
      return;
    }

    final notifier = ref.read(chatProvider.notifier);

    _messageController.clear();

    final sent = await notifier.sendMessage(message);

    if (!mounted) {
      return;
    }

    if (!sent) {
      _messageController.text = message;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );

      _showError(ref.read(chatProvider).errorMessage ?? 'تعذر إرسال الرسالة.');

      return;
    }

    _scrollToBottom();

    _messageFocusNode.requestFocus();
  }

  Future<void> _startNewConversation() async {
    FocusScope.of(context).unfocus();

    ref.read(chatProvider.notifier).startNewConversation();

    _messageController.clear();

    if (!mounted) {
      return;
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final backgroundColor = isDark
        ? const Color(0xFF090909)
        : const Color(0xFFF8F7F5);

    final surfaceColor = isDark
        ? const Color(0xFF151515)
        : const Color(0xFFFFFFFF);

    final primaryTextColor = isDark
        ? const Color(0xFFF3F3F3)
        : const Color(0xFF1D1D1D);

    final secondaryTextColor = isDark
        ? const Color(0xFFA8A8A8)
        : const Color(0xFF727272);

    final messages =
        chatState.activeConversation?.messages ?? const <ChatMessage>[];

    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous?.activeConversation?.messages.length !=
          next.activeConversation?.messages.length) {
        _scrollToBottom();
      }

      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        _showError(next.errorMessage!);

        ref.read(chatProvider.notifier).clearError();
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: surfaceColor,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          title: _ChatTopBar(
            showBackButton: widget.showBackButton,
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onBackPressed: () {
              Navigator.of(context).pop();
            },
            onNewConversationPressed: chatState.isSending
                ? null
                : _startNewConversation,
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: backgroundColor)),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ChatBackgroundPainter(isDark: isDark),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: _buildConversationBody(
                      messages: messages,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      chatState: chatState,
                    ),
                  ),
                  _MessageComposer(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    isDark: isDark,
                    isSending: chatState.isSending,
                    surfaceColor: surfaceColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    onSendPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationBody({
    required List<ChatMessage> messages,
    required bool isDark,
    required Color surfaceColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required ChatState chatState,
  }) {
    if (chatState.isLoading && chatState.activeConversation == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
          strokeWidth: 2.2,
        ),
      );
    }

    if (messages.isEmpty) {
      return _EmptyChatView(
        isDark: isDark,
        surfaceColor: surfaceColor,
        primaryTextColor: primaryTextColor,
        secondaryTextColor: secondaryTextColor,
        isSending: chatState.isSending,
        onSuggestionPressed: _sendSuggestedMessage,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 22),
      itemCount: messages.length + (chatState.isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _AssistantTypingBubble(
            isDark: isDark,
            surfaceColor: surfaceColor,
            secondaryTextColor: secondaryTextColor,
          );
        }

        final message = messages[index];

        return _MessageBubble(
          message: message,
          isDark: isDark,
          surfaceColor: surfaceColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        );
      },
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.showBackButton,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onBackPressed,
    required this.onNewConversationPressed,
  });

  final bool showBackButton;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onBackPressed;
  final VoidCallback? onNewConversationPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Row(
          children: [
            if (showBackButton)
              IconButton(
                tooltip: 'رجوع',
                onPressed: onBackPressed,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: primaryTextColor,
                  size: 20,
                ),
              )
            else
              const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: isDark ? 0.17 : 0.11),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.30),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.gold,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اسأل كراند ليان',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF49A769),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'مساعدك لخدمات كراند ليان',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 10.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'محادثة جديدة',
              onPressed: onNewConversationPressed,
              icon: Icon(
                Icons.add_comment_outlined,
                color: onNewConversationPressed == null
                    ? secondaryTextColor.withValues(alpha: 0.45)
                    : AppColors.gold,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView({
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.isSending,
    required this.onSuggestionPressed,
  });

  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isSending;
  final ValueChanged<String> onSuggestionPressed;

  static const List<String> _suggestions = [
    'ما هي خدمات الصالون؟',
    'أريد معرفة أسعار الخدمات',
    'كيف أحجز موعدًا؟',
    'هل توجد عروض حاليًا؟',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 25),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: isDark ? 0.15 : 0.10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: isDark ? 0.10 : 0.14),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 39,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'أهلًا بكِ في مساعد كراند ليان',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'اسأليني عن خدمات الصالون والعيادة، الأسعار، الحجز، العروض وسياسات المركز.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 27),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'أسئلة مقترحة',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 11),
          ..._suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSending
                      ? null
                      : () {
                          onSuggestionPressed(suggestion);
                        },
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.gold.withValues(
                          alpha: isDark ? 0.25 : 0.18,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.north_west_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final ChatMessage message;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.isCustomer;

    final bubbleColor = isCustomer ? AppColors.gold : surfaceColor;

    final textColor = isCustomer ? const Color(0xFF171717) : primaryTextColor;

    final alignment = isCustomer ? Alignment.centerLeft : Alignment.centerRight;

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(21),
      topRight: const Radius.circular(21),
      bottomLeft: Radius.circular(isCustomer ? 5 : 21),
      bottomRight: Radius.circular(isCustomer ? 21 : 5),
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.80,
        ),
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: bubbleRadius,
          border: isCustomer
              ? null
              : Border.all(
                  color: AppColors.gold.withValues(alpha: isDark ? 0.23 : 0.15),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCustomer) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.gold,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'كراند ليان',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
            ],
            SelectableText(
              message.content,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: 14.2,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (message.createdAt != null) ...[
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatTime(message.createdAt!),
                  style: TextStyle(
                    color: isCustomer
                        ? const Color(0xFF171717).withValues(alpha: 0.62)
                        : secondaryTextColor,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();

    final hour = localTime.hour.toString().padLeft(2, '0');

    final minute = localTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _AssistantTypingBubble extends StatelessWidget {
  const _AssistantTypingBubble({
    required this.isDark,
    required this.surfaceColor,
    required this.secondaryTextColor,
  });

  final bool isDark;
  final Color surfaceColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(21),
            topRight: Radius.circular(21),
            bottomLeft: Radius.circular(21),
            bottomRight: Radius.circular(5),
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: isDark ? 0.23 : 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'كراند ليان يكتب...',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.isSending,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onSendPressed,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final bool isSending;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isSending,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 14,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتبي سؤالك عن كراند ليان...',
                  hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF202020)
                      : const Color(0xFFF5F4F2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: AppColors.gold.withValues(
                        alpha: isDark ? 0.20 : 0.14,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSending ? null : onSendPressed,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 49,
                  height: 49,
                  decoration: BoxDecoration(
                    color: isSending
                        ? AppColors.gold.withValues(alpha: 0.55)
                        : AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.22),
                        blurRadius: 13,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isSending
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF171717),
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: Color(0xFF171717),
                            size: 23,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBackgroundPainter extends CustomPainter {
  const _ChatBackgroundPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: isDark ? 0.035 : 0.022)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (var index = 0; index < 3; index++) {
      final path = Path()
        ..moveTo(size.width * 0.58, -15 + index * 11)
        ..cubicTo(
          size.width * 0.80,
          size.height * 0.04,
          size.width * 0.92,
          size.height * 0.10,
          size.width + 20,
          size.height * 0.18 + index * 8,
        );

      canvas.drawPath(path, paint);
    }

    for (var index = 0; index < 2; index++) {
      final path = Path()
        ..moveTo(-20, size.height * (0.72 + index * 0.04))
        ..cubicTo(
          size.width * 0.20,
          size.height * 0.65,
          size.width * 0.43,
          size.height * 0.90,
          size.width * 0.68,
          size.height + 20,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
