// lib/features/auth/presentation/providers/auth_state_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/features/profile/presentation/providers/other_users_provider.dart'; // Import to use UserModel

final authStateProvider = StreamProvider<UserModel?>((ref) {
  // Use userChanges instead of authStateChanges to capture profile updates
  return firebase_auth.FirebaseAuth.instance.userChanges().asyncMap((user) async {
    if (user == null) return null;
    try {
      // Fetch full profile from Firestore for complete UserModel
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        // Fallback to basic from Firebase
        return UserModel.fromFirebaseUser(user);
      }
    } catch (e) {
      // Fallback
      return UserModel.fromFirebaseUser(user);
    }
  });
});

// Provider for current user (synchronous access, basic Firebase user)
final currentUserProvider = Provider<firebase_auth.User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => firebase_auth.FirebaseAuth.instance.currentUser,
    loading: () => firebase_auth.FirebaseAuth.instance.currentUser,
    error: (_, __) => null,
  );
});