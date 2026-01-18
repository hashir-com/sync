// lib/features/legal/presentation/screens/terms_conditions_screen.dart
import 'package:flutter/material.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/responsive_util.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: AppTextStyles.headingSmall(isDark: isDark),
        ),
        backgroundColor: AppColors.getCard(isDark),
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtil.getResponsivePadding(context),
        child: Card(
          elevation: ResponsiveUtil.getElevation(context, baseElevation: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtil.getBorderRadius(context, baseRadius: 20),
            ),
          ),
          color: AppColors.getCard(isDark),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtil.getSpacing(context, baseSpacing: 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms of Service',
                  style: AppTextStyles.headingMedium(isDark: isDark),
                ),
                SizedBox(height: ResponsiveUtil.getSpacing(context, baseSpacing: 16)),
                _buildSection(
                  context,
                  'Acceptance of Terms',
                  'By accessing or using our app, you agree to these terms. If you do not agree, please do not use the service.',
                ),
                _buildSection(
                  context,
                  'User Responsibilities',
                  'Users must provide accurate information and not misuse the app. Prohibited activities include spamming, harassment, or illegal use.',
                ),
                _buildSection(
                  context,
                  'Intellectual Property',
                  'All content in the app is owned by SyncEvent or its licensors. Users may not reproduce or distribute without permission.',
                ),
                _buildSection(
                  context,
                  'Limitation of Liability',
                  'We are not liable for indirect damages. The app is provided "as is" without warranties.',
                ),
                _buildSection(
                  context,
                  'Governing Law',
                  'These terms are governed by the laws of California, USA.',
                ),
                _buildSection(
                  context,
                  'Changes to Terms',
                  'We may update these terms. Continued use constitutes acceptance of changes.',
                ),
                SizedBox(height: ResponsiveUtil.getSpacing(context, baseSpacing: 16)),
                Text(
                  'Last Updated: October 28, 2025',
                  style: AppTextStyles.caption(isDark: isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtil.getSpacing(context, baseSpacing: 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge(isDark: isDark).copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: ResponsiveUtil.getSpacing(context, baseSpacing: 8)),
          Text(
            content,
            style: AppTextStyles.bodyMedium(isDark: isDark),
          ),
        ],
      ),
    );
  }
}