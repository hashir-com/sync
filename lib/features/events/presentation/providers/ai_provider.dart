import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/core/services/ai_services.dart';

// State for AI generation
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

// AI Notifier
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
        generatedText: description,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> generateIdeas({
    required String title,
    required String date,
    required String location,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

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
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = AIState();
  }
}

// Provider
final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier();
});