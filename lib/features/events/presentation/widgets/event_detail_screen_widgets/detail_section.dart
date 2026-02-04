import 'package:flutter/material.dart';

import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/responsive_util.dart';
import 'package:sync_event/features/events/domain/entities/event_entity.dart';
import 'package:sync_event/features/events/presentation/widgets/event_detail_screen_widgets/booking_button.dart';
import 'package:sync_event/features/events/presentation/widgets/event_detail_screen_widgets/going_section.dart';
import 'package:sync_event/features/events/presentation/widgets/event_detail_screen_widgets/organizer_tile.dart';
import 'package:sync_event/features/events/presentation/widgets/event_detail_screen_widgets/share_tile.dart';
import 'package:sync_event/features/events/presentation/widgets/event_detail_screen_widgets/detail_tile.dart';

// Import ErrorBoundary (create if missing - see below)
import 'package:sync_event/widgets/error_boundary.dart'; // Adjust path

// Widget for the white card section with event details
class DetailSection extends StatelessWidget {
  final EventEntity event;
  final bool isOrganizer;
  final bool isDark;

  const DetailSection({
    super.key,
    required this.event,
    required this.isOrganizer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.getCard(isDark),
      child: Padding(
        padding: ResponsiveUtil.getResponsivePadding(
          context,
        ).copyWith(bottom: 32),
        child: ErrorBoundary(
          // Isolates crashes - preserves parent map
          child: Builder(
            // Safe rebuild context
            builder: (context) {
              try {
               final title = event.title;
final formattedDate = event.formattedDate;
final formattedDayTime = event.formattedDayTime;
final formattedDuration = event.formattedDuration;
final location = event.location;
final locationSubtitle = event.locationSubtitle;
final description = event.description;
final organizerId = event.organizerId;
final organizerName = event.organizerName;
final eventId = event.id;


                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GoingSection(isDark: isDark),  // Uncomment when safe
                    // SizedBox(height: AppSizes.spacingLarge),
                    Text(
                      title,
                      style: AppTextStyles.headingLarge(isDark: isDark),
                    ),
                    SizedBox(height: AppSizes.spacingXxl),
                    DetailTile(
                      icon: Icons.calendar_today_rounded,
                      title: formattedDate,
                      subtitle: formattedDayTime,
                      isDark: isDark,
                    ),
                    SizedBox(height: AppSizes.spacingMedium),
                    DetailTile(
                      icon: Icons.access_time_rounded,
                      title: 'Duration',
                      subtitle: formattedDuration,
                      isDark: isDark,
                    ),
                    SizedBox(height: AppSizes.spacingMedium),
                    DetailTile(
                      icon: Icons.location_on_rounded,
                      title: locationSubtitle,
                      subtitle: location,
                      isDark: isDark,
                    ),
                    SizedBox(height: AppSizes.spacingMedium),
                    OrganizerTile(
                      organizerId: organizerId,
                      organizerName: organizerName,
                      isDark: isDark,
                    ),
                    SizedBox(height: AppSizes.spacingMedium),
                    ShareTile(
                      isDark: isDark,
                      eventTitle: 'Share With Friends',
                      eventDescription: "Share this app with your friends to let them joiun the events!",
                      shareUrl: "https://apkpure.com/p/ashir.developer.sync_event",
                    ),
                    SizedBox(height: AppSizes.spacingXxl),
                    Text(
                      'About Event',
                      style: AppTextStyles.titleMedium(isDark: isDark),
                    ),
                    SizedBox(height: AppSizes.spacingMedium),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium(isDark: isDark),
                    ),
                    SizedBox(height: AppSizes.spacingXxl),
                    if (event.hasStarted && !event.hasEnded) ...[
  Container(
    padding: EdgeInsets.all(AppSizes.paddingSmall),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      'Event has started',
      style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
        color: Colors.orange,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  SizedBox(height: AppSizes.spacingMedium),
],

event.hasStarted || event.hasEnded ?  // Check if event has started but not yet ended
  SizedBox(
    width: double.infinity,
    child: Container(
      padding: EdgeInsets.all(AppSizes.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Event has Started - Booking Closed',
          style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  ):

                    BookingButton(
                      eventId: eventId,
                      isOrganizer: isOrganizer,
                      isDark: isDark,
                    ),
                    SizedBox(height: AppSizes.spacingLarge),
                  ],
                );
              } catch (e, stackTrace) {
                print('DetailSection: Build error: $e\nStack: $stackTrace');
                return _buildErrorFallback(context);
              }
            },
          ),
        ),
      ),
    );
  }

  // Safe string formatter (handles null/type issues)
  String _safeFormat(dynamic value) {
    try {
      return value?.toString() ?? '';
    } catch (e) {
      print('DetailSection: Format error for $value: $e');
      return '';
    }
  }

  // Fallback UI if crash
  Widget _buildErrorFallback(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: AppSizes.spacingSmall),
          Text(
            'Error loading details',
            style: AppTextStyles.bodyMedium(isDark: false),
          ),
          SizedBox(height: AppSizes.spacingMedium),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), // Close card
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
