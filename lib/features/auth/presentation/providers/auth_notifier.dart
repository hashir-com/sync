// // auth_notifier.dart - FIXED VERSION
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sync_event/features/auth/domain/entities/user_entity.dart';
// import 'package:sync_event/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
// import 'package:sync_event/features/auth/domain/usecases/sign_out_usecase.dart';
// import 'package:sync_event/features/auth/presentation/providers/auth_providers.dart';

// class AuthState {
//   final bool isLoading;
//   final String? error;
//   final UserEntity? user;

//   AuthState({this.isLoading = false, this.error, this.user});

//   AuthState copyWith({bool? isLoading, String? error, UserEntity? user}) {
//     return AuthState(
//       isLoading: isLoading ?? this.isLoading,
//       error: error,
//       user: user ?? this.user,
//     );
//   }
// }

// class AuthNotifier extends StateNotifier<AuthState> {
//   final SignInWithGoogleUseCase _signInWithGoogleUseCase;
//   final SignOutUseCase _signOutUseCase;

//   AuthNotifier(this._signInWithGoogleUseCase, this._signOutUseCase)
//       : super(AuthState()) {
//     // Initialize with current Firebase user on app start
//     _initializeWithCurrentUser();
//   }

//   void _initializeWithCurrentUser() {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       final userEntity = UserEntity(
//         uid: currentUser.uid,
//         email: currentUser.email!,
//         name: currentUser.displayName,
//         image: currentUser.photoURL,
//         phoneNumber: currentUser.phoneNumber,
//       );
//       state = state.copyWith(user: userEntity);
//     }
//   }

//   Future<bool> signInWithGoogle({bool forceAccountChooser = true}) async {
//     state = state.copyWith(isLoading: true, error: null);
//     try {
//       final params = GoogleSignInParams(
//         forceAccountChooser: forceAccountChooser,
//       );
//       final result = await _signInWithGoogleUseCase.call(params);
//       return result.fold(
//         (failure) {
//           state = state.copyWith(isLoading: false, error: failure.message);
//           return false;
//         },
//         (userEntity) {
//           state = state.copyWith(isLoading: false, user: userEntity);
//           return true;
//         },
//       );
//     } on FirebaseAuthException catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: _mapFirebaseAuthException(e),
//       );
//       return false;
//     } catch (e) {
//       state = state.copyWith(isLoading: false, error: e.toString());
//       return false;
//     }
//   }

//   Future<void> signOut() async {
//     await _signOutUseCase.call();
//     state = AuthState();
//   }

//   // NEW: Method to refresh auth state (useful after critical operations)
//   void refreshAuthState() {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       final userEntity = UserEntity(
//         uid: currentUser.uid,
//         email: currentUser.email!,
//         name: currentUser.displayName,
//         image: currentUser.photoURL,
//         phoneNumber: currentUser.phoneNumber,
//       );
//       state = state.copyWith(user: userEntity);
//     }
//   }

//   String _mapFirebaseAuthException(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'account-exists-with-different-credential':
//         return 'Account exists with different credentials.';
//       case 'invalid-credential':
//         return 'Invalid credentials provided.';
//       case 'operation-not-allowed':
//         return 'Operation not allowed.';
//       case 'user-disabled':
//         return 'User account is disabled.';
//       case 'user-not-found':
//         return 'User not found.';
//       default:
//         return 'Authentication failed: ${e.message ?? "An error occurred"}';
//     }
//   }
// }

// final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
//   (ref) => AuthNotifier(
//     ref.read(signInWithGoogleUseCaseProvider),
//     ref.read(signOutUseCaseProvider),
//   ),
// );

// // NEW: Stream provider for real-time auth state
// final authStateProvider = StreamProvider<User?>((ref) {
//   return FirebaseAuth.instance.authStateChanges();
// });

// auth_notifier.dart - COMPLETE FIXED VERSION
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/features/auth/domain/entities/user_entity.dart';
import 'package:sync_event/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:sync_event/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:sync_event/features/auth/presentation/providers/auth_providers.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final UserEntity? user;

  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, UserEntity? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignOutUseCase _signOutUseCase;

  AuthNotifier(this._signInWithGoogleUseCase, this._signOutUseCase)
      : super(AuthState()) {
    // CRITICAL FIX: Listen to Firebase auth state changes
    _listenToAuthChanges();
  }

  // NEW: Listen to Firebase auth state changes in real-time
  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) {
      print('🔄 Auth state changed - User: ${firebaseUser?.uid ?? "null"}');
      
      if (firebaseUser != null) {
        final userEntity = UserEntity(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName,
          image: firebaseUser.photoURL,
          phoneNumber: firebaseUser.phoneNumber,
        );
        
        print('✓ User updated in AuthNotifier:');
        print('  UID: ${userEntity.uid}');
        print('  Email: ${userEntity.email}');
        print('  Phone: ${userEntity.phoneNumber}');
        
        // Update state with new user
        state = state.copyWith(user: userEntity, error: null);
      } else {
        print('✗ No user - clearing auth state');
        state = AuthState();
      }
    });
  }

  Future<bool> signInWithGoogle({bool forceAccountChooser = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = GoogleSignInParams(
        forceAccountChooser: forceAccountChooser,
      );
      final result = await _signInWithGoogleUseCase.call(params);
      return result.fold(
        (failure) {
          print('✗ Google sign-in failed: ${failure.message}');
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (userEntity) {
          print('✓ Google sign-in success: ${userEntity.uid}');
          state = state.copyWith(isLoading: false, user: userEntity);
          return true;
        },
      );
    } on FirebaseAuthException catch (e) {
      print('✗ Firebase auth exception: ${e.code}');
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseAuthException(e),
      );
      return false;
    } catch (e) {
      print('✗ Unexpected error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    print('👋 Signing out...');
    await _signOutUseCase.call();
    state = AuthState();
  }

  // Method to manually refresh auth state (useful for debugging)
  void refreshAuthState() {
    final currentUser = FirebaseAuth.instance.currentUser;
    print('🔄 Manually refreshing auth state: ${currentUser?.uid ?? "null"}');
    
    if (currentUser != null) {
      final userEntity = UserEntity(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        name: currentUser.displayName,
        image: currentUser.photoURL,
        phoneNumber: currentUser.phoneNumber,
      );
      state = state.copyWith(user: userEntity);
    } else {
      state = AuthState();
    }
  }

  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Account exists with different credentials.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'user-disabled':
        return 'User account is disabled.';
      case 'user-not-found':
        return 'User not found.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication failed: ${e.message ?? "An error occurred"}';
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(signInWithGoogleUseCaseProvider),
    ref.read(signOutUseCaseProvider),
  ),
);

// Stream provider for real-time auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});