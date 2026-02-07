import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/constants/app_theme.dart';
import 'package:sync_event/features/chat/presentation/providers/chat_providers.dart';
import 'package:sync_event/features/profile/presentation/providers/other_users_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(markMessagesAsReadUseCaseProvider).call(widget.chatId);
    });
    _messageController.addListener(_handleTyping);
  }

  void _handleTyping() {
    final isTyping =
        _messageController.text.isNotEmpty &&
        _messageController.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      _isTyping = isTyping;
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'typing.${ref.read(currentUserIdProvider)}': isTyping,
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref
          .read(sendMessageUseCaseProvider)
          .call(chatId: widget.chatId, text: text);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final chatsAsync = ref.watch(userChatsStreamProvider);
    final otherUserId = chatsAsync.when<String?>(
      data: (chats) {
        try {
          final chat = chats.firstWhere((c) => c.id == widget.chatId);
          return chat.participants.firstWhere((id) => id != currentUserId);
        } catch (e) {
          return null;
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
    final otherUserAsync = otherUserId != null && otherUserId.isNotEmpty
        ? ref.watch(userByIdProvider(otherUserId))
        : const AsyncValue.data(null);

    final typingProvider = StreamProvider.family<bool, (String, String)>((
      ref,
      params,
    ) {
      final (chatId, userId) = params;
      return FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots()
          .map((doc) {
            final data = doc.data();
            return data?['typing']?[userId] ?? false;
          });
    });
    final typingValue = otherUserId != null
        ? ref.watch(typingProvider((widget.chatId, otherUserId)))
        : const AsyncValue.data(false);

    return SafeArea(
      bottom: true,
      child: Scaffold(
        backgroundColor: AppColors.getBackground(isDark),
        appBar: AppBar(
          leadingWidth: AppSizes.paddingMedium * 2,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.getTextPrimary(isDark),
              size: AppSizes.iconMedium,
            ),
           onPressed: () {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/'); // or your home route
  }
},


          ),
          title: otherUserAsync.when(
            data: (otherUser) => Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.avatarMedium / 2,
                  backgroundImage: otherUser?.image != null
                      ? NetworkImage(otherUser!.image!)
                      : null,
                  backgroundColor: AppColors.grey300,
                  child: otherUser?.image == null
                      ? Icon(
                          Icons.person,
                          color: AppColors.grey600,
                          size: AppSizes.iconSmall,
                        )
                      : null,
                ),
                SizedBox(width: AppSizes.spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        otherUser?.name ?? 'Unknown User',
                        style: AppTextStyles.titleMedium(
                          isDark: isDark,
                        ).copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Builder(
                        builder: (context) {
                          final isTyping = typingValue.when(
                            data: (value) => value,
                            loading: () => false,
                            error: (_, __) => false,
                          );
                          return Text(
                            isTyping ? 'Typing...' : 'Active now',
                            style: TextStyle(
                              color: isTyping
                                  ? const Color(0xFF0095F6)
                                  : AppColors.getTextSecondary(isDark),
                              fontSize: AppSizes.fontSmall,
                              fontWeight: FontWeight.w400,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.avatarMedium / 2,
                  backgroundColor: AppColors.grey300,
                ),
                SizedBox(width: AppSizes.spacingSmall),
                Container(
                  width: 100,
                  height: AppSizes.fontMedium * 1.5,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                ),
              ],
            ),
            error: (_, __) => Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.avatarMedium / 2,
                  backgroundColor: AppColors.grey300,
                  child: Icon(Icons.person, size: AppSizes.iconSmall),
                ),
                SizedBox(width: AppSizes.spacingSmall),
                Text(
                  'Chat',
                  style: AppTextStyles.titleMedium(
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: AppColors.getTextPrimary(isDark),
                size: AppSizes.iconMedium,
              ),
              onPressed: () {},
            ),
          ],
          backgroundColor: AppColors.getBackground(isDark),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.getBorder(isDark), height: 0.5),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  final currentCount = messages.length;
                  if (currentCount > _previousMessageCount) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        if (_scrollController.position.pixels < 100) {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      }
                    });
                  }
                  _previousMessageCount = currentCount;

                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.paddingXxl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: AppSizes.imageLarge,
                              color: AppColors.getTextSecondary(isDark),
                            ),
                            SizedBox(height: AppSizes.spacingLarge),
                            Text(
                              'No messages yet',
                              style: AppTextStyles.titleLarge(
                                isDark: isDark,
                              ).copyWith(fontSize: AppSizes.fontXxxl),
                            ),
                            SizedBox(height: AppSizes.spacingXs),
                            Text(
                              'Start a conversation',
                              style: AppTextStyles.bodySmall(isDark: isDark),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium,
                      vertical: AppSizes.spacingSmall,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      final showDate =
                          index == messages.length - 1 ||
                          !_isSameDay(
                            message.timestamp,
                            messages[index + 1].timestamp,
                          );

                      // Check if we should show avatar (last in consecutive group)
                      final showAvatar =
                          index == 0 ||
                          messages[index - 1].senderId != message.senderId ||
                          !_isWithinTimeWindow(
                            messages[index - 1].timestamp,
                            message.timestamp,
                          );

                      return Column(
                        children: [
                          if (showDate)
                            _buildDateDivider(message.timestamp, isDark),
                          _buildMessageBubble(
                            message,
                            isMe,
                            isDark,
                            showAvatar,
                            otherUserAsync,
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.borderWidthThin,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.paddingXxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: AppSizes.imageLarge,
                          color: AppColors.getError(isDark),
                        ),
                        SizedBox(height: AppSizes.spacingLarge),
                        Text(
                          'Something went wrong',
                          style: AppTextStyles.titleLarge(isDark: isDark),
                        ),
                        SizedBox(height: AppSizes.spacingXs),
                        Text(
                          'Failed to load messages',
                          style: AppTextStyles.bodyMedium(isDark: isDark),
                        ),
                        SizedBox(height: AppSizes.paddingXxl),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            chatMessagesStreamProvider(widget.chatId),
                          ),
                          child: Text(
                            'Retry',
                            style: AppTextStyles.titleSmall(
                              isDark: isDark,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingMedium,
              ),
              decoration: BoxDecoration(
                color: AppColors.getBackground(isDark),
                border: Border(
                  top: BorderSide(
                    color: AppColors.getBorder(isDark),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: AppTextStyles.caption(isDark: isDark),
                          filled: true,
                          fillColor: AppColors.getSurface(isDark),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSizes.inputPaddingHorizontal,
                            vertical: AppSizes.paddingMedium,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound,
                            ),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.getBorder(isDark),
                              width: AppSizes.inputBorderWidth,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound,
                            ),
                            borderSide: BorderSide(
                              color: const Color(0xFF0095F6),
                              width: AppSizes.inputBorderWidthFocused,
                            ),
                          ),
                        ),
                        style: AppTextStyles.bodyMedium(
                          isDark: isDark,
                        ).copyWith(fontWeight: FontWeight.normal),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.spacingSmall),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: _messageController.text.trim().isNotEmpty
                            ? const Color(0xFF0095F6)
                            : AppColors.getSurface(isDark),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: _messageController.text.trim().isNotEmpty
                            ? Colors.white
                            : AppColors.getTextSecondary(isDark),
                        size: AppSizes.iconSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isWithinTimeWindow(DateTime time1, DateTime time2) {
    // Messages within 2 minutes are considered consecutive
    return time2.difference(time1).inMinutes < 2;
  }

  Widget _buildMessageBubble(
    dynamic message,
    bool isMe,
    bool isDark,
    bool showAvatar,
    AsyncValue otherUserAsync,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: showAvatar ? AppSizes.paddingMedium : 2,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              width: AppSizes.iconSmall * 1.4,
              margin: EdgeInsets.only(right: AppSizes.spacingSmall, bottom: 2),
              child: showAvatar
                  ? otherUserAsync.when(
                      data: (otherUser) => CircleAvatar(
                        radius: AppSizes.avatarSmall / 2,
                        backgroundImage: otherUser?.image != null
                            ? NetworkImage(otherUser!.image!)
                            : null,
                        backgroundColor: AppColors.grey300,
                        child: otherUser?.image == null
                            ? Icon(
                                Icons.person,
                                color: AppColors.grey600,
                                size: AppSizes.iconXs,
                              )
                            : null,
                      ),
                      loading: () => CircleAvatar(
                        radius: AppSizes.avatarSmall / 2,
                        backgroundColor: AppColors.grey300,
                      ),
                      error: (_, __) => CircleAvatar(
                        radius: AppSizes.avatarSmall / 2,
                        backgroundColor: AppColors.grey300,
                        child: Icon(Icons.person, size: AppSizes.iconXs),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: AppSizes.paddingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.getPrimary(isDark)
                        : AppColors.getSurface(isDark),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : AppColors.getTextPrimary(isDark),
                      fontSize: AppSizes.fontMedium,
                      height: 1.3,
                    ),
                  ),
                ),
                if (showAvatar)
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppSizes.spacingXs,
                      left: AppSizes.spacingXs,
                      right: AppSizes.spacingXs,
                    ),
                    child: Text(
                      DateFormat('h:mm a').format(message.timestamp),
                      style: AppTextStyles.caption(
                        isDark: isDark,
                      ).copyWith(fontSize: AppSizes.fontXs),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) SizedBox(width: AppSizes.spacingSmall),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSizes.spacingLarge),
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingXs * 1.5,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Text(
        _formatDate(date),
        style: AppTextStyles.labelMedium(
          isDark: isDark,
        ).copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }
}
