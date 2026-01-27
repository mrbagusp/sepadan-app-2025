import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- USER MANAGEMENT ---

  Stream<QuerySnapshot> streamUsers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> togglePremium(String uid, bool value) async {
    await _firestore.collection('users').doc(uid).update({'isPremium': value});
  }

  Future<void> toggleSuspended(String uid, bool value) async {
    await _firestore.collection('users').doc(uid).update({'isSuspended': value});
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    await _firestore.collection('profiles').doc(uid).delete();
    await _firestore.collection('preferences').doc(uid).delete();
  }

  // 🔥 FITUR BARU: Simulasi agar user lain me-like Admin
  Future<void> simulateLikeMe(String dummyUid, String adminUid) async {
    await _firestore
        .collection('likes')
        .doc(dummyUid)
        .collection('likedUsers')
        .doc(adminUid)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- CONTENT MODERATION ---

  Stream<QuerySnapshot> streamPending(String collection) {
    return _firestore
        .collection(collection)
        .where('approved', isEqualTo: false)
        .snapshots();
  }

  Future<void> approve(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).update({'approved': true});
  }

  Future<void> reject(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }
}
