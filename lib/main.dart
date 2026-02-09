import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sync_event/core/constants/app_theme.dart';
import 'package:sync_event/core/di/injection_container.dart';
import 'package:sync_event/core/routes/routes.dart';
import 'package:sync_event/core/services/notification_service.dart';
import 'package:sync_event/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await configureDependencies();
  await NotificationService.init();
  FirebaseMessaging.onBackgroundMessage(
  firebaseMessagingBackgroundHandler,
);
   if (!kIsWeb) {
    await FirebaseInAppMessaging.instance.setMessagesSuppressed(false);
  }
  final initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

if (initialMessage != null) {
  final chatId = initialMessage.data['chatId'];
  if (chatId != null) {
    appRouter.go('/chat/$chatId');
  }
}

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Sync Event',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You can log, analytics, etc.
  print('Background message: ${message.messageId}');
}

Future<void> enableAnalyticsDebug() async {
  if (kDebugMode) {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  }
}