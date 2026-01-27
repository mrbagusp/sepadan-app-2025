import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/screens/admin/admin_dashboard.dart';
import 'package:sepadan/screens/chat/chat_screen.dart';
import 'package:sepadan/screens/premium/premium_upsell_screen.dart';
import 'package:sepadan/screens/premium/payment_screen.dart';
import 'package:sepadan/services/profile_service.dart';
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

    if (!loggedIn) {
      return isAuthRoute ? null : '/login';
    }

    try {
      // Cek profil dengan aman
      final userProfile = await ProfileService().getUserProfile().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
      
      final bool profileComplete = userProfile != null &&
          userProfile.name.isNotEmpty &&
          userProfile.photos.isNotEmpty &&
          userProfile.age > 0;

      final onProfileScreen = state.matchedLocation == '/profile';

      if (!profileComplete && !onProfileScreen) {
        return '/profile';
      }

      if (profileComplete && isAuthRoute) {
        return '/main';
      }
    } catch (e) {
      debugPrint("Router Redirect Error: $e");
      // Jika error Firestore (Permission Denied), biarkan user di halaman saat ini
      // agar tidak terjadi loop crash.
    }

    return null;
  },
);
