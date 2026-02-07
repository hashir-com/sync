import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/auth/presentation/providers/auth_notifier.dart';

// Assuming authStateProvider is defined as in the previous response
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sync_event/core/di/injection_container.dart';
import 'package:sync_event/features/auth/domain/repo/auth_repo.dart';

// Define UserModel
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

// Ensure authStateProvider is accessible
final authStateProvider = StreamProvider<UserModel?>((ref) {
  sl<AuthRepository>();
  return firebase_auth.FirebaseAuth.instance.userChanges().map((user) {
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  });
});

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeUtils.isDark(context);
    ref.read(authNotifierProvider.notifier);
    final userAsync = ref.watch(authStateProvider);

    return Drawer(
      elevation: AppSizes.cardElevationHigh,
      shadowColor: AppColors.getShadow(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppSizes.radiusXxl),
          bottomRight: Radius.circular(AppSizes.radiusXxl),
        ),
      ),
      backgroundColor: AppColors.getCard(isDark),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
            vertical: AppSizes.paddingXl,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- User Info ---
                        userAsync.when(
                          data: (user) => Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/profile'),
                                child: Hero(
                                  tag: "profile",
                                  child: CircleAvatar(
                                    radius: AppSizes.avatarMedium,
                                    backgroundColor: AppColors.getSurface(
                                      isDark,
                                    ),
                                    backgroundImage: user?.image != null
                                        ? NetworkImage(user!.image!)
                                        : const AssetImage(
                                                'assets/avatar_placeholder.png',
                                              )
                                              as ImageProvider,
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSizes.spacingMedium),
                              Expanded(
                                child: Text(
                                  user?.name ??
                                      user?.uid?.split('@').first ??
                                      'User',
                                  style:
                                      AppTextStyles.titleLarge(
                                        isDark: isDark,
                                      ).copyWith(
                                        fontSize: AppSizes.fontXl,
                                        fontWeight: FontWeight.w600,
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
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSmall,
                                    ),
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
                                  style:
                                      AppTextStyles.titleLarge(
                                        isDark: isDark,
                                      ).copyWith(
                                        fontSize: AppSizes.fontXl,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getError(isDark),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSizes.spacingXxxl),

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
                        _buildItem(
                          context,
                          isDark,
                          Icons.wallet,
                          'My Wallet',
                          '/wallet',
                        ),

                        Expanded(
                          child: _buildItem(
                            context,
                            isDark,
                            Icons.settings_outlined,
                            'Settings',
                            '/settings',
                          ),
                        ),
                        // ListTile(
                        //   contentPadding: EdgeInsets.zero,
                        //   leading: Icon(
                        //     Icons.logout_rounded,
                        //     color: AppColors.getError(isDark),
                        //     size: AppSizes.iconMedium,
                        //   ),
                        //   title: Text(
                        //     'Logout',
                        //     style: AppTextStyles.bodyLarge(isDark: isDark)
                        //         .copyWith(
                        //           color: AppColors.getError(isDark),
                        //           fontWeight: FontWeight.w500,
                        //           fontSize: AppSizes.fontMedium,
                        //         ),
                        //   ),
                        //   onTap: () async {
                        //     final shouldLogout = await showDialog<bool>(
                        //       context: context,
                        //       builder: (context) => AlertDialog(
                        //         backgroundColor: AppColors.getCard(isDark),
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(
                        //             AppSizes.radiusXl,
                        //           ),
                        //         ),
                        //         title: Text(
                        //           'Confirm Logout',
                        //           style: AppTextStyles.headingSmall(
                        //             isDark: isDark,
                        //           ).copyWith(fontSize: AppSizes.fontXl),
                        //         ),
                        //         content: Text(
                        //           'Are you sure you want to log out?',
                        //           style: AppTextStyles.bodyMedium(
                        //             isDark: isDark,
                        //           ).copyWith(fontSize: AppSizes.fontMedium),
                        //         ),
                        //         actions: [
                        //           TextButton(
                        //             onPressed: () =>
                        //                 Navigator.pop(context, false),
                        //             child: Text(
                        //               'Cancel',
                        //               style:
                        //                   AppTextStyles.labelLarge(
                        //                     isDark: isDark,
                        //                   ).copyWith(
                        //                     fontSize: AppSizes.fontMedium,
                        //                     color: AppColors.getTextSecondary(
                        //                       isDark,
                        //                     ),
                        //                   ),
                        //             ),
                        //           ),
                        //           ElevatedButton(
                        //             style: ElevatedButton.styleFrom(
                        //               backgroundColor: AppColors.getError(
                        //                 isDark,
                        //               ),
                        //               shape: RoundedRectangleBorder(
                        //                 borderRadius: BorderRadius.circular(
                        //                   AppSizes.radiusSmall,
                        //                 ),
                        //               ),
                        //             ),
                        //             onPressed: () =>
                        //                 Navigator.pop(context, true),
                        //             child: Text(
                        //               'Logout',
                        //               style:
                        //                   AppTextStyles.labelLarge(
                        //                     isDark: false,
                        //                   ).copyWith(
                        //                     fontSize: AppSizes.fontMedium,
                        //                     color: Colors.white,
                        //                   ),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     );

                        //     if (shouldLogout == true) {
                        //       await authNotifier.signOut();
                        //       if (context.mounted) context.go('/login');
                        //     }
                        //   },
                        // ),

                        // Animated Theme Toggle with Haptic Feedback
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
      padding: EdgeInsets.symmetric(vertical: AppSizes.paddingXs),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: AppColors.getTextPrimary(isDark),
          size: AppSizes.iconMedium,
        ),
        title: Text(
          label,
          style: AppTextStyles.bodyLarge(
            isDark: isDark,
          ).copyWith(fontSize: AppSizes.fontMedium),
        ),
        onTap: () {
          context.push(route);
        },
      ),
    );
  }
}
