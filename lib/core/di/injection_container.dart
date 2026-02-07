import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'package:sync_event/core/network/network_info.dart';

// Auth
import 'package:sync_event/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:sync_event/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sync_event/features/auth/data/repositories/auth_repository.dart';
import 'package:sync_event/features/auth/domain/repo/auth_repo.dart';
import 'package:sync_event/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:sync_event/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:sync_event/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:sync_event/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:sync_event/features/auth/domain/usecases/signup_with_email_usecase.dart';
import 'package:sync_event/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:sync_event/features/auth/domain/usecases/verify_phone_number_usecase.dart';

// Bookings
import 'package:sync_event/features/bookings/data/datasources/booking_remote_datasource.dart' as booking_datasource;
import 'package:sync_event/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:sync_event/features/bookings/domain/repositories/booking_repositories.dart';
import 'package:sync_event/features/bookings/domain/usecases/book_tickets_usecase.dart';
import 'package:sync_event/features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'package:sync_event/features/bookings/domain/usecases/get_booking_usecase.dart';
import 'package:sync_event/features/bookings/domain/usecases/get_user_bookings_usecase.dart';
import 'package:sync_event/features/bookings/domain/usecases/process_refund_usecase.dart';
import 'package:sync_event/features/bookings/domain/usecases/refund_to_razorpay_usecase.dart';
import 'package:sync_event/features/bookings/domain/usecases/request_refund_usecase.dart';

// Events
import 'package:sync_event/features/events/data/datasources/event_local_datasource.dart';
import 'package:sync_event/features/events/data/datasources/event_remote_datasource.dart';
import 'package:sync_event/features/events/data/repositories/event_repository_impl.dart';
import 'package:sync_event/features/events/domain/repositories/event_repository.dart';
import 'package:sync_event/features/events/domain/usecases/create_event_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/approved_event_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/get_user_events_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/join_event_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/update_event_usecase.dart';
import 'package:sync_event/features/events/domain/usecases/delete_event_usecase.dart';

// Profile
import 'package:sync_event/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:sync_event/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:sync_event/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:sync_event/features/profile/domain/repositories/profile_repository.dart';
import 'package:sync_event/features/profile/domain/usecases/create_user_usecase.dart';
import 'package:sync_event/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:sync_event/features/profile/domain/usecases/update_user_profile_usecase.dart';

// Wallet
import 'package:sync_event/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:sync_event/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:sync_event/features/wallet/domain/repositories/wallet_repositories.dart';
import 'package:sync_event/features/wallet/domain/usecases/update_wallet_usecase.dart';
import 'package:sync_event/features/wallet/domain/usecases/get_wallet_usecase.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  if (kDebugMode) {
    print('Injection: Registering SharedPreferences');
  }
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  final firebaseAuth = FirebaseAuth.instance;
  print('Injection: Registering FirebaseAuth instance: $firebaseAuth');
  sl.registerLazySingleton<FirebaseAuth>(() => firebaseAuth);

  final firebaseFirestore = FirebaseFirestore.instance;
  print('Injection: Registering FirebaseFirestore instance: $firebaseFirestore');
  sl.registerLazySingleton<FirebaseFirestore>(() => firebaseFirestore);

  final firebaseStorage = FirebaseStorage.instance;
  print('Injection: Registering FirebaseStorage instance: $firebaseStorage');
  sl.registerLazySingleton<FirebaseStorage>(() => firebaseStorage);

  // Core
  print('Injection: Registering NetworkInfo');
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // Features
  print('Injection: Initializing Auth feature');
  _initAuth();
  print('Injection: Initializing Profile feature');
  _initProfile();
  print('Injection: Initializing Events feature');
  _initEvents();
  print('Injection: Initializing Booking feature');
  _initBooking();
  print('Injection: Initializing Wallet feature');
  _initWallet();
}

void _initAuth() {
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firebaseFirestore: sl<FirebaseFirestore>(),
      firebaseStorage: sl<FirebaseStorage>(),
    ),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<LoginWithEmailUseCase>(
    () => LoginWithEmailUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignUpWithEmailUseCase>(
    () => SignUpWithEmailUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignInWithGoogleUseCase>(
    () => SignInWithGoogleUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<VerifyPhoneNumberUseCase>(
    () => VerifyPhoneNumberUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<VerifyOtpUseCase>(
    () => VerifyOtpUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SendPasswordResetUseCase>(
    () => SendPasswordResetUseCase(sl<AuthRepository>()),
  );
}

void _initProfile() {
  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(
      firebaseFirestore: sl<FirebaseFirestore>(),
      firebaseStorage: sl<FirebaseStorage>(),
    ),
  );
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl<ProfileRemoteDataSource>(),
      localDataSource: sl<ProfileLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<GetUserProfileUseCase>(
    () => GetUserProfileUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<UpdateUserProfileUseCase>(
    () => UpdateUserProfileUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<CreateUserProfileUseCase>(
  () => CreateUserProfileUseCase(sl<ProfileRepository>()),
);
}

void _initEvents() {
  // Data sources
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(
      firebaseFirestore: sl<FirebaseFirestore>(),
      firebaseStorage: sl<FirebaseStorage>(),
    ),
  );
  sl.registerLazySingleton<EventLocalDataSource>(
    () => EventLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
  );

  // Repository
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(
      remoteDataSource: sl<EventRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      firebaseFirestore: sl<FirebaseFirestore>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<CreateEventUseCase>(
    () => CreateEventUseCase(sl<EventRepository>()),
  );
  sl.registerLazySingleton<GetApprovedEventsUseCase>(
    () => GetApprovedEventsUseCase(sl<EventRepository>()),
  );
  sl.registerLazySingleton(() => GetUserEventsUseCase(sl<EventRepository>()));
  sl.registerLazySingleton(() => JoinEventUseCase(sl<EventRepository>()));
  sl.registerLazySingleton(() => UpdateEventUseCase(sl<EventRepository>()));
  sl.registerLazySingleton(() => DeleteEventUseCase(sl<EventRepository>()));
}

void _initBooking() {
  // Data sources
  sl.registerLazySingleton<booking_datasource.BookingRemoteDataSource>(
    () => booking_datasource.BookingRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<BookingRepository>(
  () => BookingRepositoryImpl(
    remoteDataSource: sl<booking_datasource.BookingRemoteDataSource>(),
    walletRemoteDataSource: sl<WalletRemoteDataSource>(),
    networkInfo: sl<NetworkInfo>(),
    eventRepository: sl<EventRepository>(),
    auth: sl<FirebaseAuth>(),
  ),
);

  // Use cases
  sl.registerLazySingleton<BookTicketUseCase>(
    () => BookTicketUseCase(sl<BookingRepository>(), sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<CancelBookingUseCase>(
    () => CancelBookingUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<GetBookingUseCase>(
    () => GetBookingUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<RefundToRazorpayUseCase>(
    () => RefundToRazorpayUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<GetUserBookingsUseCase>(
    () => GetUserBookingsUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<RequestRefundUseCase>(
    () => RequestRefundUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<ProcessRefundUseCase>(
    () => ProcessRefundUseCase(sl<BookingRepository>()),
  );
}

void _initWallet() {
  // Data sources
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(
      remoteDataSource: sl<WalletRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<UpdateWalletUseCase>(
    () => UpdateWalletUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<GetWalletUseCase>(
    () => GetWalletUseCase(sl<WalletRepository>()),
  );
}