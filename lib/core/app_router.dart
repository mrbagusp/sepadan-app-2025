import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/screens/admin/admin_dashboard.dart';
import 'package:sepadan/screens/chat/chat_screen.dart';
import 'package:sepadan/screens/premium/premium_upsell_screen.dart';
import 'package:sepadan/screens/premium/payment_screen.dart';
import 'package:sepadan/services/auth_service.dart';
import '../screens/main_screen.dart';
import '../screens/splash_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/premium', builder: (context, state) => const PremiumUpsellScreen(featureName: 'Premium Features')),
    GoRoute(path: '/payment', builder: (context, state) => const PaymentScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboard()),
    GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final matchId = extra['matchId'] as String;
          final otherUser = extra['otherUser'] as UserProfile;
          return ChatScreen(matchId: matchId, otherUser: otherUser);
        }),
  ],
  redirect: (context, state) async {
    final authService = AuthService();
    final user = authService.currentUser;
    final loggedIn = user != null;
    
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    final isSplash = state.matchedLocation == '/';

    // 🔥 OPTIMASI: Jangan panggil Firestore di sini agar booting aplikasi super cepat.
    // Cukup cek status login dasar.
    if (!loggedIn) {
      if (isSplash || isAuthRoute) return null;
      return '/login';
    }

    if (loggedIn && (isSplash || isAuthRoute)) {
      return '/main';
    }

    return null;
  },
);
