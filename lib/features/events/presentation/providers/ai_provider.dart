// ai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sync_event/core/services/ai_services.dart';

class AIState {
  final bool isLoading;
  final String? generatedText;
  final String? error;

  AIState({
    this.isLoading = false,
    this.generatedText,
    this.error,
  });

  AIState copyWith({
    bool? isLoading,
    String? generatedText,
    String? error,
  }) {
    return AIState(
      isLoading: isLoading ?? this.isLoading,
      generatedText: generatedText ?? this.generatedText,
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

    state = state.copyWith(isLoading: true, error: null, generatedText: null);

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
        generatedText: description,
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

    state = state.copyWith(isLoading: true, error: null, generatedText: null);

    try {
      final ideas = await AIService.generateEventIdeas(
        title: title,
        date: date,
        location: location,
      );

      state = state.copyWith(
        isLoading: false,
        generatedText: ideas,
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