import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final Timestamp date;
  final String submittedBy; // User UID
  final String status; // pending, approved, rejected
  final Timestamp createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.submittedBy,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      submittedBy: data['submittedBy'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': date,
      'submittedBy': submittedBy,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
