// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/auth/presentation/providers/auth_notifier.dart';

class SocialButtons extends ConsumerWidget {
  const SocialButtons({super.key});

  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isDark,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium(
            isDark: true,
          ).copyWith(fontSize: AppSizes.fontMedium, color: Colors.white),
        ),
        backgroundColor: isError
            ? AppColors.getError(isDark)
            : AppColors.getSuccess(isDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
        ),
        margin: EdgeInsets.all(AppSizes.paddingLarge),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeUtils.isDark(context);
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Column(
      children: [
        // Google Sign-In Button
        SizedBox(
          width: 320,
          child: Material(
            elevation: AppSizes.cardElevationMedium,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            shadowColor: AppColors.getShadow(isDark),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              onTap: authState.isLoading
                  ? null
                  : () async {
                      final success = await authNotifier.signInWithGoogle(
                        forceAccountChooser: true,
                      );
                      if (success && context.mounted) {
                        _showSnackBar(
                          context,
                          'Successfully signed in!',
                          isDark: isDark,
                        );
                        context.go('/root');
                      } else if (authState.error != null && context.mounted) {
                        _showSnackBar(
                          context,
                          'Sign-inn failed: ${authState.error}',
                          isDark: isDark,
                          isError: true,
                        );
                       print(
                            'SocialButtons: Google sign-in error: ${authState.error}');   
                      }
                    },
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: AppSizes.paddingMedium,
                  horizontal: AppSizes.paddingLarge,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  color: AppColors.getCard(isDark),
                  border: Border.all(
                    color: AppColors.getBorder(isDark).withOpacity(0.3),
                    width: AppSizes.borderWidthThin,
                  ),
                ),
                child: authState.isLoading
                    ? Shimmer.fromColors(
                        baseColor: AppColors.getShimmerBase(isDark),
                        highlightColor: AppColors.getShimmerHighlight(isDark),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.google,
                              color: AppColors.getTextSecondary(isDark),
                              size: AppSizes.iconMedium,
                            ),
                            SizedBox(width: AppSizes.spacingLarge),
                            Text(
                              "Continue with Google",
                              style: AppTextStyles.labelLarge(isDark: isDark)
                                  .copyWith(
                                    fontSize: AppSizes.fontMedium,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.google,
                            color: AppColors.error,
                            size: AppSizes.iconMedium,
                          ),
                          SizedBox(width: AppSizes.spacingLarge),
                          Text(
                            "Continue with Google",
                            style: AppTextStyles.labelLarge(isDark: isDark)
                                .copyWith(
                                  fontSize: AppSizes.fontMedium,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSizes.spacingXl),

        // Phone Sign-In Button
        SizedBox(
          width: 320,
          child: Material(
            elevation: AppSizes.cardElevationMedium,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            shadowColor: AppColors.getShadow(isDark),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              onTap: () => context.push('/phone'),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: AppSizes.paddingMedium,
                  horizontal: AppSizes.paddingLarge,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  color: AppColors.getCard(isDark),
                  border: Border.all(
                    color: AppColors.getBorder(isDark).withOpacity(0.3),
                    width: AppSizes.borderWidthThin,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      color: AppColors.getPrimary(isDark),
                      size: AppSizes.iconMedium,
                    ),
                    SizedBox(width: AppSizes.spacingLarge),
                    Text(
                      "Continue with Phone",
                      style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                        fontSize: AppSizes.fontMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
