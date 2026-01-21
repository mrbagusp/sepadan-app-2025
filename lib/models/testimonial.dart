
import 'package:cloud_firestore/cloud_firestore.dart';

class Testimonial {
  final String uid;
  final String story;
  final String photoUrl;
  final Timestamp timestamp;

  Testimonial({
    required this.uid,
    required this.story,
    required this.photoUrl,
    required this.timestamp,
  });

  factory Testimonial.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Testimonial(
      uid: data['uid'] ?? '',
      story: data['story'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
