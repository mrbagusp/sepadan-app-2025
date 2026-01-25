import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sepadan/models/user_profile.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Get a list of matched users to display on the chat list screen.
  Future<List<(UserProfile, String)>> getMatches() async {
    if (_currentUserId == null) return [];

    try {
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: _currentUserId)
          .get();

      if (matchesSnapshot.docs.isEmpty) return [];

      List<String> otherUserIds = [];
      Map<String, String> matchIdMap = {}; // Map otherUserId -> matchId

      for (var doc in matchesSnapshot.docs) {
        final List<String> users = List<String>.from(doc.data()['users'] ?? []);
        final otherId = users.firstWhere((id) => id != _currentUserId, orElse: () => '');
        if (otherId.isNotEmpty) {
          otherUserIds.add(otherId);
          matchIdMap[otherId] = doc.id;
        }
      }

      if (otherUserIds.isEmpty) return [];

      // Ambil profil dari koleksi 'profiles' (BUKAN 'users')
      final profilesSnapshot = await _firestore
          .collection('profiles')
          .where(FieldPath.documentId, whereIn: otherUserIds)
          .get();

      final List<(UserProfile, String)> results = [];
      for (var doc in profilesSnapshot.docs) {
        final profile = UserProfile.fromFirestore(doc);
        final mId = matchIdMap[profile.uid];
        if (mId != null) {
          results.add((profile, mId));
        }
      }

      return results;
    } catch (e) {
      print("ChatService Error: $e");
      rethrow;
    }
  }

  // Get a real-time stream of messages for a specific match.
  Stream<QuerySnapshot> getMessages(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Send a new message.
  Future<void> sendMessage(String matchId, String text) async {
    if (_currentUserId == null || text.trim().isEmpty) return;

    await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .add({
      'senderId': _currentUserId,
      'text': text,
      'createdAt': Timestamp.now(),
    });
    
    await _firestore.collection('matches').doc(matchId).update({
      'lastMessage': text,
      'lastMessageTimestamp': Timestamp.now(),
    });
  }
}
