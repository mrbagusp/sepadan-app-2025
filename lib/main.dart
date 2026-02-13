import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/auth_service.dart';
import 'package:sepadan/services/user_service.dart';
import 'package:sepadan/services/firestore_service.dart';
import 'package:sepadan/services/notification_service.dart';
import 'package:sepadan/services/premium_service.dart';
import 'package:sepadan/notifiers/premium_notifier.dart';
import 'package:sepadan/screens/match/match_notifier.dart';
import 'package:sepadan/core/theme.dart';
import 'package:sepadan/core/app_router.dart';
import 'package:sepadan/firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 Memulai inisialisasi Firebase...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('✅ Firebase berhasil diinisialisasi!');
    debugPrint(
        'Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');

    // 🔥 AKTIFKAN APP CHECK (WAJIB)
    await FirebaseAppCheck.instance.activate(
      androidProvider:
      kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: AppleProvider.deviceCheck,
    );

    debugPrint('✅ Firebase App Check aktif!');
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR saat inisialisasi Firebase / App Check');
    debugPrint('Error: $e');
    debugPrint('Stacktrace: $stackTrace');
  }

  // 🔔 Init Notification
  final notificationService = NotificationService();
  await notificationService.init();

  final authService = AuthService();
  final userService = UserService();
  final firestoreService = FirestoreService();
  final premiumService = PremiumService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => PremiumNotifier()),
        ChangeNotifierProvider(create: (context) => MatchNotifier()),
        Provider<AuthService>.value(value: authService),
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<PremiumService>.value(value: premiumService),
        StreamProvider<UserProfile?>.value(
          value: userService.getUserProfile(),
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'SEPADAN',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
