import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/models/user_preferences.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserId;

  MatchService() {
    _currentUserId = _auth.currentUser?.uid;
    _auth.authStateChanges().listen((user) => _currentUserId = user?.uid);
  }

  /// Mengecek apakah user masih boleh swipe hari ini
  Future<bool> canSwipe() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();

    // Premium atau admin boleh unlimited swipe
    if (userData?['isPremium'] == true || userData?['isAdmin'] == true) {
      return true;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final statsDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_stats')
        .doc(today)
        .get();

    final swipeCount = statsDoc.data()?['swipeCount'] as int? ?? 0;
    return swipeCount < 50;
  }

  /// Menambah hitungan swipe harian
  Future<void> _incrementSwipeCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_stats')
        .doc(today)
        .set(
      {
        'swipeCount': FieldValue.increment(1),
        'lastSwipe': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Mengambil daftar profil potensial untuk ditampilkan (explore/swipe)
  Future<List<UserProfile>> getPotentialMatches() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final profileDoc = await _firestore.collection('profiles').doc(uid).get();
      final prefsDoc = await _firestore.collection('preferences').doc(uid).get();

      final currentUserProfile = profileDoc.exists
          ? UserProfile.fromFirestore(profileDoc)
          : null;

      final preferences = prefsDoc.exists
          ? UserPreferences.fromFirestore(prefsDoc)
          : UserPreferences.defaultValues();

      final excludedUids = await _getExcludedUids();

      final allProfilesSnapshot = await _firestore.collection('profiles').get();

      final potentialMatches = allProfilesSnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((profile) {
        // Jangan tampilkan diri sendiri
        if (profile.uid == uid) return false;

        // Sudah di-like, di-pass, atau sudah match → skip
        if (excludedUids.contains(profile.uid)) return false;

        // Dummy profile boleh ditampilkan (jika ada)
        if (profile.uid.contains('dummy')) return true;

        // Filter berdasarkan preferensi gender
        final targetGender = preferences.preferredGender.toLowerCase();
        if (targetGender != 'both' &&
            targetGender != 'everyone' &&
            targetGender != 'all') {
          final userGender = profile.gender.toLowerCase();
          if (targetGender == 'men' && userGender != 'male') return false;
          if (targetGender == 'women' && userGender != 'female') return false;
        }

        // Filter umur
        if (profile.age < preferences.ageMin ||
            profile.age > preferences.ageMax) {
          return false;
        }

        // Filter jarak (jika lokasi tersedia)
        if (currentUserProfile?.location != null && profile.location != null) {
          try {
            final distanceInKm = Geolocator.distanceBetween(
              currentUserProfile!.location!.latitude,
              currentUserProfile.location!.longitude,
              profile.location!.latitude,
              profile.location!.longitude,
            ) /
                1000;

            if (distanceInKm > preferences.maxDistanceKm) return false;
          } catch (e) {
            debugPrint("Distance calculation error: $e");
          }
        }

        return true;
      }).toList();

      potentialMatches.shuffle();
      return potentialMatches;
    } catch (e) {
      debugPrint("getPotentialMatches error: $e");
      return [];
    }
  }

  /// Mengambil semua UID yang sudah di-like, di-pass, atau sudah match
  Future<Set<String>> _getExcludedUids() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    try {
      final results = await Future.wait([
        // Likes yang sudah dilakukan
        _firestore.collection('likes').doc(uid).collection('liked').get(),
        // Passes
        _firestore.collection('passes').doc(uid).collection('passedUsers').get(),
        // Matches yang sudah ada
        _firestore
            .collection('matches')
            .where('users', arrayContains: uid)
            .get(),
      ]);

      final Set<String> excluded = {uid};

      // Tambahkan semua yang sudah di-like
      for (var doc in results[0].docs) {
        excluded.add(doc.id);
      }

      // Tambahkan semua yang sudah di-pass
      for (var doc in results[1].docs) {
        excluded.add(doc.id);
      }

      // Tambahkan semua user dari match yang sudah ada
      for (var doc in results[2].docs) {
        final users = doc.data()['users'] as List<dynamic>?;
        if (users != null) {
          excluded.addAll(users.cast<String>());
        }
      }

      return excluded;
    } catch (e) {
      debugPrint("getExcludedUids error: $e");
      return {uid ?? ''};
    }
  }

  /// Mencatat bahwa user saat ini menyukai (like) user lain
  Future<void> likeUser(String likedUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Fluttertoast.showToast(
        msg: "Gagal: Belum login",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (uid == likedUserId) return;

    try {
      await _firestore
          .collection('likes')
          .doc(uid)
          .collection('liked')
          .doc(likedUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _incrementSwipeCount();

      // Catatan: match akan dibuat otomatis oleh Cloud Function
      // Kamu bisa menampilkan toast "Liked!" atau animasi di UI
    } catch (e) {
      debugPrint("likeUser error: $e");
      Fluttertoast.showToast(
        msg: "Gagal like: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  /// Mencatat bahwa user saat ini melewati (pass) user lain
  Future<void> passUser(String passedUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid == passedUserId) return;

    try {
      await _firestore
          .collection('passes')
          .doc(uid)
          .collection('passedUsers')
          .doc(passedUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _incrementSwipeCount();
    } catch (e) {
      debugPrint("passUser error: $e");
    }
  }

  /// Stream untuk mendapatkan daftar match user saat ini secara real-time
  Stream<QuerySnapshot> getMyMatchesStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('matches')
        .where('users', arrayContains: uid)
        .orderBy('lastActivityAt', descending: true)
        .snapshots();
  }
}