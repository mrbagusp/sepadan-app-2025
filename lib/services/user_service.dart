
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sepadan/models/user_profile.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserProfile> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(UserProfile.empty());
    }
    return _firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromFirestore(snapshot);
      } else {
        return UserProfile.empty();
      }
    });
  }

  Future<void> updateUserPremiumStatus(bool isPremium) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isPremium': isPremium,
        // In a real app, you'd also set 'premiumUntil'
      });
    }
  }
}
