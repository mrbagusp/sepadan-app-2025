// ============================================================
// 📁 lib/services/notification_service.dart
// ✅ FIXED: Token saved after auth, token refresh handled
// ============================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // ✅ Singleton to prevent multiple inits
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  Future<void> init(BuildContext context) async {
    // ✅ Prevent duplicate initialization
    if (_isInitialized) return;
    _isInitialized = true;

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // ✅ Get and save token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // ✅ Listen for token refresh (tokens can change!)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed');
        _saveTokenToFirestore(newToken);
      });
    }

    // ✅ Listen for auth state changes - save token after login
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        // User just logged in, save token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('🔑 User logged in, saving FCM token');
          await _saveTokenToFirestore(token);
        }
      }
    });

    // Handle background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(context, message);
    });

    // Handle terminated state notification tap
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(context, initialMessage);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification!.title ?? 'Notifikasi Baru'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () => _handleNotificationClick(context, message),
            ),
          ),
        );
      }
    });

    debugPrint('✅ NotificationService initialized');
  }

  void _handleNotificationClick(BuildContext context, RemoteMessage message) {
    if (message.data['type'] == 'daily_devo' || message.data['type'] == 'daily_devotional') {
      Navigator.pushNamed(context, '/explore/daily-devo');
    } else if (message.data['type'] == 'new_match') {
      Navigator.pushNamed(context, '/chat');
    } else if (message.data['type'] == 'new_message') {
      Navigator.pushNamed(context, '/chat');
    }
  }

  // ✅ Save token - with retry if user not logged in yet
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⏳ User not logged in yet, token will be saved after login');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ FCM token saved for user ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  Future<void> updateNotificationSettings({
    required bool dailyDevo,
    required bool newMatch,
    required bool newMessage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'notificationSettings': {
          'dailyDevo': dailyDevo,
          'newMatch': newMatch,
          'newMessage': newMessage,
        }
      }, SetOptions(merge: true));
    }
  }
}