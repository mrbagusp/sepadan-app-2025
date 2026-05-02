// ============================================================
// 📁 lib/screens/profile/profile_create_screen.dart
// ✅ FIXED: Tablet keyboard support, proper scrolling
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sepadan/core/app_router.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/models/user_preferences.dart';
import 'package:sepadan/services/profile_service.dart';

class ProfileCreateScreen extends StatefulWidget {
  const ProfileCreateScreen({super.key});

  @override
  State<ProfileCreateScreen> createState() => _ProfileCreateScreenState();
}

class _ProfileCreateScreenState extends State<ProfileCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Form data
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _faithAnswerController = TextEditingController();
  String _gender = 'male';
  String _interestedIn = 'female';
  RangeValues _ageRange = const RangeValues(25, 45);
  double _maxDistance = 100;
  List<File> _photos = [];
  GeoPoint? _location;

  @override
  void initState() {
    super.initState();
    // ✅ Listen to text changes for button state update
    _faithAnswerController.addListener(_onFaithTextChanged);
    _aboutMeController.addListener(() => setState(() {}));
  }

  void _onFaithTextChanged() {
    setState(() {}); // Rebuild to update button state
  }

  @override
  void dispose() {
    _faithAnswerController.removeListener(_onFaithTextChanged);
    _nameController.dispose();
    _ageController.dispose();
    _aboutMeController.dispose();
    _faithAnswerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Important for keyboard handling
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressBar(),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildBasicInfoPage(),
                  _buildPhotosPage(),
                  _buildFaithPage(),
                  _buildPreferencesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousPage,
                ),
              const Spacer(),
              Text(
                'Step ${_currentPage + 1} of 5',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PAGE 1: Welcome
  // ─────────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 60,
              color: Colors.deepPurple.shade400,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to SEPADAN! 🎉',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Mari lengkapi profilmu agar bisa menemukan pasangan yang sepadan denganmu.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Mulai Setup Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PAGE 2: Basic Info
  // ─────────────────────────────────────────────────────────
  Widget _buildBasicInfoPage() {
    // ✅ Get keyboard height for padding
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return SingleChildScrollView(
      // ✅ Dismiss keyboard on scroll
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 40, // ✅ Extra padding for keyboard
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tentang Kamu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informasi dasar untuk profilmu',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            
            // Name
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            
            // Age
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Umur',
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v?.isEmpty == true) return 'Umur wajib diisi';
                final age = int.tryParse(v!) ?? 0;
                if (age < 18) return 'Minimal 18 tahun';
                if (age > 100) return 'Umur tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Gender
            Text(
              'Gender',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption('Pria', 'male', Icons.male),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGenderOption('Wanita', 'female', Icons.female),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // About Me
            TextFormField(
              controller: _aboutMeController,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Tentang Saya',
                hintText: 'Ceritakan sedikit tentang dirimu...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.edit_note),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label, String value, IconData icon) {
    final selected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.deepPurple : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Colors.deepPurple.shade50 : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? Colors.deepPurple : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.deepPurple : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PAGE 3: Photos
  // ─────────────────────────────────────────────────────────
  Widget _buildPhotosPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto Profil',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload minimal 1 foto (maksimal 6)',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          // Photo grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                return _buildPhotoItem(index);
              }
              return _buildAddPhotoButton();
            },
          ),
          
          if (_errorMessage != null && _photos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          
          const SizedBox(height: 32),
          _buildNextButton(enabled: _photos.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _photos[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _photos.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Utama',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.grey[400], size: 32),
            const SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 6) {
      setState(() => _errorMessage = 'Maksimal 6 foto');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _photos.add(File(pickedFile.path));
        _errorMessage = null;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  // PAGE 4: Faith Question
  // ✅ FIXED: Proper keyboard handling for tablet
  // ─────────────────────────────────────────────────────────
  Widget _buildFaithPage() {
    // ✅ Get keyboard height
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;
    
    return GestureDetector(
      // ✅ Tap outside to dismiss keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        // ✅ Dismiss keyboard on scroll
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          // ✅ Extra padding when keyboard is visible (especially important for tablets)
          bottom: isKeyboardVisible ? bottomInset + 120 : 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.church, color: Colors.deepPurple, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pertanyaan Iman',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepPurple[800],
                          ),
                        ),
                        Text(
                          'Untuk memastikan kamu adalah Kristen sejati',
                          style: TextStyle(color: Colors.deepPurple[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Siapakah Yesus Kristus bagimu?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jawaban ini akan membantu kami memverifikasi akunmu.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            // ✅ TextField with proper configuration
            TextFormField(
              controller: _faithAnswerController,
              maxLines: 6,
              minLines: 4,
              maxLength: 1000,
              textInputAction: TextInputAction.done,
              // ✅ Done button will dismiss keyboard
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: 'Ceritakan pengalamanmu dengan Tuhan, bagaimana Yesus mengubah hidupmu...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ✅ Character count helper
            if (_faithAnswerController.text.isNotEmpty && _faithAnswerController.text.length < 20)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Ketik ${20 - _faithAnswerController.text.length} karakter lagi...',
                  style: TextStyle(color: Colors.orange[700], fontSize: 13),
                ),
              ),
            
            // ✅ Button always visible
            _buildNextButton(
              enabled: _faithAnswerController.text.length >= 20,
              label: _faithAnswerController.text.length < 20 
                  ? 'Minimal 20 karakter' 
                  : 'Lanjut',
            ),
            
            // ✅ Extra space at bottom for keyboard
            SizedBox(height: isKeyboardVisible ? 20 : 0),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PAGE 5: Preferences
  // ─────────────────────────────────────────────────────────
  Widget _buildPreferencesPage() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferensi Pasangan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Siapa yang ingin kamu temui?',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          
          // Interested in
          Text(
            'Tertarik dengan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _buildChoiceChip('Pria', 'male'),
              _buildChoiceChip('Wanita', 'female'),
            ],
          ),
          const SizedBox(height: 32),
          
          // Age range
          Text(
            'Rentang Umur: ${_ageRange.start.round()} - ${_ageRange.end.round()} tahun',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 70,
            divisions: 52,
            labels: RangeLabels(
              '${_ageRange.start.round()}',
              '${_ageRange.end.round()}',
            ),
            activeColor: Colors.deepPurple,
            onChanged: (values) => setState(() => _ageRange = values),
          ),
          const SizedBox(height: 32),
          
          // Distance
          Text(
            'Jarak Maksimal: ${_maxDistance.round()} km',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _maxDistance,
            min: 10,
            max: 500,
            divisions: 49,
            label: '${_maxDistance.round()} km',
            activeColor: Colors.deepPurple,
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
          
          const SizedBox(height: 48),
          
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700]))),
                  ],
                ),
              ),
            ),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Selesai! Mulai Cari Pasangan 💜',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value) {
    final selected = _interestedIn == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (s) => s ? setState(() => _interestedIn = value) : null,
      selectedColor: Colors.deepPurple.shade100,
      labelStyle: TextStyle(
        color: selected ? Colors.deepPurple : Colors.grey[700],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildNextButton({bool enabled = true, String label = 'Lanjut'}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? _nextPage : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _nextPage() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    
    // Validate current page before proceeding
    if (_currentPage == 1) {
      if (!_formKey.currentState!.validate()) return;
    }
    if (_currentPage == 2 && _photos.isEmpty) {
      setState(() => _errorMessage = 'Upload minimal 1 foto');
      return;
    }
    if (_currentPage == 3 && _faithAnswerController.text.length < 20) {
      setState(() => _errorMessage = 'Jawaban minimal 20 karakter');
      return;
    }

    setState(() => _errorMessage = null);

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveAndContinue() async {
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // 1. Get location
      await _updateLocation();
      if (_location == null) {
        setState(() {
          _errorMessage = 'Izinkan akses lokasi untuk melanjutkan';
          _isLoading = false;
        });
        return;
      }

      // 2. Upload photos
      final List<String> photoUrls = [];
      final storage = FirebaseStorage.instance;
      
      for (int i = 0; i < _photos.length; i++) {
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = storage.ref().child('profileImages').child(user.uid).child(fileName);
        await ref.putFile(_photos[i]);
        final url = await ref.getDownloadURL();
        photoUrls.add(url);
      }

      // 3. Create profile
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _gender,
        aboutMe: _aboutMeController.text.trim(),
        faithAnswer: _faithAnswerController.text.trim(),
        photos: photoUrls,
        location: _location,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // 4. Create preferences
      final preferences = UserPreferences(
        preferredGender: _interestedIn,
        ageMin: _ageRange.start.round(),
        ageMax: _ageRange.end.round(),
        maxDistanceKm: _maxDistance.round(),
      );

      // 5. Save to Firestore
      final profileService = ProfileService();
      await Future.wait([
        profileService.updateUserProfile(profile),
        profileService.updateUserPreferences(preferences),
      ]);

      // 6. Mark profile as complete in cache
      await markProfileComplete();

      // 7. Navigate to main
      if (mounted) {
        context.go('/main');
      }

    } catch (e) {
      debugPrint('Save error: $e');
      setState(() => _errorMessage = 'Gagal menyimpan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Aktifkan layanan lokasi');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _errorMessage = 'Izin lokasi diperlukan');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = 'Buka pengaturan untuk izinkan lokasi');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      _location = GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() => _errorMessage = 'Gagal mendapatkan lokasi');
    }
  }
}