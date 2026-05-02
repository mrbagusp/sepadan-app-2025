// ============================================================
// 📁 lib/screens/match/match_notifier.dart
// ✅ FIXED: Only show popup for truly NEW matches
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/match_service.dart';
import 'package:sepadan/services/ad_service.dart';
import 'package:sepadan/services/premium_service.dart';
import 'package:sepadan/services/profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchNotifier extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final AdService _adService = AdService();
  final PremiumService _premiumService = PremiumService();
  final ProfileService _profileService = ProfileService();

  List<UserProfile> _profiles = [];
  List<UserProfile> get profiles => _profiles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasNewMatch = false;
  bool get hasNewMatch => _hasNewMatch;

  UserProfile? _latestMatchedUser;
  UserProfile? get latestMatchedUser => _latestMatchedUser;

  String? _latestMatchId;
  String? get latestMatchId => _latestMatchId;

  StreamSubscription<QuerySnapshot>? _matchListener;
  bool _isPremium = false;

  // 🔥 Track seen matches and listener initialization
  Set<String> _seenMatchIds = {};
  bool _isListenerInitialized = false;
  DateTime? _listenerStartTime;

  MatchNotifier() {
    _initializeAndListen();
    _adService.loadInterstitialAd();
    _initPremiumStatus();
  }

  void _initPremiumStatus() {
    _premiumService.getPremiumStatus().listen((status) {
      _isPremium = status;
    });
  }

  @override
  void dispose() {
    _matchListener?.cancel();
    _adService.dispose();
    super.dispose();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchPotentialMatches({bool clearExisting = false}) async {
    if (clearExisting) {
      _setLoading(true);
      _profiles = [];
    }

    try {
      final newProfiles = await _matchService.getPotentialMatches();
      final existingIds = _profiles.map((p) => p.uid).toSet();
      final filteredNew = newProfiles.where((p) => !existingIds.contains(p.uid)).toList();

      _profiles.addAll(filteredNew);
      notifyListeners();
    } catch (e) {
      debugPrint("MatchNotifier Error: $e");
    } finally {
      if (clearExisting) _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // 🔥 INITIALIZE: Load seen matches, then start listener
  // ─────────────────────────────────────────────────────────
  Future<void> _initializeAndListen() async {
    await _loadSeenMatches();
    _listenerStartTime = DateTime.now();
    _listenToNewMatches();
  }

  // ─────────────────────────────────────────────────────────
  // 🔥 LOAD SEEN MATCH IDs from SharedPreferences
  // ─────────────────────────────────────────────────────────
  Future<void> _loadSeenMatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final seenList = prefs.getStringList('seen_matches_$uid') ?? [];
      _seenMatchIds = seenList.toSet();
      debugPrint('📋 Loaded ${_seenMatchIds.length} seen matches');
    } catch (e) {
      debugPrint('Error loading seen matches: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // 🔥 SAVE SEEN MATCH ID to SharedPreferences
  // ─────────────────────────────────────────────────────────
  Future<void> _markMatchAsSeen(String matchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      _seenMatchIds.add(matchId);
      await prefs.setStringList('seen_matches_$uid', _seenMatchIds.toList());
      debugPrint('✅ Marked match as seen: $matchId');
    } catch (e) {
      debugPrint('Error saving seen match: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // 🔥 LISTEN TO NEW MATCHES - Only trigger for unseen matches
  // ─────────────────────────────────────────────────────────
  void _listenToNewMatches() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _matchListener = FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(5) // Check last 5 matches
        .snapshots()
        .listen((snapshot) async {

      for (var change in snapshot.docChanges) {
        final matchId = change.doc.id;
        final data = change.doc.data() as Map<String, dynamic>?;

        if (data == null) continue;

        // 🔥 Skip if already seen
        if (_seenMatchIds.contains(matchId)) {
          debugPrint('⏭️ Skipping already seen match: $matchId');
          continue;
        }

        // 🔥 For initial load, check if match is recent (within last 5 minutes)
        // This handles background matches that happened while app was closed
        if (!_isListenerInitialized) {
          final createdAt = data['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final matchTime = createdAt.toDate();
            final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

            // If match is older than 5 minutes and this is initial load, mark as seen and skip
            if (matchTime.isBefore(fiveMinutesAgo)) {
              await _markMatchAsSeen(matchId);
              debugPrint('⏭️ Old match on initial load, marking as seen: $matchId');
              continue;
            }
          }
        }

        // 🔥 This is a NEW match - show popup!
        final otherUserId = data['user1Id'] == uid ? data['user2Id'] : data['user1Id'];
        final otherUserProfile = await _profileService.getProfileByUid(otherUserId);

        if (otherUserProfile != null) {
          _hasNewMatch = true;
          _latestMatchId = matchId;
          _latestMatchedUser = otherUserProfile;

          debugPrint('🎉 NEW MATCH DETECTED: ${_latestMatchedUser?.name}');
          notifyListeners();
        }
      }

      // Mark listener as initialized after first snapshot
      _isListenerInitialized = true;
    });
  }

  // ─────────────────────────────────────────────────────────
  // 🔥 RESET: Called after popup is dismissed
  // ─────────────────────────────────────────────────────────
  void resetMatchNotification() {
    // Mark current match as seen before resetting
    if (_latestMatchId != null) {
      _markMatchAsSeen(_latestMatchId!);
    }

    _hasNewMatch = false;
    _latestMatchedUser = null;
    _latestMatchId = null;
    notifyListeners();
  }

  Future<void> swipe(int index, bool didLike) async {
    if (index >= _profiles.length) return;

    final userToSwipe = _profiles[index];
    _adService.showInterstitialAdIfEligible(_isPremium);

    if (didLike) {
      try {
        await _matchService.likeUser(userToSwipe.uid);
      } catch (e) {
        debugPrint("Swipe Like Error: $e");
      }
    } else {
      await _matchService.passUser(userToSwipe.uid);
    }

    if (index >= _profiles.length - 3 && _profiles.length > 0) {
      fetchPotentialMatches();
    }
  }
}