import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sepadan/models/user_profile.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // 🔥 REAL-TIME: Ambil daftar match sebagai Stream
  Stream<List<Map<String, dynamic>>> getMatchesStream() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('matches')
        .where('users', arrayContains: _currentUserId)
        .orderBy('lastMessageTimestamp', descending: true) // Pesan terbaru di atas
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> matchesWithProfiles = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<String> users = List<String>.from(data['users'] ?? []);
        final otherId = users.firstWhere((id) => id != _currentUserId, orElse: () => '');

        if (otherId.isNotEmpty) {
          // Ambil profil user lawan bicara
          final profileDoc = await _firestore.collection('profiles').doc(otherId).get();
          if (profileDoc.exists) {
            final profile = UserProfile.fromFirestore(profileDoc);
            matchesWithProfiles.add({
              'profile': profile,
              'matchId': doc.id,
              'lastMessage': data['lastMessage'] ?? 'Kalian telah cocok! Silakan mulai menyapa.',
              'lastMessageTimestamp': data['lastMessageTimestamp'],
            });
          }
        }
      }
      return matchesWithProfiles;
    });
  }

  Stream<QuerySnapshot> getMessages(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(String matchId, String text) async {
    if (_currentUserId == null || text.trim().isEmpty) return;

    final messageData = {
      'senderId': _currentUserId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .add(messageData);
      
      await _firestore.collection('matches').doc(matchId).update({
        'lastMessage': text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("SendMessage Error: $e");
      rethrow;
    }
  }
}
