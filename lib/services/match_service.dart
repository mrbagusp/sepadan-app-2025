
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sepadan/models/user_preferences.dart';
import 'package:sepadan/models/user_profile.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Correctly fetches the current user's profile and their saved preferences.
  Future<(UserProfile?, UserPreferences?)> _getCurrentUserData() async {
    if (_currentUserId == null) return (null, null);

    final profileDoc = await _firestore.collection('profiles').doc(_currentUserId).get();
    // CORRECTED: Fetch from the 'preferences' collection.
    final prefsDoc = await _firestore.collection('preferences').doc(_currentUserId).get();

    final profile = profileDoc.exists ? UserProfile.fromFirestore(profileDoc) : null;
    // Load preferences or return default values if none are saved.
    final preferences = prefsDoc.exists ? UserPreferences.fromFirestore(prefsDoc) : UserPreferences.defaultValues();

    return (profile, preferences);
  }

  // Gathers a set of UIDs to be excluded from matching (already liked, passed, or matched).
  Future<Set<String>> _getExcludedUids() async {
    if (_currentUserId == null) return {};

    final likesSnapshot = await _firestore.collection('likes').doc(_currentUserId).collection('likedUsers').get();
    final passesSnapshot = await _firestore.collection('passes').doc(_currentUserId).collection('passedUsers').get();
    final matchesSnapshot = await _firestore.collection('matches').where('users', arrayContains: _currentUserId).get();

    final likedUids = likesSnapshot.docs.map((doc) => doc.id).toSet();
    final passedUids = passesSnapshot.docs.map((doc) => doc.id).toSet();
    final matchedUids = matchesSnapshot.docs.fold<Set<String>>({}, (prev, doc) {
      final List<String> users = List<String>.from(doc.data()['users']);
      final otherUserId = users.firstWhere((id) => id != _currentUserId, orElse: () => 'null');
      if (otherUserId != 'null') prev.add(otherUserId);
      return prev;
    });
    
    // Add current user's own ID to the exclusion list.
    return {...likedUids, ...passedUids, ...matchedUids, _currentUserId!};
  }

  // Fetches profiles that are potential matches based on the user's saved preferences.
  Future<List<UserProfile>> getPotentialMatches() async {
    final (currentUserProfile, preferences) = await _getCurrentUserData();

    // Abort if the user's profile or preferences are missing, or if their profile is incomplete.
    if (currentUserProfile == null || preferences == null || !currentUserProfile.isProfileComplete) {
      return [];
    }

    final excludedUids = await _getExcludedUids();
    
    // Start with a basic query on the profiles collection.
    Query query = _firestore.collection('profiles');

    // SERVER-SIDE FILTER: Filter by gender if the preference is not 'both'. This narrows down the documents read.
    // CORRECTED: Use 'preferredGender' from the preferences model.
    if (preferences.preferredGender != 'both') {
      query = query.where('gender', isEqualTo: preferences.preferredGender);
    }

    final allProfilesSnapshot = await query.get();

    // CLIENT-SIDE FILTERING: Apply filters that are difficult to perform on the server (distance, age range, exclusions).
    final potentialMatches = allProfilesSnapshot.docs
      .map((doc) => UserProfile.fromFirestore(doc))
      .where((profile) {
        // Exclude profiles from the exclusion list.
        if (excludedUids.contains(profile.uid)) return false;

        // Filter by age range.
        // CORRECTED: Use 'ageMin' and 'ageMax' from the preferences model.
        if (profile.age < preferences.ageMin || profile.age > preferences.ageMax) return false;

        // Filter by distance (calculated client-side).
        final distanceInKm = Geolocator.distanceBetween(
              currentUserProfile.location.latitude,
              currentUserProfile.location.longitude,
              profile.location.latitude,
              profile.location.longitude,
            ) / 1000;

        // CORRECTED: Use 'maxDistanceKm' from the preferences model.
        return distanceInKm <= preferences.maxDistanceKm;
      }).toList();
      
    // Shuffle the results to provide a varied order each time.
    potentialMatches.shuffle();

    return potentialMatches;
  }

  // Records a 'like' action and checks if it results in a new match.
  Future<(bool, String?)> likeUser(String likedUserId) async {
    if (_currentUserId == null) return (false, null);

    await _firestore.collection('likes').doc(_currentUserId).collection('likedUsers').doc(likedUserId).set({'timestamp': FieldValue.serverTimestamp()});

    final otherUserLike = await _firestore.collection('likes').doc(likedUserId).collection('likedUsers').doc(_currentUserId).get();

    // If the other user has also liked the current user, create a match.
    if (otherUserLike.exists) {
      final matchId = await _createMatch(_currentUserId!, likedUserId);
      return (true, matchId); // Returns true for a match, and the new match ID.
    }

    return (false, null); // No match yet.
  }

  // Records a 'pass' action.
  Future<void> passUser(String passedUserId) async {
    if (_currentUserId == null) return;
    await _firestore.collection('passes').doc(_currentUserId).collection('passedUsers').doc(passedUserId).set({'timestamp': FieldValue.serverTimestamp()});
  }

  // Creates a new match document in Firestore.
  Future<String> _createMatch(String uid1, String uid2) async {
    // Create a consistent ID to prevent duplicate match documents.
    final matchId = uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
    await _firestore.collection('matches').doc(matchId).set({
      'users': [uid1, uid2],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return matchId;
  }
}
