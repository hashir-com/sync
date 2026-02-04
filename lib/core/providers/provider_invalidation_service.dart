// lib/core/services/provider_invalidation_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/features/auth/presentation/providers/auth_notifier.dart';
import 'package:sync_event/features/profile/presentation/providers/other_users_provider.dart';

class ProviderInvalidationService {
  /// Invalidate all user-related providers when auth state changes
  static void invalidateUserProviders(WidgetRef ref) {
    // Invalidate all user profile providers
    ref.invalidate(authStateProvider);
    ref.invalidate(allUsersProvider);
    // Note: We don't invalidate family providers here as they auto-invalidate
    // when their parameter changes (userId)
  }
  
  /// Clear all cached state on logout
  static void clearAllCachedState(WidgetRef ref) {
    ref.invalidate(authStateProvider);
    ref.invalidate(allUsersProvider);
    // The StreamProvider will automatically stop listening and clean up
  }
}

// Add these imports to your profile_providers.dart file:
// import 'package:sync_event/features/profile/presentation/providers/profile_providers.dart';