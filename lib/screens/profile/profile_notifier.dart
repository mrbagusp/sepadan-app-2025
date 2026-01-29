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
  String gender = 'male';
  GeoPoint? _location;
  GeoPoint? get location => _location;

  // Notification settings
  bool notifyDailyDevo = true;
  bool notifyNewMatch = true;
  bool notifyNewMessage = true;

  // Preferences data
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
      _preferredAgeRange = RangeValues(_userPreferences!.ageMin.toDouble(), _userPreferences!.ageMax.toDouble());
      _preferredDistance = _userPreferences!.maxDistanceKm.toDouble();
      _interestedInGender = _userPreferences!.preferredGender;

      // Load notification settings from users collection
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final settings = data['notificationSettings'] as Map<String, dynamic>?;
          if (settings != null) {
            notifyDailyDevo = settings['dailyDevo'] ?? true;
            notifyNewMatch = settings['newMatch'] ?? true;
            notifyNewMessage = settings['newMessage'] ?? true;
          }
        }
      }

    } catch (e) {
      _setError('Failed to load data: $e');
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

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

  Future<void> updateLocation() async {
     _setLoading(true);
     _setError(null);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();
      _location = GeoPoint(position.latitude, position.longitude);
      
    } catch (e) {
      _setError('Failed to get location: $e');
    }
    finally {
      _setLoading(false);
    }
  }

  Future<bool> saveData() async {
    _setLoading(true);
    _setError(null);

    final user = _auth.currentUser;
    if (user == null) {
      _setError("User not logged in.");
      _setLoading(false);
      return false;
    }
    
    if (_location == null) {
      _setError("Please update your location before saving.");
      _setLoading(false);
      return false;
    }

    try {
      // 1. Save Profile
      List<String> photoUrls = [];
      for (var image in _images) {
        if (image is File) {
          final currentUser = _auth.currentUser;
          if (currentUser == null) throw Exception("Session expired. Please login again.");
          
          final photoUrl = await _uploadImage(image, currentUser.uid);
          photoUrls.add(photoUrl);
        } else if (image is String) {
          photoUrls.add(image);
        }
      }

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

      final existingProfile = await _profileService.getUserProfile();
      if (existingProfile == null) {
          await _profileService.createUserProfile(profile);
      } else {
          await _profileService.updateUserProfile(profile);
      }

      // 2. Save Preferences
      final preferences = UserPreferences(
        ageMin: _preferredAgeRange.start.round(),
        ageMax: _preferredAgeRange.end.round(),
        maxDistanceKm: _preferredDistance.round(),
        preferredGender: _interestedInGender,
      );
      await _profileService.updateUserPreferences(preferences);
      
      await loadData(); // Refresh all data
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
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'profile_$timestamp.jpg';
      final storageRef = _storage.ref().child('profileImages').child(userId).child(fileName);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload Error Details: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    aboutMeController.dispose();
    faithAnswerController.dispose();
    super.dispose();
  }
}
