import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:intl/intl.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // 🔥 Fungsi untuk mengecek limit chat harian
  Future<bool> canChat() async {
    if (_currentUserId == null) return false;

    final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
    final bool isPremium = userDoc.data()?['isPremium'] == true;
    final bool isAdmin = userDoc.data()?['isAdmin'] == true;

    // Admin dan Premium bebas chat
    if (isPremium || isAdmin) return true;

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final statsDoc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('daily_stats')
        .doc(today)
        .get();

    if (!statsDoc.exists) return true;

    final int chatCount = statsDoc.data()?['chatCount'] ?? 0;
    return chatCount < 20; // Limit 20 chat per hari untuk user biasa
  }

  // 🔥 Fungsi untuk mencatat pengiriman pesan
  Future<void> _incrementChatCount() async {
    if (_currentUserId == null) return;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('daily_stats')
        .doc(today);

    await docRef.set({
      'chatCount': FieldValue.increment(1),
      'lastChat': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getMatchesStream() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('matches')
        .where('users', arrayContains: _currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> matchesWithProfiles = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<String> users = List<String>.from(data['users'] ?? []);
        final otherId = users.firstWhere((id) => id != _currentUserId, orElse: () => '');

        if (otherId.isNotEmpty) {
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

    // Cek limit sebelum kirim pesan
    if (!(await canChat())) {
      throw Exception("DAILY_CHAT_LIMIT_REACHED");
    }

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

      await _incrementChatCount(); // Catat chat berhasil
    } catch (e) {
      print("SendMessage Error: $e");
      rethrow;
    }
  }
}
