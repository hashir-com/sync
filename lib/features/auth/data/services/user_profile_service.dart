// lib/features/auth/data/services/user_profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save or update user email in Firestore
  Future<void> saveUserEmail(String userId, String email) async {
    try {
      print('💾 Saving email to Firestore...');
      print('User ID: $userId');
      print('Email: $email');
      
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✓ Email saved successfully to Firestore');
    } catch (e) {
      print('❌ Error saving email to Firestore: $e');
      rethrow;
    }
  }

  // Get user email from Firestore (fallback for phone users)
  Future<String?> getUserEmail(String userId) async {
    try {
      print('📖 Fetching email from Firestore for user: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final email = doc.data()?['email'] as String?;
        print('✓ Email found in Firestore: $email');
        return email;
      }
      
      print('⚠️ No email found in Firestore');
      return null;
    } catch (e) {
      print('❌ Error fetching email from Firestore: $e');
      return null;
    }
  }

  // Get current user's email (from Firebase Auth or Firestore)
  Future<String?> getCurrentUserEmail() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // First try to get email from Firebase Auth
    if (user.email != null && user.email!.isNotEmpty) {
      print('✓ Using email from Firebase Auth: ${user.email}');
      return user.email;
    }

    // If no email in Firebase Auth, try Firestore (for phone users)
    print('⚠️ No email in Firebase Auth, checking Firestore...');
    return await getUserEmail(user.uid);
  }

  // Update user profile with phone and email
  Future<void> updateUserProfile({
    required String userId,
    String? email,
    String? name,
    String? phoneNumber,
  }) async {
    try {
      print('📝 Updating user profile in Firestore...');
      
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (email != null) updates['email'] = email;
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;

      await _firestore.collection('users').doc(userId).set(
        updates,
        SetOptions(merge: true),
      );
      
      print('✓ User profile updated successfully');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }
}

// Provider for UserProfileService


final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});