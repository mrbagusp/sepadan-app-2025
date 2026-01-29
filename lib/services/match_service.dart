import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/models/user_preferences.dart';
import 'package:intl/intl.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // 🔥 Fungsi untuk mengecek limit swipe harian
  Future<bool> canSwipe() async {
    if (_currentUserId == null) return false;

    final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
    final bool isPremium = userDoc.data()?['isPremium'] == true;
    final bool isAdmin = userDoc.data()?['isAdmin'] == true;

    // Admin dan Premium bebas swipe
    if (isPremium || isAdmin) return true;

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final statsDoc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('daily_stats')
        .doc(today)
        .get();

    if (!statsDoc.exists) return true;

    final int swipeCount = statsDoc.data()?['swipeCount'] ?? 0;
    return swipeCount < 50; // Limit 50 swipe per hari untuk user biasa
  }

  // 🔥 Fungsi untuk mencatat swipe
  Future<void> _incrementSwipeCount() async {
    if (_currentUserId == null) return;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('daily_stats')
        .doc(today);

    await docRef.set({
      'swipeCount': FieldValue.increment(1),
      'lastSwipe': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<UserProfile>> getPotentialMatches() async {
    if (_currentUserId == null) return [];

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final bool isAdmin = userDoc.data()?['isAdmin'] == true;

      final profileDoc = await _firestore.collection('profiles').doc(_currentUserId).get();
      final prefsDoc = await _firestore.collection('preferences').doc(_currentUserId).get();
      
      final currentUserProfile = profileDoc.exists ? UserProfile.fromFirestore(profileDoc) : null;
      final preferences = prefsDoc.exists ? UserPreferences.fromFirestore(prefsDoc) : UserPreferences.defaultValues();

      final excludedUids = await _getExcludedUids();
      
      Query query = _firestore.collection('profiles');
      
      String targetGender = preferences.preferredGender.toLowerCase();
      if (targetGender == 'men') targetGender = 'male';
      if (targetGender == 'women') targetGender = 'female';

      if (targetGender != 'both' && targetGender != 'everyone') {
        query = query.where('gender', isEqualTo: targetGender);
      }

      final allProfilesSnapshot = await query.get();

      final potentialMatches = allProfilesSnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((profile) {
        if (profile.uid == _currentUserId) return false;
        if (excludedUids.contains(profile.uid)) return false;

        if (isAdmin || profile.uid.contains('dummy')) return true;

        if (profile.age < preferences.ageMin || profile.age > preferences.ageMax) return false;

        if (currentUserProfile?.location != null && profile.location != null) {
          final distanceInKm = Geolocator.distanceBetween(
                currentUserProfile!.location!.latitude,
                currentUserProfile.location!.longitude,
                profile.location!.latitude,
                profile.location!.longitude,
              ) / 1000;
          return distanceInKm <= preferences.maxDistanceKm;
        }

        return true;
      }).toList();

      potentialMatches.shuffle();
      return potentialMatches;
    } catch (e) {
      debugPrint("MatchService Error: $e");
      return [];
    }
  }

  Future<Set<String>> _getExcludedUids() async {
    if (_currentUserId == null) return {};
    final likes = await _firestore.collection('likes').doc(_currentUserId).collection('likedUsers').get();
    final passes = await _firestore.collection('passes').doc(_currentUserId).collection('passedUsers').get();
    final matches = await _firestore.collection('matches').where('users', arrayContains: _currentUserId).get();

    final Set<String> ids = {};
    for (var doc in likes.docs) ids.add(doc.id);
    for (var doc in passes.docs) ids.add(doc.id);
    for (var doc in matches.docs) {
      final List<String> users = List<String>.from(doc.data()['users'] ?? []);
      ids.addAll(users);
    }
    return ids;
  }

  Future<(bool, String?)> likeUser(String likedUserId) async {
    if (_currentUserId == null) return (false, null);

    // Cek limit sebelum like
    if (!(await canSwipe())) {
      throw Exception("DAILY_LIMIT_REACHED");
    }

    await _firestore
        .collection('likes')
        .doc(_currentUserId)
        .collection('likedUsers')
        .doc(likedUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});

    await _incrementSwipeCount(); // Catat swipe berhasil

    final otherUserLike = await _firestore
        .collection('likes')
        .doc(likedUserId)
        .collection('likedUsers')
        .doc(_currentUserId)
        .get();

    if (otherUserLike.exists) {
      final List<String> pair = [_currentUserId!, likedUserId]..sort();
      final String matchId = pair.join('_');

      await _firestore.collection('matches').doc(matchId).set({
        'users': pair,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Kalian telah cocok! Silakan mulai menyapa.',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      
      return (true, matchId);
    }

    return (false, null);
  }

  Future<void> passUser(String passedUserId) async {
    if (_currentUserId == null) return;
    
    // Cek limit sebelum pass
    if (!(await canSwipe())) {
      throw Exception("DAILY_LIMIT_REACHED");
    }

    await _firestore
        .collection('passes')
        .doc(_currentUserId)
        .collection('passedUsers')
        .doc(passedUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});

    await _incrementSwipeCount(); // Catat swipe berhasil
  }
}
