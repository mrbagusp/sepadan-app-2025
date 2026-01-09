
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        .set(profile.toFirestore());
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    if (currentUser == null) return;
    await firestore
        .collection('profiles')
        .doc(currentUser!.uid)
        .update(profile.toFirestore());
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
    return UserPreferences.defaultValues(); // Return default if not found
  }

  Future<void> updateUserPreferences(UserPreferences preferences) async {
    if (currentUser == null) return;
    await firestore
        .collection('preferences')
        .doc(currentUser!.uid)
        .set(preferences.toFirestore());
  }
}
