// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/events/presentation/providers/event_providers.dart';
import 'package:sync_event/features/events/presentation/widgets/event_screen_widgets/events_list_view.dart';
import 'package:sync_event/features/home/presentation/screen/filter_bottom_sheet.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredEvents = ref.watch(filteredEventsProvider);
    final filter = ref.watch(eventFilterProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = ThemeUtils.isDark(context);
    

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.getBackground(isDark),
        appBar: AppBar(
          title: Text(
            'Discover Events',
            style: AppTextStyles.titleLarge(
              isDark: isDark,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.getBackground(isDark),
          actions: [
            // Filter button with badge
            // Filter button with badge
            Padding(
              padding: EdgeInsets.only(right: AppSizes.paddingXs),
              child: Stack(
                children: [
                  Container(
                    margin: EdgeInsets.all(AppSizes.paddingXs),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(isDark),
                      borderRadius: BorderRadius.circular(
                        50,
                      ), // <-- fully rounded
                      border: Border.all(
                        color: filter.hasActiveFilters
                            ? AppColors.getPrimary(isDark).withOpacity(0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: filter.hasActiveFilters
                            ? AppColors.getPrimary(isDark)
                            : AppColors.getTextSecondary(isDark),
                      ),
                      onPressed: () {
                        showFilterBottomSheet(
                          context,
                          onApplyFilters: () {
                            if (kDebugMode) {
                              print("Filters applied on events screen");
                            }
                          },
                        );
                      },
                    ),
                  ),
                  if (filter.hasActiveFilters)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.getError(isDark),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getError(
                                isDark,
                              ).withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          '${_getActiveFilterCount(filter)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Reset filters button
            if (filter.hasActiveFilters)
              Padding(
                padding: EdgeInsets.only(right: AppSizes.paddingSmall),
                child: Container(
                  margin: EdgeInsets.all(AppSizes.paddingXs),
                  decoration: BoxDecoration(
                    color: AppColors.getError(isDark).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      50,
                    ), // <-- fully rounded
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.getError(isDark),
                    ),
                    onPressed: () {
                      ref.read(eventFilterProvider.notifier).reset();
                    },
                    tooltip: 'Clear filters',
                  ),
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(approvedEventsStreamProvider);
          },
          color: AppColors.getPrimary(isDark),
          child: EventsListView(
            events: filteredEvents,
            currentUserId: currentUserId,
            filter: filter,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  int _getActiveFilterCount(EventFilter filter) {
    int count = 0;
    if (filter.selectedCategories.isNotEmpty) count++;
    if (filter.selectedLocation != null) count++;
    if (filter.dateRange != null) count++;
    if (filter.priceRange.min > 0 || filter.priceRange.max < double.infinity) {
      count++;
    }
    return count;
  }
}
