
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sepadan/models/daily_devo.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all devotionals, ordered by date descending
  Stream<List<DailyDevo>> getDevotionals() {
    return _firestore
        .collection('daily_devotionals')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DailyDevo.fromFirestore(doc)).toList();
    });
  }

  // Get only the most recent devotional
  Stream<List<DailyDevo>> getLatestDevotional() {
    return _firestore
        .collection('daily_devotionals')
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DailyDevo.fromFirestore(doc)).toList();
    });
  }
  
  // Add more methods here for other collections like events, testimonials, etc.
}
