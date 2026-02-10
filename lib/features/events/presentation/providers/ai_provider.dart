// ai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sync_event/core/services/ai_services.dart';

class AIState {
  final bool isLoading;
  final String? descriptionText;  // New: For Description tab
  final String? ideasText;        // New: For Ideas tab
  final String? error;

  AIState({
    this.isLoading = false,
    this.descriptionText,
    this.ideasText,
    this.error,
  });

  AIState copyWith({
    bool? isLoading,
    String? descriptionText,
    String? ideasText,
    String? error,
  }) {
    return AIState(
      isLoading: isLoading ?? this.isLoading,
      descriptionText: descriptionText ?? this.descriptionText,
      ideasText: ideasText ?? this.ideasText,
      error: error ?? this.error,
    );
  }
}

class AINotifier extends StateNotifier<AIState> {
  AINotifier() : super(AIState());

  Future<void> generateDescription({
    required String title,
    required String date,
    required String time,
    required String duration,
    required String location,
    String? existingDescription,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please sign in to use AI features',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final description = await AIService.generateEventDescription(
        title: title,
        date: date,
        time: time,
        duration: duration,
        location: location,
        existingDescription: existingDescription,
      );

      state = state.copyWith(
        isLoading: false,
        descriptionText: description,  // Set only description
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> generateIdeas({
    required String title,
    required String date,
    required String location,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please sign in to use AI features',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final ideas = await AIService.generateEventIdeas(
        title: title,
        date: date,
        location: location,
      );

      state = state.copyWith(
        isLoading: false,
        ideasText: ideas,  // Set only ideas
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = AIState();
  }
}

final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier();
});