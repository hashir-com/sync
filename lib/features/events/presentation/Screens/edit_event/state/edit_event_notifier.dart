import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/features/events/domain/entities/event_entity.dart';
import 'package:sync_event/features/events/domain/usecases/update_event_usecase.dart';
import 'edit_event_state.dart';

class EditEventSubmissionNotifier extends StateNotifier<EditEventSubmissionState> {
  final UpdateEventUseCase updateEventUseCase;

  EditEventSubmissionNotifier({required this.updateEventUseCase})
      : super(EditEventSubmissionState());

  Future<void> updateEvent(
    EventEntity event, {
    File? coverFile,
    File? docFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await updateEventUseCase.call(
        event,
        coverFile: coverFile,
        docFile: docFile,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
    }
  }

  void reset() {
    state = EditEventSubmissionState();
  }
}

class EditEventFormNotifier extends StateNotifier<EditEventFormData?> {
  EditEventFormNotifier() : super(null);

  void initialize(EventEntity event) {
    state = EditEventFormData(
      title: event.title,
      description: event.description,
      location: event.location,
      category: event.category,
      maxAttendees: event.maxAttendees,
      ticketPrice: event.ticketPrice,
      startTime: event.startTime,
      endTime: event.endTime,
      existingImageUrl: event.imageUrl,
      existingDocumentUrl: event.documentUrl,
      latitude: event.latitude,
      longitude: event.longitude,
    );
  }

  void updateFormData(EditEventFormData newData) {
    state = newData;
  }

  void reset() {
    state = null;
  }
}