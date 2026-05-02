// ============================================================
// 📁 lib/models/user_profile.dart
// ✅ UPDATED: Added lastActiveAt, isVisible, accountStatus
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Account status enum
enum AccountStatus {
  active,    // Normal active account
  inactive,  // User hasn't been active for 30+ days
  suspended, // Admin suspended the account
  deleted,   // Soft-deleted account
}

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
  
  // 🔥 NEW FIELDS for user visibility
  final Timestamp? lastActiveAt;      // Last time user opened the app
  final bool isVisible;               // Can be set to false to hide from swipe
  final AccountStatus accountStatus;  // Current account status
  final String? lastActiveDisplay;    // Computed "Active X ago" string

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
    // New fields
    this.lastActiveAt,
    this.isVisible = true,
    this.accountStatus = AccountStatus.active,
    this.lastActiveDisplay,
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

    // Parse account status
    AccountStatus status = AccountStatus.active;
    final statusStr = data['accountStatus'] as String?;
    if (statusStr != null) {
      status = AccountStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => AccountStatus.active,
      );
    }
    
    // Handle legacy isSuspended field
    if (data['isSuspended'] == true) {
      status = AccountStatus.suspended;
    }

    // Parse lastActiveAt and compute display string
    final lastActiveTimestamp = data['lastActiveAt'] as Timestamp?;
    String? lastActiveDisplay;
    
    if (lastActiveTimestamp != null) {
      lastActiveDisplay = _computeLastActiveDisplay(lastActiveTimestamp);
    }

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
      // New fields
      lastActiveAt: lastActiveTimestamp,
      isVisible: data['isVisible'] ?? true,
      accountStatus: status,
      lastActiveDisplay: lastActiveDisplay,
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
      // New fields
      'lastActiveAt': lastActiveAt ?? FieldValue.serverTimestamp(),
      'isVisible': isVisible,
      'accountStatus': accountStatus.name,
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

  /// Check if user should appear in swipe pool
  bool get canBeSwipedOn {
    return isProfileComplete &&
        isVisible &&
        accountStatus == AccountStatus.active;
  }

  /// Check if user is considered "active" (within last 7 days)
  bool get isRecentlyActive {
    if (lastActiveAt == null) return false;
    final now = DateTime.now();
    final lastActive = lastActiveAt!.toDate();
    final difference = now.difference(lastActive);
    return difference.inDays <= 7;
  }

  /// Check if user is "online" (within last 5 minutes)
  bool get isOnlineNow {
    if (lastActiveAt == null) return false;
    final now = DateTime.now();
    final lastActive = lastActiveAt!.toDate();
    final difference = now.difference(lastActive);
    return difference.inMinutes <= 5;
  }

  /// Create copy with updated fields
  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    int? age,
    String? aboutMe,
    String? gender,
    String? faithAnswer,
    GeoPoint? location,
    List<String>? photos,
    bool? isPremium,
    String? role,
    Timestamp? premiumUntil,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? lastActiveAt,
    bool? isVisible,
    AccountStatus? accountStatus,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      aboutMe: aboutMe ?? this.aboutMe,
      gender: gender ?? this.gender,
      faithAnswer: faithAnswer ?? this.faithAnswer,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      isPremium: isPremium ?? this.isPremium,
      role: role ?? this.role,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isVisible: isVisible ?? this.isVisible,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }

  /// Compute human-readable "last active" string
  static String _computeLastActiveDisplay(Timestamp timestamp) {
    final now = DateTime.now();
    final lastActive = timestamp.toDate();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Online';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Active ${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Active ${weeks}w ago';
    } else {
      return 'Active 30+ days ago';
    }
  }
}
