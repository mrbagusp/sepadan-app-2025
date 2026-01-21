
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyDevo {
  final String id;
  final String title;
  final String content;
  final DateTime date;

  DailyDevo({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  factory DailyDevo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DailyDevo(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      // Convert Firestore Timestamp to Dart DateTime
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
