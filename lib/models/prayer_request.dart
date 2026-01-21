import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerRequest {
  final String id;
  final String title;
  final String details;
  final String submittedBy; // User UID
  final String status; // pending, approved, rejected
  final Timestamp createdAt;
  final String userName;
  final String requestDetails;

  PrayerRequest({
    required this.id,
    required this.title,
    required this.details,
    required this.submittedBy,
    this.status = 'pending',
    required this.createdAt,
    required this.userName,
    required this.requestDetails,
  });

  factory PrayerRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PrayerRequest(
      id: doc.id,
      title: data['title'] ?? '',
      details: data['details'] ?? '',
      submittedBy: data['submittedBy'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      userName: data['userName'] ?? '',
      requestDetails: data['requestDetails'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'details': details,
      'submittedBy': submittedBy,
      'status': status,
      'createdAt': createdAt,
      'userName': userName,
      'requestDetails': requestDetails,
    };
  }
}
