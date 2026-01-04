// lib/features/legal/presentation/screens/privacy_security_screen.dart
import 'package:flutter/material.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/responsive_util.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
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
                  'Privacy Policy',
                  style: AppTextStyles.headingMedium(isDark: isDark),
                ),
                SizedBox(height: ResponsiveUtil.getSpacing(context, baseSpacing: 16)),
                _buildSection(
                  context,
                  'Information We Collect',
                  'We collect personal information such as your name, email, and usage data to provide and improve our services. This includes data from your device and interactions with the app.',
                ),
                _buildSection(
                  context,
                  'How We Use Your Information',
                  'Your information is used to personalize your experience, process transactions, send communications, and analyze usage for improvements. We do not sell your data to third parties.',
                ),
                _buildSection(
                  context,
                  'Data Security',
                  'We employ SSL encryption, secure servers, and regular security audits to protect your data. Access is restricted to authorized personnel only.',
                ),
                _buildSection(
                  context,
                  'Your Rights',
                  'You have the right to access, update, or delete your data. Contact us at privacy@syncevent.com to exercise these rights.',
                ),
                _buildSection(
                  context,
                  'Changes to This Policy',
                  'We may update this policy periodically. Changes will be posted here with the updated date at the top.',
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