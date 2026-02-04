// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';

class FavoriteEventCard extends StatelessWidget {
  final dynamic event;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const FavoriteEventCard({super.key, 
    required this.event,
    required this.isDark,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getCard(isDark),
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: AppColors.getBorder(isDark), width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Event Image
              ClipRRect(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppSizes.radiusLarge),
                ),
                child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                    ? Image.network(
                        event.imageUrl!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // Event Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title ?? 'Event',
                        style: AppTextStyles.titleMedium(
                          isDark: isDark,
                        ).copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSizes.spacingSmall),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: AppSizes.iconSmall,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                          SizedBox(width: AppSizes.spacingXs),
                          Expanded(
                            child: Text(
                              dateFormat.format(event.startTime),
                              style: AppTextStyles.bodySmall(isDark: isDark)
                                  .copyWith(
                                    color: AppColors.getTextSecondary(isDark),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.spacingXs),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: AppSizes.iconSmall,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                          SizedBox(width: AppSizes.spacingXs),
                          Expanded(
                            child: Text(
                              timeFormat.format(event.startTime),
                              style: AppTextStyles.bodySmall(isDark: isDark)
                                  .copyWith(
                                    color: AppColors.getTextSecondary(isDark),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.spacingSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_rounded,
                                size: AppSizes.iconSmall,
                                color: AppColors.getPrimary(isDark),
                              ),
                              SizedBox(width: AppSizes.spacingXs),
                              Text(
                                '${event.attendees?.length ?? 0} going',
                                style: AppTextStyles.labelSmall(isDark: isDark)
                                    .copyWith(
                                      color: AppColors.getPrimary(isDark),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: onFavoriteTap,
                            child: Container(
                              padding: EdgeInsets.all(AppSizes.paddingSmall),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: AppSizes.iconMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: AppColors.getSurface(isDark),
      child: Icon(
        Icons.event_rounded,
        size: AppSizes.iconXxl,
        color: AppColors.getTextSecondary(isDark),
      ),
    );
  }
}
