import 'package:flutter/material.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/match_service.dart';

class MatchNotifier extends ChangeNotifier {
  final MatchService _matchService = MatchService();

  List<UserProfile> _profiles = [];
  List<UserProfile> get profiles => _profiles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isMutualMatch = false;
  bool get isMutualMatch => _isMutualMatch;

  UserProfile? get matchedUser => _matchedUser;
  UserProfile? _matchedUser;
  
  String? _matchId;
  String? get matchId => _matchId;


  MatchNotifier();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchPotentialMatches() async {
    _setLoading(true);
    try {
      _profiles = await _matchService.getPotentialMatches();
    } catch (e) {
      print(e);
    } finally {
      _setLoading(false);
    }
  }

  void removeTopProfile() {
    if (_profiles.isNotEmpty) {
      _profiles.removeAt(0);
      notifyListeners();
    }
  }
  
  void resetMutualMatch() {
    _isMutualMatch = false;
    _matchedUser = null;
    _matchId = null;
    notifyListeners();
  }


  Future<void> swipe(int index, bool didLike) async {
    if (index >= _profiles.length) return;

    final userToSwipe = _profiles[index];
    removeTopProfile();

    if (didLike) {
      final (mutual, matchId) = await _matchService.likeUser(userToSwipe.uid);
      if (mutual) {
        _isMutualMatch = true;
        _matchedUser = userToSwipe;
        _matchId = matchId;
        notifyListeners();
      }
    } else {
      await _matchService.passUser(userToSwipe.uid);
    }

    if (_profiles.length < 3) {
      fetchPotentialMatches();
    }
  }
}
