import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<bool> getPremiumStatus() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(false);
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return false;
        final data = snapshot.data() as Map<String, dynamic>;
        return data['isPremium'] ?? false;
      });
    });
  }

  Future<void> updatePremiumStatus(bool status) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isPremium': status,
      });
    }
  }
}
