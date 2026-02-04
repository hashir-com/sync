import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/core/di/injection_container.dart';
import 'package:sync_event/features/events/domain/entities/event_entity.dart';
import 'package:sync_event/features/events/domain/usecases/approved_event_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/create_event_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/delete_event_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/get_user_events_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/join_event_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/update_event_usecase.dart';
import 'package:sync_event/features/events/presentation/state/create_event_notifier.dart';
import 'package:sync_event/features/events/presentation/state/location_picker_notifier.dart';
import 'package:sync_event/features/home/presentation/screen/filter_bottom_sheet.dart';

// Use case providers
final createEventUseCaseProvider = Provider<CreateEventUseCase>(
  (ref) => sl<CreateEventUseCase>(),
);

final getApprovedEventsUseCaseProvider = Provider<GetApprovedEventsUseCase>(
  (ref) => sl<GetApprovedEventsUseCase>(),
);

final joinEventUseCaseProvider = Provider<JoinEventUseCase>(
  (ref) => sl<JoinEventUseCase>(),
);

final getUserEventsUseCaseProvider = Provider<GetUserEventsUseCase>(
  (ref) => sl<GetUserEventsUseCase>(),
);

final updateEventUseCaseProvider = Provider<UpdateEventUseCase>(
  (ref) => sl<UpdateEventUseCase>(),
);

final deleteEventUseCaseProvider = Provider<DeleteEventUseCase>(
  (ref) => sl<DeleteEventUseCase>(),
);

// Stream of approved events
final approvedEventsStreamProvider =
    StreamProvider.autoDispose<List<EventEntity>>((ref) {
  final usecase = ref.read(getApprovedEventsUseCaseProvider);
  return usecase.call();
});

// Stream of current user's events
final userEventsStreamProvider =
    StreamProvider.autoDispose.family<List<EventEntity>, String>((ref, userId) {
  final usecase = ref.read(getUserEventsUseCaseProvider);
  return usecase.call(userId);
});

// Filtered Events Provider
final filteredEventsProvider = Provider<List<EventEntity>>((ref) {
  final eventsAsync = ref.watch(approvedEventsStreamProvider);
  final filter = ref.watch(eventFilterProvider);

  return eventsAsync.when(
    data: (events) {
      final now = DateTime.now();

      // 1️⃣ REMOVE expired events FIRST
      var filtered = events
          .where((event) => event.endTime.isAfter(now))
          .toList();

      // 2️⃣ Filter by categories
      if (filter.selectedCategories.isNotEmpty) {
        filtered = filtered
            .where(
              (event) => filter.selectedCategories.contains(event.category),
            )
            .toList();
      }

      // 3️⃣ Filter by location
      if (filter.selectedLocation != null) {
        filtered = filtered
            .where(
              (event) => event.location
                  .toLowerCase()
                  .contains(filter.selectedLocation!.toLowerCase()),
            )
            .toList();
      }

      // 4️⃣ Filter by price range
      filtered = filtered
          .where(
            (event) =>
                (event.ticketPrice ?? 0) >= filter.priceRange.min &&
                (event.ticketPrice ?? double.infinity) <=
                    filter.priceRange.max,
          )
          .toList();

      // 5️⃣ Filter by date range (start time)
      if (filter.dateRange != null) {
        filtered = filtered
            .where(
              (event) =>
                  event.startTime.isAfter(filter.dateRange!.start) &&
                  event.startTime.isBefore(filter.dateRange!.end),
            )
            .toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});


// Notifier providers
final createEventNotifierProvider =
    StateNotifierProvider<CreateEventNotifier, CreateEventState>(
  (ref) => CreateEventNotifier(
    createEventUseCase: ref.read(createEventUseCaseProvider),
  ),
);

final locationPickerNotifierProvider =
    StateNotifierProvider.autoDispose<LocationPickerNotifier, LocationPickerState>(
  (ref) => LocationPickerNotifier(),
);