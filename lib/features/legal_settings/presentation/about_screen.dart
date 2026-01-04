// lib/features/legal/presentation/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/responsive_util.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'About SyncEvent',
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
            padding: EdgeInsets.all(
              ResponsiveUtil.getSpacing(context, baseSpacing: 24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rounded Sync Logo
                Center(
                  child: CircleAvatar(
                    radius: ResponsiveUtil.getAvatarSize(context, baseSize: 50),
                    backgroundColor: AppColors.getPrimary(isDark),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/sync_logo_icon.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if image fails to load
                          return Icon(
                            Icons.sync_alt,
                            size: 50,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
                ),
                Text(
                  'Welcome to SyncEvent',
                  style: AppTextStyles.headingMedium(isDark: isDark),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveUtil.getSpacing(context, baseSpacing: 8),
                ),
                Text(
                  'SyncEvent is a cutting-edge platform designed to streamline event management, collaboration, and synchronization for teams worldwide.',
                  style: AppTextStyles.bodyMedium(isDark: isDark),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveUtil.getSpacing(context, baseSpacing: 24),
                ),
                _buildInfoRow(
                  context,
                  Icons.info_outline,
                  'Our Mission',
                  'To empower users with seamless tools for event planning and execution.',
                ),
                _buildInfoRow(
                  context,
                  Icons.group_outlined,
                  'Team',
                  'A dedicated team of developers, designers, and event experts.',
                ),
                _buildInfoRow(
                  context,
                  Icons.location_on_outlined,
                  'Headquarters',
                  'Bangalore, India',
                ),
                _buildInfoRow(
                  context,
                  Icons.email_outlined,
                  'Contact',
                  'info@syncevent.com',
                ),
                SizedBox(
                  height: ResponsiveUtil.getSpacing(context, baseSpacing: 24),
                ),
                Text(
                  'Version 1.0.0',
                  style: AppTextStyles.caption(isDark: isDark),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtil.getSpacing(context, baseSpacing: 12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.getPrimary(isDark), size: 24),
          SizedBox(width: ResponsiveUtil.getSpacing(context, baseSpacing: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall(
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(subtitle, style: AppTextStyles.bodySmall(isDark: isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
