import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flow_drawer/flow_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_theme.dart';
import 'package:sync_event/core/util/responsive_util.dart';
import 'package:sync_event/features/events/presentation/providers/event_providers.dart';
import 'package:sync_event/features/home/presentation/widgets/event_section.dart';
import 'package:sync_event/features/home/presentation/widgets/header_section.dart';
import 'package:sync_event/features/home/presentation/widgets/invite_banner.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sync_event/core/di/injection_container.dart';
import 'package:sync_event/features/auth/domain/repo/auth_repo.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';

// Selected Category Provider
final selectedCategoryProvider = StateProvider<int>((ref) => 0);

// UserModel
class UserModel {
  final String? name;
  final String? image;
  final String? uid;

  UserModel({this.name, this.image, this.uid});

  factory UserModel.fromFirebaseUser(firebase_auth.User? user) {
    return UserModel(
      name: user?.displayName,
      image: user?.photoURL,
      uid: user?.uid,
    );
  }
}

// Auth State Provider
final authStateProvider = StreamProvider<UserModel?>((ref) {
  sl<AuthRepository>();
  return firebase_auth.FirebaseAuth.instance.userChanges().map((user) {
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  });
});

// Home Screen Widget
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late FlowDrawerController controller;

  @override
  void initState() {
    super.initState();
    controller = FlowDrawerController();
  }

  Future<void> _handleRefresh(BuildContext context) async {
    ref.invalidate(approvedEventsStreamProvider);
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Events refreshed'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          margin: AppSizes.getResponsivePadding(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSizes.getBorderRadius(context, baseRadius: 8),
            ),
          ),
        ),
      );
    }
  }

  List<Widget> _buildDrawerItems(BuildContext context, bool isDark) {
    return [
      // Custom Drawer Content
      SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
            vertical: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- User Info ---
              _buildUserSection(context, isDark),
              SizedBox(height: 15),

              // --- Drawer Items ---
              _buildItem(
                context,
                isDark,
                Icons.person_outline_rounded,
                'My Profile',
                '/profile',
              ),
              _buildItem(
                context,
                isDark,
                Icons.calendar_today_outlined,
                'Calendar',
                '/calendar',
              ),
              _buildItem(
                context,
                isDark,
                Icons.chat_bubble_outline_rounded,
                'Messages',
                '/chat',
              ),
              _buildItem(
                context,
                isDark,
                Icons.favorite_border_rounded,
                'Favorites',
                '/favorites',
              ),
              _buildItem(
                context,
                isDark,
                Icons.confirmation_number_outlined,
                'My Bookings',
                '/mybookings',
              ),
              _buildItem(
                context,
                isDark,
                Icons.event_note_outlined,
                'My Events',
                '/my-events',
              ),
              _buildItem(context, isDark, Icons.wallet, 'My Wallet', '/wallet'),
              _buildItem(
                context,
                isDark,
                Icons.settings_outlined,
                'Settings',
                '/settings',
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildUserSection(BuildContext context, bool isDark) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) => Row(
        children: [
          GestureDetector(
            onTap: () {
              controller.close();
              context.push('/profile');
            },
            child: Hero(
              tag: "profile",
              child: CircleAvatar(
                radius: AppSizes.avatarMedium,
                backgroundColor: AppColors.getSurface(isDark),
                backgroundImage: user?.image != null
                    ? NetworkImage(user!.image!)
                    : const AssetImage('assets/avatar_placeholder.png')
                          as ImageProvider,
              ),
            ),
          ),
          SizedBox(width: AppSizes.spacingMedium),
          Expanded(
            child: Text(
              user?.name ?? user?.uid?.split('@').first ?? 'User',
              style: AppTextStyles.titleLarge(isDark: isDark).copyWith(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          CircleAvatar(
            radius: AppSizes.avatarMedium,
            backgroundColor: AppColors.getDisabled(isDark),
          ),
          SizedBox(width: AppSizes.spacingMedium),
          Expanded(
            child: Container(
              height: AppSizes.fontXl,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.getDisabled(isDark),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
            ),
          ),
        ],
      ),
      error: (error, stack) => Row(
        children: [
          CircleAvatar(
            radius: AppSizes.avatarMedium,
            backgroundColor: AppColors.getDisabled(isDark),
            child: Icon(
              Icons.error_outline_rounded,
              size: AppSizes.iconSmall,
              color: AppColors.getError(isDark),
            ),
          ),
          SizedBox(width: AppSizes.spacingMedium),
          Expanded(
            child: Text(
              'Error loading user',
              style: AppTextStyles.titleLarge(isDark: isDark).copyWith(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    bool isDark,
    IconData icon,
    String label,
    String route,
  ) {
    return Padding(
      padding: EdgeInsets.zero,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.white, size: AppSizes.iconMedium),
        title: Text(
          label,
          style: AppTextStyles.bodyLarge(
            isDark: isDark,
          ).copyWith(fontSize: AppSizes.fontMedium, color: Colors.white),
        ),
        onTap: () {
          controller.close();
          context.push(route);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    ref.watch(selectedCategoryProvider);

    return FlowDrawer(
      controller: controller,
      drawerItems: _buildDrawerItems(context, isDark),
      drawerGradient: RadialGradient(
        colors: [AppColors.primaryLight, AppColors.primary],
      ),
      child: Scaffold(
        backgroundColor: AppColors.getBackground(isDark),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: () => _handleRefresh(context),
              color: AppColors.getPrimary(isDark),
              backgroundColor: AppColors.getCard(isDark),
              child: Column(
                children: [
                  HeaderSection(controller: controller),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight -
                              AppSizes.getAppBarHeight(context) -
                              MediaQuery.of(context).padding.top,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const EventSection(),
                              SizedBox(
                                height: AppSizes.getHeightSpacing(
                                  context,
                                  baseSpacing: 20,
                                ),
                              ),
                              const InviteBanner(),
                              SizedBox(
                                height: AppSizes.getHeightSpacing(
                                  context,
                                  baseSpacing: 20,
                                ),
                              ),
                              SizedBox(
                                height:
                                    ResponsiveUtil.getBottomPadding(context) +
                                    AppSizes.getHeightSpacing(
                                      context,
                                      baseSpacing: 16,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
