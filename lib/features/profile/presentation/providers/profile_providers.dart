import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/features/profile/domain/entities/profile_entity.dart';
// Use Case Providers (for DI)
import 'package:sync_event/core/di/injection_container.dart';
import 'package:sync_event/features/profile/domain/usecases/create_user_usecase.dart';
import 'package:sync_event/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:sync_event/features/profile/domain/usecases/update_user_profile_usecase.dart';

// UserModel (unified with ProfileEntity for consistency)
class UserModel extends ProfileEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.image,
    super.bio,
    super.interests,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      image: data['image'],
      bio: data['bio'],
      interests: data['interests'] != null
          ? List<String>.from(data['interests'])
          : const [],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserModel.fromFirebaseUser(firebase_auth.User? user) {
    if (user == null) {
      throw ArgumentError('User cannot be null');
    }
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      image: user.photoURL,
    );
  }

  factory UserModel.fromProfileEntity(ProfileEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      image: entity.image,
      bio: entity.bio,
      interests: entity.interests,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

final createUserProfileUseCaseProvider = Provider<CreateUserProfileUseCase>(
  (ref) => sl<CreateUserProfileUseCase>(),
);
// Auth State Provider (fetches full profile)
final authStateProvider = StreamProvider<UserModel?>((ref) {
  return firebase_auth.FirebaseAuth.instance.userChanges().asyncMap((
    user,
  ) async {
    if (user == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        return UserModel.fromFirebaseUser(user);
      }
    } catch (e) {
      return UserModel.fromFirebaseUser(user);
    }
  });
});

// Current Firebase User (for quick access)
final currentUserProvider = Provider<firebase_auth.User?>((ref) {
  return firebase_auth.FirebaseAuth.instance.currentUser;
});

// All Users
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  });
});

// User by ID
final userByIdProvider = StreamProvider.family<UserModel?, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });
});

// User Hosted Events
final userHostedEventsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
      if (userId.isEmpty) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('events')
          .where('organizerId', isEqualTo: userId)
          // Removed .where('status', isEqualTo: 'approved') to fetch all statuses
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
          });
    });

// Search Users
final searchUsersProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  query,
) {
  if (query.isEmpty || query.length < 2) {
    return Stream.value([]);
  }
  final lowerQuery = query.toLowerCase();
  return FirebaseFirestore.instance.collection('users').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where(
          (user) =>
              user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery),
        )
        .toList();
  });
});

// Followers Count
final userFollowersCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('followers')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// Following Count
final userFollowingCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('following')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>(
  (ref) => sl<GetUserProfileUseCase>(),
);
final updateUserProfileUseCaseProvider = Provider<UpdateUserProfileUseCase>(
  (ref) => sl<UpdateUserProfileUseCase>(),
);
