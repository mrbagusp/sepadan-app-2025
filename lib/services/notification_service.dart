import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init(BuildContext context) async {
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
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _saveTokenToFirestore(token);
      }
    }

    // Handle background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(context, message);
    });

    // Handle terminated state notification tap
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(context, initialMessage);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show local notification or snackbar if app is in foreground
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
  }

  void _handleNotificationClick(BuildContext context, RemoteMessage message) {
    if (message.data['type'] == 'daily_devo') {
      // Navigasi ke Daily Devo Screen
      Navigator.pushNamed(context, '/explore/daily-devo');
    } else if (message.data['type'] == 'new_match') {
      Navigator.pushNamed(context, '/chat');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
