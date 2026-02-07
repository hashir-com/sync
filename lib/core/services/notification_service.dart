import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.max,
  );

  /// Call this ONCE from main()
  static Future<void> init() async {
    // Android 13+ permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create notification channel (Android REQUIRED)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    // Token refresh (VERY IMPORTANT)
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);
  }

  // HANDLERS

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data['route'], // optional
    );
  }

  static void _handleMessageOpen(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) {
      // TODO: navigate using navigatorKey
      print('Notification opened → route: $route');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // TODO: navigate using navigatorKey
      print('Notification tapped → payload: $payload');
    }
  }

  static Future<void> _handleTokenRefresh(String newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {'fcmToken': newToken},
      SetOptions(merge: true),
    );
  }

  // UTIL
 

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
