import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/auth_service.dart';
import 'package:sepadan/services/user_service.dart'; // Import UserService
import 'package:sepadan/services/firestore_service.dart'; // Import FirestoreService
import 'package:sepadan/services/notification_service.dart';
import 'package:sepadan/core/theme.dart';
import 'package:sepadan/core/app_router.dart';
import 'package:sepadan/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.init();

  final authService = AuthService();
  final userService = UserService(); // Create instance of UserService
  final firestoreService = FirestoreService(); // Create instance of FirestoreService

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        
        // Provide the AuthService
        Provider<AuthService>.value(value: authService),
        
        // Provide the FirestoreService
        Provider<FirestoreService>.value(value: firestoreService),

        // Stream the UserProfile using the new UserService
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
