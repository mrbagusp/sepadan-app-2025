import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/match_service.dart';
import 'package:sepadan/services/ad_service.dart';
import 'package:sepadan/services/premium_service.dart';
import 'package:sepadan/services/profile_service.dart'; // 🔥 Import ProfileService
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchNotifier extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final AdService _adService = AdService();
  final PremiumService _premiumService = PremiumService();
  final ProfileService _profileService = ProfileService(); // 🔥 Instance ProfileService

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

  MatchNotifier() {
    _listenToNewMatches();
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

  void _listenToNewMatches() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _matchListener = FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async { // 🔥 Tambahkan async di sini
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final otherUserId = data['user1Id'] == uid ? data['user2Id'] : data['user1Id'];
            
            // 🔥 AMBIL DATA PROFIL ASLI DARI FIRESTORE
            final otherUserProfile = await _profileService.getProfileByUid(otherUserId);
            
            if (otherUserProfile != null) {
              _hasNewMatch = true;
              _latestMatchId = change.doc.id;
              _latestMatchedUser = otherUserProfile;
              
              notifyListeners();
              debugPrint("NEW MATCH DETECTED: ${_latestMatchedUser?.name}");
            }
          }
        }
      }
    });
  }

  void resetMatchNotification() {
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
