// ============================================================
// 📁 lib/screens/profile/profile_notifier.dart
// ✅ FIXED: Based on original + added location permission dialogs
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sepadan/models/user_preferences.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/profile_service.dart';
import 'package:sepadan/services/notification_service.dart';

class ProfileNotifier extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  UserPreferences? _userPreferences;
  UserPreferences? get userPreferences => _userPreferences;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Profile data
  List<dynamic> _images = [];
  List<dynamic> get images => _images;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();
  final TextEditingController faithAnswerController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();

  String gender = 'male';
  GeoPoint? _location;
  GeoPoint? get location => _location;

  // Notification settings
  bool notifyDailyDevo = true;
  bool notifyNewMatch = true;
  bool notifyNewMessage = true;

  // Preferences data - using private with setters (IMPORTANT!)
  RangeValues _preferredAgeRange = const RangeValues(25, 45);
  RangeValues get preferredAgeRange => _preferredAgeRange;
  set preferredAgeRange(RangeValues value) {
    _preferredAgeRange = value;
    notifyListeners();
  }

  double _preferredDistance = 50;
  double get preferredDistance => _preferredDistance;
  set preferredDistance(double value) {
    _preferredDistance = value;
    notifyListeners();
  }

  String _interestedInGender = 'both';
  String get interestedInGender => _interestedInGender;
  set interestedInGender(String value) {
    _interestedInGender = value;
    notifyListeners();
  }

  // Context for location dialogs
  BuildContext? _context;
  void setContext(BuildContext context) {
    _context = context;
  }

  ProfileNotifier() {
    loadData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> loadData() async {
    _setLoading(true);
    _setError(null);
    try {
      _userProfile = await _profileService.getUserProfile();
      if (_userProfile != null) {
        nameController.text = _userProfile!.name;
        ageController.text = _userProfile!.age.toString();
        aboutMeController.text = _userProfile!.aboutMe;
        faithAnswerController.text = _userProfile!.faithAnswer;
        gender = _userProfile!.gender;
        _location = _userProfile!.location;
        _images = List<dynamic>.from(_userProfile!.photos);
      }

      _userPreferences = await _profileService.getUserPreferences();
      if (_userPreferences != null) {
        _preferredAgeRange = RangeValues(_userPreferences!.ageMin.toDouble(), _userPreferences!.ageMax.toDouble());
        _preferredDistance = _userPreferences!.maxDistanceKm.toDouble();
        _interestedInGender = _userPreferences!.preferredGender;
      }

      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final settings = userDoc.data()?['notificationSettings'] as Map<String, dynamic>?;
          if (settings != null) {
            notifyDailyDevo = settings['dailyDevo'] ?? true;
            notifyNewMatch = settings['newMatch'] ?? true;
            notifyNewMessage = settings['newMessage'] ?? true;
          }
        }
      }

      if (_location == null) {
        await updateLocation();
      }

    } catch (e) {
      debugPrint("Load Data Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateNotification(String key, bool value) async {
    if (key == 'dailyDevo') notifyDailyDevo = value;
    if (key == 'newMatch') notifyNewMatch = value;
    if (key == 'newMessage') notifyNewMessage = value;
    notifyListeners();

    await _notificationService.updateNotificationSettings(
      dailyDevo: notifyDailyDevo,
      newMatch: notifyNewMatch,
      newMessage: notifyNewMessage,
    );
  }

  Future<void> pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (index < _images.length) {
        _images[index] = file;
      } else {
        _images.add(file);
      }
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index < _images.length) {
      _images.removeAt(index);
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  // 🔥 LOCATION WITH PERMISSION DIALOGS
  // ─────────────────────────────────────────────────────────

  Future<void> updateLocation() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (_context != null && _context!.mounted) {
          final shouldOpen = await _showLocationServiceDialog(_context!);
          if (shouldOpen) {
            await Geolocator.openLocationSettings();
          }
        }
        return;
      }

      // 2. Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Show explanation dialog first
        if (_context != null && _context!.mounted) {
          await _showPermissionExplanationDialog(_context!);
        }

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (_context != null && _context!.mounted) {
          final shouldOpen = await _showPermissionDeniedForeverDialog(_context!);
          if (shouldOpen) {
            await Geolocator.openAppSettings();
          }
        }
        return;
      }

      // 3. Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      _location = GeoPoint(position.latitude, position.longitude);

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('profiles').doc(user.uid).set({
          'location': _location,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _setError(null);
      notifyListeners();
    } catch (e) {
      debugPrint("Location update failed: $e");
      _setError('Failed to get location');
    }
  }

  // ─────────────────────────────────────────────────────────
  // LOCATION DIALOGS
  // ─────────────────────────────────────────────────────────

  Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off, color: Colors.orange.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Location Disabled'),
          ],
        ),
        content: const Text(
          'Location services are turned off.\n\nPlease enable them to find matches near you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showPermissionExplanationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: Colors.deepPurple.shade600),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Allow Location', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEPADAN needs your location to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBullet(Icons.people, 'Find matches near you'),
            _buildBullet(Icons.straighten, 'Show distance on profiles'),
            _buildBullet(Icons.explore, 'Improve recommendations'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your exact location is never shown to others.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('I Understand'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Future<bool> _showPermissionDeniedForeverDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_disabled, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Location permission was permanently denied.\n\n'
              'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  // ─────────────────────────────────────────────────────────
  // OTHER METHODS (unchanged from original)
  // ─────────────────────────────────────────────────────────

  Future<bool> sendFeedback() async {
    if (feedbackController.text.trim().isEmpty) return false;
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      await _firestore.collection('admin_feedback').add({
        'userId': user?.uid,
        'userName': nameController.text,
        'userEmail': user?.email ?? 'Unknown',
        'message': feedbackController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'feedback_bug',
      }).timeout(const Duration(seconds: 10));

      feedbackController.clear();
      return true;
    } catch (e) {
      _setError('Failed to send feedback: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).delete();
      await _firestore.collection('profiles').doc(user.uid).delete();
      await _firestore.collection('preferences').doc(user.uid).delete();

      await user.delete();
      return true;
    } catch (e) {
      _setError('Failed to delete account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveData() async {
    _setLoading(true);
    _setError(null);

    final user = _auth.currentUser;
    if (user == null) {
      _setLoading(false);
      return false;
    }

    // Harus ada minimal 1 foto
    if (_images.isEmpty) {
      _setError("Please upload at least 1 photo to continue.");
      _setLoading(false);
      return false;
    }

    if (_location == null) {
      await updateLocation();
      if (_location == null) {
        _setError("Please enable location access to save your profile.");
        _setLoading(false);
        return false;
      }
    }

    try {
      // 1. Parallel Upload
      List<Future<String>> uploadFutures = [];
      for (var image in _images) {
        if (image is File) {
          uploadFutures.add(_uploadImage(image, user.uid).timeout(const Duration(seconds: 30)));
        } else if (image is String) {
          uploadFutures.add(Future.value(image));
        }
      }

      final List<String> photoUrls = await Future.wait(uploadFutures);

      // 2. Save Core Data
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        name: nameController.text,
        age: int.tryParse(ageController.text) ?? 0,
        gender: gender,
        aboutMe: aboutMeController.text,
        photos: photoUrls,
        faithAnswer: faithAnswerController.text,
        location: _location!,
        createdAt: _userProfile?.createdAt ?? Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      final preferences = UserPreferences(
        ageMin: _preferredAgeRange.start.round(),
        ageMax: _preferredAgeRange.end.round(),
        maxDistanceKm: _preferredDistance.round(),
        preferredGender: _interestedInGender,
      );

      await Future.wait([
        _profileService.updateUserProfile(profile),
        _profileService.updateUserPreferences(preferences),
      ]).timeout(const Duration(seconds: 15));

      return true;
    } catch (e) {
      debugPrint("Save Data Error: $e");
      _setError('Failed to save data: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _uploadImage(File imageFile, String userId) async {
    final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage.ref().child('profileImages').child(userId).child(fileName);
    final uploadTask = storageRef.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    aboutMeController.dispose();
    faithAnswerController.dispose();
    feedbackController.dispose();
    super.dispose();
  }
}