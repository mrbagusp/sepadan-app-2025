// ============================================================
// 📁 lib/core/app_router.dart
// ✅ FIXED: Smart routing - returning users go directly to main
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../screens/profile/profile_create_screen.dart'; // NEW: Onboarding screen
import '../screens/settings/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// 🔥 KEY untuk SharedPreferences
const String _kProfileCompleteKey = 'profile_complete_v1';
const String _kLastCheckedUidKey = 'last_checked_uid';

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    // 🔥 NEW: Dedicated onboarding screen for NEW users
    GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileCreateScreen()),
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
      },
    ),
  ],
  redirect: (context, state) async {
    final authService = AuthService();
    final user = authService.currentUser;
    final loggedIn = user != null;

    final isAuthRoute = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register';
    final isSplash = state.matchedLocation == '/';
    final isProfileSetup = state.matchedLocation == '/profile-setup';

    // ─────────────────────────────────────────────────────────
    // 1. NOT LOGGED IN → Go to login (except splash/auth routes)
    // ─────────────────────────────────────────────────────────
    if (!loggedIn) {
      if (isSplash || isAuthRoute) return null;
      return '/login';
    }

    // ─────────────────────────────────────────────────────────
    // 2. LOGGED IN → Smart profile check
    // ─────────────────────────────────────────────────────────
    
    // 🔥 STEP A: Quick sync check from SharedPreferences (INSTANT)
    final prefs = await SharedPreferences.getInstance();
    final cachedUid = prefs.getString(_kLastCheckedUidKey);
    final cachedComplete = prefs.getBool(_kProfileCompleteKey) ?? false;
    
    // If same user and we cached "complete" → go directly to main
    if (cachedUid == user.uid && cachedComplete) {
      if (isAuthRoute || isSplash) {
        return '/main';
      }
      return null; // Allow navigation to proceed
    }

    // 🔥 STEP B: Async Firestore check (only for new/different user or first time)
    try {
      final userProfile = await ProfileService().getUserProfile().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      final bool profileComplete = userProfile != null &&
          userProfile.name.isNotEmpty &&
          userProfile.photos.isNotEmpty &&
          userProfile.age > 0 &&
          userProfile.gender.isNotEmpty;

      // 🔥 STEP C: Cache the result
      await prefs.setString(_kLastCheckedUidKey, user.uid);
      await prefs.setBool(_kProfileCompleteKey, profileComplete);

      // 🔥 STEP D: Route based on profile status
      if (!profileComplete) {
        // Profile incomplete → go to setup (NOT regular profile screen)
        if (!isProfileSetup && state.matchedLocation != '/profile') {
          return '/profile-setup';
        }
        return null;
      }

      // Profile complete → go to main
      if (isAuthRoute || isSplash) {
        return '/main';
      }

    } catch (e) {
      debugPrint("Router Redirect Error: $e");
      // On error, if we have cached complete status, trust it
      if (cachedComplete && cachedUid == user.uid) {
        if (isAuthRoute || isSplash) return '/main';
      }
      // Otherwise, allow navigation to continue
    }

    return null;
  },
);

// ============================================================
// 🔧 UTILITY: Call this after profile is saved successfully
// ============================================================
Future<void> markProfileComplete() async {
  final prefs = await SharedPreferences.getInstance();
  final user = AuthService().currentUser;
  if (user != null) {
    await prefs.setString(_kLastCheckedUidKey, user.uid);
    await prefs.setBool(_kProfileCompleteKey, true);
  }
}

// 🔧 UTILITY: Call this on logout to clear cache
Future<void> clearProfileCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kLastCheckedUidKey);
  await prefs.remove(_kProfileCompleteKey);
}
