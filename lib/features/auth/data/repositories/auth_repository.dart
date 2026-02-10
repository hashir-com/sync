import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sync_event/core/error/exceptions.dart';
import 'package:sync_event/core/error/failures.dart';
import 'package:sync_event/core/network/network_info.dart';
import 'package:sync_event/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:sync_event/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sync_event/features/auth/data/models/user_model.dart';
import 'package:sync_event/features/auth/domain/entities/user_entity.dart';
import 'package:sync_event/features/auth/domain/repo/auth_repo.dart';
import 'package:sync_event/core/services/fcm_token_service.dart';


class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail(
    String email,
    String password,
    String name,
    String? imagePath,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signUpWithEmail(email, password);
        if (user != null) {
          await remoteDataSource.updateUserName(name);

          String? imageUrl;
          if (imagePath != null) {
            final file = File(imagePath);
            imageUrl = await remoteDataSource.uploadProfileImage(
              file,
              user.uid,
            );
            await remoteDataSource.updateProfilePhoto(imageUrl);
          }

          await firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email,
            'name': name,
            'image': imageUrl,
            'nameLower': name.toLowerCase(), 
            'emailLower': email.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          final userEntity = UserModel.fromFirebase(user);
          await localDataSource.cacheUserData(userEntity.toJson().toString());
          await FcmTokenService.syncToken();

          return Right(userEntity);
        }
        return const Left(ServerFailure(message: 'Failed to create user'));
      } on FirebaseAuthException catch (e) {
        return Left(AuthFailure(message: _mapFirebaseAuthException(e)));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnknownFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail(
    String email,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.loginWithEmail(email, password);
        if (user != null) {
          final userEntity = UserModel.fromFirebase(user);
          await localDataSource.cacheUserData(userEntity.toJson().toString());
          await FcmTokenService.syncToken();
          return Right(userEntity);
        }
        return const Left(AuthFailure(message: 'Login failed'));
      } on FirebaseAuthException catch (e) {
        return Left(AuthFailure(message: _mapFirebaseAuthException(e)));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnknownFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendPasswordResetEmail(email);
        return const Right(null);
      } on FirebaseAuthException catch (e) {
        return Left(AuthFailure(message: _mapFirebaseAuthException(e)));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnknownFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle(
    bool forceAccountChooser,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (forceAccountChooser) {
          await googleSignIn
              .signOut(); // Forces account chooser on next sign-in
        }

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return const Left(AuthFailure(message: 'Google Sign-In cancelled'));
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          // Check if user exists in Firestore; create if not
          final userDoc = await firestore
              .collection('users')
              .doc(user.uid)
              .get();
          if (!userDoc.exists) {
            await firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'name': user.displayName ?? 'Anonymous',
              'image': user.photoURL,

              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          final userEntity = UserModel.fromFirebase(user);
          await localDataSource.cacheUserData(userEntity.toJson().toString());
          await FcmTokenService.syncToken();
          return Right(userEntity);
        }

        return const Left(AuthFailure(message: 'Google Sign-In failed'));
      } on FirebaseAuthException catch (e) {
        return Left(AuthFailure(message: _mapFirebaseAuthException(e)));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnknownFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyPhoneNumber(
    String phoneNumber,
    Function(String, int?) codeSent,
    Function(String) codeAutoRetrievalTimeout,
    Function(UserEntity) verificationCompleted,
    Function(String) verificationFailed,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyPhoneNumber(
          phoneNumber,
          codeSent,
          codeAutoRetrievalTimeout,
          (user) async {
            final userEntity = UserModel.fromFirebase(user);
            await localDataSource.cacheUserData(userEntity.toJson().toString());
            await FcmTokenService.syncToken();
            verificationCompleted(userEntity);
          },
          verificationFailed,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnknownFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp(String otp) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.verifyOtp(otp);
        if (user != null) {
          final userEntity = UserModel.fromFirebase(user);
          await localDataSource.cacheUserData(userEntity.toJson().toString());
          await FcmTokenService.syncToken();
          return Right(userEntity);
        }
        return const Left(AuthFailure(message: 'OTP verification failed'));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnknownFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await FcmTokenService.clearToken();
      await remoteDataSource.signOut();
      await localDataSource.clearUserData();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  

  @override
  Stream<Either<Failure, UserEntity?>> get authStateChanges {
    return FirebaseAuth.instance
        .authStateChanges()
        .map((user) {
          if (user != null) {
            return Right<Failure, UserEntity?>(UserModel.fromFirebase(user));
          } else {
            return const Right<Failure, UserEntity?>(null);
          }
        })
        .handleError((error) {
          return Left(UnknownFailure(message: error.toString()));
        });
  }

  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed: ${e.message ?? "An error occurred"}';
    }
  }
}
