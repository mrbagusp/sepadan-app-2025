import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sepadan/models/user_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserProfile?> getUserProfile() async {
    if (currentUser == null) return null;

    DocumentSnapshot doc = await firestore
        .collection('profiles')
        .doc(currentUser!.uid)
        .get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  Future<UserProfile?> getProfileByUid(String uid) async {
    DocumentSnapshot doc = await firestore.collection('profiles').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  Future<void> createUserProfile(UserProfile profile) async {
    if (currentUser == null) return;
    await firestore
        .collection('profiles')
        .doc(currentUser!.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    if (currentUser == null) return;
    // 🔥 FIXED: Gunakan set dengan merge agar tidak error 'not-found' untuk user baru
    await firestore
        .collection('profiles')
        .doc(currentUser!.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> saveUserProfile({
    required String name,
    required int age,
    required String gender,
    required String about,
    required List<String> photoUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("saveUserProfile Error: No authenticated user found.");
        return;
      }

      final uid = user.uid;
      final docRef = firestore.collection('profiles').doc(uid);

      await docRef.set({
        'name': name,
        'age': age,
        'gender': gender,
        'about': about,
        'photoUrls': photoUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Profile saved successfully for UID: $uid");
    } catch (e) {
      debugPrint("saveUserProfile Error: $e");
      rethrow;
    }
  }

  Future<UserPreferences> getUserPreferences() async {
    if (currentUser == null) return UserPreferences.defaultValues();

    DocumentSnapshot doc = await firestore
        .collection('preferences')
        .doc(currentUser!.uid)
        .get();
        
    if (doc.exists) {
      return UserPreferences.fromFirestore(doc);
    }
    return UserPreferences.defaultValues();
  }

  Future<void> updateUserPreferences(UserPreferences preferences) async {
    if (currentUser == null) return;
    // 🔥 FIXED: Gunakan merge true
    await firestore
        .collection('preferences')
        .doc(currentUser!.uid)
        .set(preferences.toFirestore(), SetOptions(merge: true));
  }
}
