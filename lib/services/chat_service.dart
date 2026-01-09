
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

    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('users', arrayContains: _currentUserId)
        .get();

    if (matchesSnapshot.docs.isEmpty) return [];

    List<String> otherUserIds = matchesSnapshot.docs.map((doc) {
      final List<String> users = List<String>.from(doc.data()['users']);
      return users.firstWhere((id) => id != _currentUserId);
    }).toList();

    final profilesSnapshot = await _firestore
        .collection('profiles')
        .where(FieldPath.documentId, whereIn: otherUserIds)
        .get();

    final profiles = profilesSnapshot.docs
        .map((doc) => UserProfile.fromFirestore(doc))
        .toList();

    // Pair profiles with their corresponding matchId
    List<(UserProfile, String)> matchedUsersWithId = [];
    for (var profile in profiles) {
       final matchDoc = matchesSnapshot.docs.firstWhere((doc) => List<String>.from(doc.data()['users']).contains(profile.uid));
       matchedUsersWithId.add((profile, matchDoc.id));
    }

    return matchedUsersWithId;
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
    
    // Optionally, update the match document with the last message details
    await _firestore.collection('matches').doc(matchId).update({
      'lastMessage': text,
      'lastMessageTimestamp': Timestamp.now(),
    });

  }
}
