import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/constants/app_theme.dart';
import 'package:sync_event/core/util/responsive_util.dart';
import 'package:sync_event/features/chat/domain/entities/chat_user_entity.dart';
import 'package:sync_event/features/chat/presentation/providers/chat_providers.dart';
import 'package:sync_event/features/chat/presentation/widgets/user_search_tile.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<ChatUserEntity> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await ref.read(searchUsersUseCaseProvider).call(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching users: $e')));
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _startChat(String userId) async {
    try {
      final chatId = await ref
          .read(createOrGetChatUseCaseProvider)
          .call(userId);
      if (mounted) {
        context.push('/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        leading:  IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getTextPrimary(isDark),
            size: ResponsiveUtil.getIconSize(context, baseSize: 20),
          ),
          onPressed: () => context.pop(),
        ),
        foregroundColor: AppColors.getPrimary(isDark),
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        title: Container(
          height: AppSizes.inputHeight,
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: BorderRadius.circular(AppSizes.radiusSemiRound),
            boxShadow: [
              BoxShadow(
                color: AppColors.getShadow(isDark).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: AppTextStyles.bodyMedium(
              isDark: isDark,
            ).copyWith(fontWeight: FontWeight.normal),
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: AppTextStyles.bodyMedium(
                isDark: isDark,
              ).copyWith(color: AppColors.getTextSecondary(isDark)),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.getTextSecondary(isDark),
                size: AppSizes.iconMedium,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.getTextSecondary(isDark),
                        size: AppSizes.iconMedium,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSemiRound),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSemiRound),
                borderSide: BorderSide(
                  color: AppColors.getBorder(isDark),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSemiRound),
                borderSide: BorderSide(
                  color: AppColors.getPrimary(isDark),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSizes.inputPaddingHorizontal,
                vertical: AppSizes.inputPaddingVertical,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? Center(
                key: const ValueKey('loading'),
                child: CircularProgressIndicator(
                  color: AppColors.getPrimary(isDark),
                  strokeWidth: AppSizes.borderWidthMedium,
                ),
              )
            : _searchResults.isEmpty
            ? _EmptyState(
                key: const ValueKey('empty'),
                isDark: isDark,
                isSearching: _searchController.text.isNotEmpty,
                fadeAnimation: _fadeAnimation,
              )
            : ListView.builder(
                key: const ValueKey('results'),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                  vertical: AppSizes.spacingMedium,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: UserSearchTile(
                            user: _searchResults[index],
                            onTap: () => _startChat(_searchResults[index].uid),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool isSearching;
  final Animation<double> fadeAnimation;

  const _EmptyState({
    super.key,
    required this.isDark,
    required this.isSearching,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.5, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.search,
                    size: AppSizes.imageMedium,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                );
              },
            ),
            SizedBox(height: AppSizes.spacingXxl),
            Text(
              isSearching ? 'No users found' : 'Search for users',
              style: AppTextStyles.titleMedium(
                isDark: isDark,
              ).copyWith(color: AppColors.getTextSecondary(isDark)),
            ),
            if (!isSearching) ...[
              SizedBox(height: AppSizes.spacingMedium),
              Text(
                'Start typing to find friends',
                style: AppTextStyles.bodySmall(isDark: isDark),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
