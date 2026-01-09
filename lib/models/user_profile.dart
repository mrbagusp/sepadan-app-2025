import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String aboutMe;
  final List<String> photos;
  final String faithAnswer;
  final GeoPoint location;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String role;
  final String? fcmToken;

  UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.aboutMe,
    required this.photos,
    required this.faithAnswer,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.role = 'user', // Default role
    this.fcmToken,
  });

  bool get isProfileComplete {
    return name.isNotEmpty &&
        age > 0 &&
        gender.isNotEmpty &&
        aboutMe.isNotEmpty &&
        photos.isNotEmpty;
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      aboutMe: data['aboutMe'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      faithAnswer: data['faithAnswer'] ?? 'Siapa Yesus Kristus buatmu?',
      location: data['location'] ?? const GeoPoint(0, 0),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      role: data['role'] ?? 'user', // Read role, default to 'user'
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'gender': gender,
      'aboutMe': aboutMe,
      'photos': photos,
      'faithAnswer': faithAnswer,
      'location': location,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'role': role,
      'fcmToken': fcmToken,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    int? age,
    String? gender,
    String? aboutMe,
    List<String>? photos,
    String? faithAnswer,
    GeoPoint? location,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? role,
    String? fcmToken,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      aboutMe: aboutMe ?? this.aboutMe,
      photos: photos ?? this.photos,
      faithAnswer: faithAnswer ?? this.faithAnswer,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
