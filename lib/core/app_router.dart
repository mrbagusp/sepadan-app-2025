import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/screens/admin/admin_screen.dart';
import 'package:sepadan/screens/admin/content_moderation_screen.dart';
import 'package:sepadan/screens/admin/daily_devo_management_screen.dart';
import 'package:sepadan/screens/admin/payment_gateway_settings_screen.dart';
import 'package:sepadan/screens/admin/user_management_screen.dart';
import 'package:sepadan/screens/chat/chat_screen.dart';
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
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
        routes: [
          GoRoute(
            path: 'content-moderation',
            builder: (context, state) => const ContentModerationScreen(),
          ),
          GoRoute(
            path: 'user-management',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: 'payment-gateway-settings',
            builder: (context, state) => const PaymentGatewaySettingsScreen(),
          ),
          GoRoute(
            path: 'daily-devo-management',
            builder: (context, state) => const DailyDevoManagementScreen(),
          ),
        ]),
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
    final loggedIn = authService.currentUser != null;
    final loggingIn =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!loggedIn) {
      return loggingIn ? null : '/login';
    }

    final user = await authService.getUser();
    final isAdmin = user?.role == 'admin';
    final toAdmin = state.matchedLocation?.startsWith('/admin') ?? false;

    if (toAdmin && !isAdmin) {
      return '/main';
    }

    // If logged in, check for profile completion
    final profileService = ProfileService();
    final userProfile = await profileService.getUserProfile();
    final profileComplete =
        userProfile != null &&
        userProfile.name.isNotEmpty &&
        userProfile.photos.isNotEmpty &&
        userProfile.age > 0;

    final onProfileScreen = state.matchedLocation == '/profile';

    // If trying to access login/register while logged in, redirect away
    if (loggingIn) {
      return profileComplete ? '/main' : '/profile';
    }

    // If profile is not complete, redirect to profile screen
    if (!profileComplete && !onProfileScreen) {
      return '/profile';
    }

    return null;
  },
);
