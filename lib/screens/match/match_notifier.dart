import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/match_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchNotifier extends ChangeNotifier {
  final MatchService _matchService = MatchService();

  List<UserProfile> _profiles = [];
  List<UserProfile> get profiles => _profiles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Flag untuk notifikasi "New Match" (update via listener)
  bool _hasNewMatch = false;
  bool get hasNewMatch => _hasNewMatch;

  // Data match terbaru (opsional untuk tampilkan popup)
  UserProfile? _latestMatchedUser;
  UserProfile? get latestMatchedUser => _latestMatchedUser;

  String? _latestMatchId;
  String? get latestMatchId => _latestMatchId;

  StreamSubscription<QuerySnapshot>? _matchListener;

  MatchNotifier() {
    _listenToNewMatches();
  }

  @override
  void dispose() {
    _matchListener?.cancel();
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

  // Mendengarkan collection matches secara real-time
  void _listenToNewMatches() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _matchListener = FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            // Kita terdeteksi match baru dari Cloud Function!
            _hasNewMatch = true;
            _latestMatchId = change.doc.id;

            // Nama lawan bicara (ambil dari doc matches)
            final String otherName = data['user1Id'] == uid ? data['user2Name'] : data['user1Name'];
            final String otherPhoto = data['user1Id'] == uid ? data['user2PhotoUrl'] : data['user1PhotoUrl'];

            _latestMatchedUser = UserProfile(
              uid: data['user1Id'] == uid ? data['user2Id'] : data['user1Id'],
              name: otherName,
              email: '',
              photos: [otherPhoto],
              createdAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
            );

            notifyListeners();
          }
        }
      }
    }, onError: (e) {
      debugPrint("Match listener error: $e");
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

    if (didLike) {
      try {
        await _matchService.likeUser(userToSwipe.uid);
        // Tidak perlu cek match di sini lagi
        // UI akan update otomatis via listener _listenToNewMatches()
      } catch (e) {
        debugPrint("Swipe Like Error: $e");
      }
    } else {
      await _matchService.passUser(userToSwipe.uid);
    }

    // Load more profiles jika mendekati akhir list
    if (index >= _profiles.length - 3 && _profiles.length > 0) {
      fetchPotentialMatches();
    }
  }
}