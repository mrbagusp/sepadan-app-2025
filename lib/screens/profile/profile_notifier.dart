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

      // 🔥 Minta izin dan update lokasi otomatis saat aplikasi diakses (load data)
      await updateLocation();

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

  Future<void> updateLocation() async {
    _setLoading(true);
    _setError(null);
    try {
      // 1. Cek apakah layanan lokasi aktif di perangkat
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // 2. Cek status izin saat ini
      LocationPermission permission = await Geolocator.checkPermission();
      
      // 3. Jika izin belum pernah ditanyakan, minta izin ke pengguna (muncul pop-up)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      // 4. Jika izin diblokir secara permanen
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
      }

      // 5. Ambil lokasi saat ini dengan akurasi rendah (lebih cepat)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low
      );
      
      _location = GeoPoint(position.latitude, position.longitude);
      
      // 6. Jika profil sudah ada, langsung update lokasi ke Firestore secara background
      final user = _auth.currentUser;
      if (user != null && _userProfile != null) {
        await _firestore.collection('profiles').doc(user.uid).update({
          'location': _location,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Update Location Error: $e");
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendFeedback() async {
    final String message = feedbackController.text.trim();
    if (message.isEmpty) return false;
    
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      await _firestore.collection('admin_feedback').add({
        'userId': user?.uid,
        'userName': nameController.text,
        'userEmail': user?.email ?? 'Unknown',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'feedback_bug',
      });
      
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
    if (user == null) return false;
    
    if (_location == null) {
      // Coba minta lokasi sekali lagi sebelum simpan
      await updateLocation();
      if (_location == null) {
        _setError("Please enable location access to continue.");
        _setLoading(false);
        return false;
      }
    }

    try {
      List<Future<String>> uploadFutures = [];
      for (var image in _images) {
        if (image is File) {
          uploadFutures.add(_uploadImage(image, user.uid));
        } else if (image is String) {
          uploadFutures.add(Future.value(image));
        }
      }

      final List<String> photoUrls = await Future.wait(uploadFutures);

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
      ]);
      
      return true;
    } catch (e) {
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
