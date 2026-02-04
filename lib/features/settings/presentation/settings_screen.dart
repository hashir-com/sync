// lib/features/settings/presentation/pages/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/auth/presentation/providers/auth_notifier.dart';
import 'package:sync_event/core/constants/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeUtils.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Settings',
              style: AppTextStyles.headingLarge(isDark: isDark).copyWith(
                fontSize: AppSizes.fontDisplay1,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: AppSizes.spacingXxxl),

            // --- ACCOUNT ---
            _buildSectionTitle('ACCOUNT', isDark),
            SizedBox(height: AppSizes.spacingSmall),

            _buildSimpleTile(
              context,
              isDark,
              Icons.person_outline_rounded,
              'Account Settings',
              '/profile', // placeholder route
            ),
            _buildThemeSwitcher(context, ref, isDark),

            SizedBox(height: AppSizes.spacingXxl),

            // --- SUPPORT ---
            _buildSectionTitle('SUPPORT', isDark),
            SizedBox(height: AppSizes.spacingSmall),

            _buildSimpleTile(
              context,
              isDark,
              Icons.help_outline,
              'Help & FAQ',
              '/help-faq', // placeholder route
            ),
            _buildSimpleTile(
              context,
              isDark,
              Icons.mail_outline_rounded,
              'Contact Us',
              '/contact-us', // placeholder route
            ),

            SizedBox(height: AppSizes.spacingXxl),

            // --- LEGAL ---
            _buildSectionTitle('LEGAL', isDark),
            SizedBox(height: AppSizes.spacingSmall),

            _buildSimpleTile(
              context,
              isDark,
              Icons.privacy_tip_outlined,
              'Privacy & Security',
              '/privacy-security', // placeholder route
            ),
            _buildSimpleTile(
              context,
              isDark,
              Icons.description_outlined,
              'Terms & Conditions',
              '/terms-conditions', // placeholder route
            ),
            _buildSimpleTile(
              context,
              isDark,
              Icons.info_outline_rounded,
              'About',
              '/about', // placeholder route
            ),

            SizedBox(height: AppSizes.spacingXxl),

            // --- SIGN OUT ---
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeightLarge,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getError(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.getCard(isDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                      ),
                      title: Text(
                        'Sign Out?',
                        style: AppTextStyles.headingSmall(
                          isDark: isDark,
                        ).copyWith(fontSize: AppSizes.fontXl),
                      ),
                      content: Text(
                        'Are you sure you want to sign out?',
                        style: AppTextStyles.bodyMedium(
                          isDark: isDark,
                        ).copyWith(fontSize: AppSizes.fontMedium),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.labelLarge(isDark: isDark)
                                .copyWith(
                                  fontSize: AppSizes.fontMedium,
                                  color: AppColors.getTextSecondary(isDark),
                                ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getError(isDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSmall,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Sign Out',
                            style: AppTextStyles.labelLarge(isDark: false)
                                .copyWith(
                                  fontSize: AppSizes.fontMedium,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && context.mounted) {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  }
                },
                child: Text(
                  'Sign Out',
                  style: AppTextStyles.labelLarge(isDark: false).copyWith(
                    fontSize: AppSizes.fontMedium,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSizes.spacingXxxl),

            // --- VERSION INFO ---
            Center(
              child: Text(
                'Version 1.0.0',
                style: AppTextStyles.bodySmall(
                  isDark: isDark,
                ).copyWith(color: AppColors.getTextSecondary(isDark)),
              ),
            ),
            SizedBox(height: AppSizes.spacingLarge),
          ],
        ),
      ),
    );
  }

  // --- Section Title ---
  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTextStyles.bodySmall(isDark: isDark).copyWith(
        color: AppColors.getTextSecondary(isDark),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  // --- Simple List Tile (no border box) ---
  Widget _buildSimpleTile(
    BuildContext context,
    bool isDark,
    IconData icon,
    String label,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.getTextPrimary(isDark)),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge(
          isDark: isDark,
        ).copyWith(fontWeight: FontWeight.w500, fontSize: AppSizes.fontMedium),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: AppSizes.iconSmall,
        color: AppColors.getTextSecondary(isDark),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
    );
  }

  // --- Theme Switcher (keeps your previous logic) ---
  Widget _buildThemeSwitcher(BuildContext context, WidgetRef ref, bool isDark) {
    final themeIsDark = ref.watch(themeProvider);

    return ListTile(
      leading: Icon(
        Icons.brightness_6_outlined,
        color: AppColors.getTextPrimary(isDark),
      ),
      title: Text(
        'Theme',
        style: AppTextStyles.bodyLarge(
          isDark: isDark,
        ).copyWith(fontWeight: FontWeight.w500, fontSize: AppSizes.fontMedium),
      ),
      trailing: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          await ref.read(themeProvider.notifier).toggleTheme(!themeIsDark);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 60,
          height: AppSizes.chipHeight,
          padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingXs),
          decoration: BoxDecoration(
            color: themeIsDark
                ? AppColors.getPrimary(isDark)
                : AppColors.getDisabled(isDark),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                alignment: themeIsDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: AppSizes.iconMedium,
                  height: AppSizes.iconMedium,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getShadow(isDark),
                        blurRadius: AppSizes.cardElevationLow,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    themeIsDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: AppSizes.iconSmall,
                    color: themeIsDark
                        ? AppColors.getPrimary(isDark)
                        : Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
