import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String aboutMe;
  final String gender;
  final String faithAnswer;
  final GeoPoint? location;
  final List<String> photos;

  final bool isPremium;
  final String role;
  final Timestamp? premiumUntil;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.age = 0,
    this.aboutMe = '',
    this.gender = '',
    this.faithAnswer = '',
    this.location,
    this.photos = const [],
    this.isPremium = false,
    this.role = 'user',
    this.premiumUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty profile
  factory UserProfile.empty() {
    return UserProfile(
      uid: '',
      name: '',
      email: '',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }

  /// Firestore → Object
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      age: (data['age'] ?? 0).toInt(),
      aboutMe: data['aboutMe'] ?? '',
      gender: data['gender'] ?? '',
      faithAnswer: data['faithAnswer'] ?? '',
      location: data['location'],
      photos: List<String>.from(data['photos'] ?? []),
      isPremium: data['isPremium'] ?? false,
      role: data['role'] ?? 'user',
      premiumUntil: data['premiumUntil'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Object → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'aboutMe': aboutMe,
      'gender': gender,
      'faithAnswer': faithAnswer,
      'location': location,
      'photos': photos,
      'isPremium': isPremium,
      'role': role,
      'premiumUntil': premiumUntil,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Check if profile ready for swipe/match
  bool get isProfileComplete {
    return name.isNotEmpty &&
        age > 0 &&
        gender.isNotEmpty &&
        photos.isNotEmpty &&
        location != null;
  }
}
