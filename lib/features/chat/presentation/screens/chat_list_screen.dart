import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/constants/app_theme.dart';
import 'package:sync_event/core/util/responsive_util.dart';
import 'package:sync_event/features/chat/presentation/providers/chat_providers.dart';
import 'package:sync_event/features/chat/presentation/widgets/chat_list_tile.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final chatsAsync = ref.watch(userChatsStreamProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getTextPrimary(isDark),
            size: ResponsiveUtil.getIconSize(context, baseSize: 20),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Messages',
          style: AppTextStyles.titleLarge(isDark: isDark).copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        backgroundColor: AppColors.getCard(isDark),
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
            ),
            child: IconButton(
              icon: Icon(
                Icons.search,
                color: AppColors.getTextPrimary(isDark),
                size: ResponsiveUtil.getIconSize(context, baseSize: 24),
              ),
              onPressed: () {
                context.push('/chat/search');
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: chatsAsync.when(
          data: (chats) {
            if (chats.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(
                    ResponsiveUtil.getSpacing(context, baseSpacing: 24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          ResponsiveUtil.getSpacing(context, baseSpacing: 32),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(isDark),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: ResponsiveUtil.getIconSize(
                            context,
                            baseSize: 64,
                          ),
                          color: AppColors.getTextSecondary(isDark),
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveUtil.getSpacing(
                          context,
                          baseSpacing: 24,
                        ),
                      ),
                      Text(
                        'No messages yet',
                        style: AppTextStyles.headingSmall(isDark: isDark)
                            .copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                      ),
                      SizedBox(
                        height: ResponsiveUtil.getSpacing(
                          context,
                          baseSpacing: 8,
                        ),
                      ),
                      Text(
                        'Start a conversation to see your messages here',
                        style: AppTextStyles.bodyMedium(isDark: isDark)
                            .copyWith(
                              color: AppColors.getTextSecondary(isDark),
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: ResponsiveUtil.getSpacing(
                          context,
                          baseSpacing: 32,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.getButtonHeight(context),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Trigger new chat or navigate to start conversation
                            // Existing logic can be hooked here if needed
                          },
                          icon: Icon(Icons.add_comment_outlined, size: 20),
                          label: Text(
                            'Start a Chat',
                            style: AppTextStyles.button(
                              isDark: isDark,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.getPrimary(isDark),
                            side: BorderSide(
                              color: AppColors.getPrimary(isDark),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtil.getBorderRadius(
                                  context,
                                  baseRadius: 12,
                                ),
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

            return ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
                vertical: ResponsiveUtil.getSpacing(context, baseSpacing: 8),
              ),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return Card(
                  elevation: ResponsiveUtil.getElevation(
                    context,
                    baseElevation: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtil.getBorderRadius(context, baseRadius: 16),
                    ),
                  ),
                  margin: EdgeInsets.only(
                    bottom: ResponsiveUtil.getSpacing(context, baseSpacing: 12),
                  ),
                  color: AppColors.getCard(isDark),
                  child: ChatListTile(
                    chat: chat,
                    currentUserId: currentUserId,
                    isDark: isDark,
                  ),
                );
              },
            );
          },
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveUtil.getSpacing(context, baseSpacing: 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.getPrimary(isDark),
                    strokeWidth: 3,
                  ),
                  SizedBox(
                    height: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
                  ),
                  Text(
                    'Loading messages...',
                    style: AppTextStyles.bodyMedium(
                      isDark: isDark,
                    ).copyWith(color: AppColors.getTextSecondary(isDark)),
                  ),
                ],
              ),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveUtil.getSpacing(context, baseSpacing: 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ResponsiveUtil.getIconSize(context, baseSize: 64),
                    color: AppColors.getError(isDark),
                  ),
                  SizedBox(
                    height: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
                  ),
                  Text(
                    'Something went wrong',
                    style: AppTextStyles.headingSmall(isDark: isDark).copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtil.getSpacing(context, baseSpacing: 8),
                  ),
                  Text(
                    'Failed to load messages. Please try again.',
                    style: AppTextStyles.bodyMedium(
                      isDark: isDark,
                    ).copyWith(color: AppColors.getTextSecondary(isDark)),
                    textAlign: TextAlign.center,
                  ),
                  Builder(
                    builder: (_) {
                      debugPrint(
                        'Error occurred in userChatsStreamProvider: $error',
                      );
                      return const SizedBox.shrink(); // returns empty widget
                    },
                  ),
                  SizedBox(
                    height: ResponsiveUtil.getSpacing(context, baseSpacing: 24),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.getButtonHeight(context),
                    child: ElevatedButton.icon(
                      onPressed: () => ref.invalidate(userChatsStreamProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'Retry',
                        style: AppTextStyles.button(isDark: isDark).copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(isDark),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtil.getBorderRadius(
                              context,
                              baseRadius: 12,
                            ),
                          ),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
