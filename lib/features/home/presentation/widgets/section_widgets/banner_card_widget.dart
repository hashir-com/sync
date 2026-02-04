import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this for image handling

class BannerCard extends StatelessWidget {
  final dynamic event;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const BannerCard({
    super.key,
    required this.event,
    required this.isDark,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = event.startTime ?? DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(startTime);
    final attendeesCount = (event.attendees?.length ?? 0).clamp(0, 999);

    // Debug: Log the image URL to check if it's valid/empty
    final imageUrl = event.imageUrl;
    debugPrint(
      'BannerCard: Image URL for event "${event.title ?? 'Unknown'}": $imageUrl',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: ThemeUtils.shadowColor(context),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
              child: Container(
                color: AppColors.getSurface(isDark),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) {
                          // Debug: Log loading start
                          debugPrint('BannerCard: Loading image from $url');
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.getTextSecondary(isDark),
                            ),
                          );
                        },
                        errorWidget: (context, url, error) {
                          // Debug: Log error details
                          debugPrint(
                            'BannerCard: Image load FAILED for $url. Error: $error',
                          );
                          return Center(
                            child: Icon(
                              Icons.event_rounded,
                              size: AppSizes.iconXxl,
                              color: AppColors.getTextSecondary(
                                isDark,
                              ).withOpacity(0.5),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.event_rounded,
                          size: AppSizes.iconXxl,
                          color: AppColors.getTextSecondary(
                            isDark,
                          ).withOpacity(0.5),
                        ),
                      ),
              ),
            ),
            // Gradient overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
            // Favorite button
            Positioned(
              top: AppSizes.paddingMedium,
              right: AppSizes.paddingMedium,
              child: GestureDetector(
                onTap: onFavoriteTap,
                child: Container(
                  padding: EdgeInsets.all(AppSizes.paddingSmall),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? AppColors.getFavorite(isDark)
                        : Colors.white,
                    size: AppSizes.iconMedium,
                  ),
                ),
              ),
            ),
            // Bottom info panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title ?? 'Event',
                      style: AppTextStyles.headingSmall(isDark: false).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSizes.spacingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white70,
                          size: AppSizes.iconSmall,
                        ),
                        SizedBox(width: AppSizes.spacingXs),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: AppTextStyles.bodySmall(
                              isDark: false,
                            ).copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spacingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          color: Colors.white70,
                          size: AppSizes.iconSmall,
                        ),
                        SizedBox(width: AppSizes.spacingXs),
                        Expanded(
                          child: Text(
                            '$attendeesCount going',
                            style: AppTextStyles.bodySmall(
                              isDark: false,
                            ).copyWith(color: Colors.white70),
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
    );
  }
}
