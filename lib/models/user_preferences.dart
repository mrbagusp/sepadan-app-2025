
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferences {
  final int ageMin;
  final int ageMax;
  final String preferredGender;
  final int maxDistanceKm;

  UserPreferences({
    required this.ageMin,
    required this.ageMax,
    required this.preferredGender,
    required this.maxDistanceKm,
  });

  factory UserPreferences.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserPreferences(
      ageMin: data['ageMin'] ?? 18,
      ageMax: data['ageMax'] ?? 35,
      preferredGender: data['preferredGender'] ?? 'everyone',
      maxDistanceKm: data['maxDistanceKm'] ?? 25,
    );
  }

    factory UserPreferences.defaultValues() {
    return UserPreferences(
      ageMin: 18,
      ageMax: 35,
      preferredGender: 'everyone',
      maxDistanceKm: 25,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ageMin': ageMin,
      'ageMax': ageMax,
      'preferredGender': preferredGender,
      'maxDistanceKm': maxDistanceKm,
    };
  }

   UserPreferences copyWith({
    int? ageMin,
    int? ageMax,
    String? preferredGender,
    int? maxDistanceKm,
  }) {
    return UserPreferences(
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      preferredGender: preferredGender ?? this.preferredGender,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }
}
