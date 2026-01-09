
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sepadan/services/profile_service.dart';
import 'dart:developer' as developer;

// Handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You can process the message here, e.g., show a local notification
  developer.log('Handling a background message: \${message.messageId}');
}


class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ProfileService _profileService = ProfileService();

  Future<void> initialize() async {
    // Request permission from the user
    await requestPermission();

    // Get the FCM token
    final String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await saveTokenToProfile(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(saveTokenToProfile);

    // Set up message handlers
    _setupMessageHandlers();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    developer.log('User granted permission: \${settings.authorizationStatus}');
  }

  Future<void> saveTokenToProfile(String token) async {
    try {
      final userProfile = await _profileService.getUserProfile();
      if (userProfile != null && userProfile.fcmToken != token) {
         // Create a new UserProfile object with the updated token
        final updatedProfile = userProfile.copyWith(fcmToken: token);
        await _profileService.updateUserProfile(updatedProfile);
        developer.log('FCM Token saved to profile.');
      }
    } catch (e) {
      developer.log('Error saving FCM token: \$e', name: 'notification.service');
    }
  }

  void _setupMessageHandlers() {
    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Got a message whilst in the foreground!');
      developer.log('Message data: \${message.data}');

      if (message.notification != null) {
        developer.log('Message also contained a notification: \${message.notification}');
        // Here you would typically show a local notification,
        // as foreground messages don't show a system notification by default.
      }
    });

    // Handle messages when the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('App opened from terminated state by message: \${message.data}');
        // Navigate to a specific screen if needed
      }
    });

    // Handle messages when the app is in the background and the user taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('A new onMessageOpenedApp event was published!');
      developer.log('Message data: \${message.data}');
      // Navigate to a specific screen if needed
    });

     // Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
