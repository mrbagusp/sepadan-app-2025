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
        final bool manualPremium = data['isPremium'] ?? false;
        
        // 🔥 LOGIKA FREEMIUM 14 HARI
        final Timestamp? createdAt = data['createdAt'] as Timestamp?;
        bool isTrialActive = false;
        
        if (createdAt != null) {
          final creationDate = createdAt.toDate();
          final now = DateTime.now();
          final difference = now.difference(creationDate).inDays;
          
          // Jika akun berumur kurang dari 14 hari, anggap premium (Trial)
          if (difference <= 14) {
            isTrialActive = true;
          }
        }

        return manualPremium || isTrialActive;
      });
    });
  }

  // Helper untuk mendapatkan sisa hari trial
  Future<int> getTrialDaysRemaining() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return 0;

    final Timestamp? createdAt = doc.data()?['createdAt'] as Timestamp?;
    if (createdAt == null) return 0;

    final difference = DateTime.now().difference(createdAt.toDate()).inDays;
    final remaining = 14 - difference;
    return remaining > 0 ? remaining : 0;
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
