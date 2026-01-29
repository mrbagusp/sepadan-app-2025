import 'package:cloud_firestore/cloud_firestore.dart';

class DatingTip {
  final String id;
  final String title;
  final String content;
  final Timestamp createdAt;

  DatingTip({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory DatingTip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DatingTip(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
