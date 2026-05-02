// ============================================================
// 📁 lib/screens/admin/dummy_data_generator.dart
// ✅ Generate dummy users with exact Firebase Storage file names
// ============================================================

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DummyDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // ─────────────────────────────────────────────────────────
  // 🔥 FIREBASE STORAGE BUCKET
  // ─────────────────────────────────────────────────────────
  static const String _bucketName = 'sepadan-app-2025.firebasestorage.app';

  // ─────────────────────────────────────────────────────────
  // 🔥 EXACT FILE NUMBERS FROM FIREBASE STORAGE
  // ─────────────────────────────────────────────────────────
  // Men: 1-50 (lengkap)
  static const List<int> malePhotoNumbers = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50
  ];

  // Women: 1-51 (lengkap)
  static const List<int> femalePhotoNumbers = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
  ];

  // ─────────────────────────────────────────────────────────
  // NAMA PRIA INDONESIA (50 nama = sesuai jumlah foto)
  // ─────────────────────────────────────────────────────────
  static const List<String> maleNames = [
    'Budi Santoso', 'Andi Wijaya', 'Rizki Pratama', 'Dimas Prasetyo', 'Fajar Nugroho',
    'Gilang Ramadan', 'Hendra Kusuma', 'Ivan Setiawan', 'Joko Susanto', 'Kevin Tanoto',
    'Lukmana Hakim', 'Muhammad Rizal', 'Nanda Saputra', 'Oscar Panjaitan', 'Putra Aditya',
    'Qori Firmansyah', 'Raka Mahendra', 'Satria Wibowo', 'Taufik Hidayat', 'Umar Syarif',
    'Vinocom Bastian', 'Wahyu Ananda', 'Xavier Tanjung', 'Yusuf Maulana', 'Zainal Abidin',
    'Arief Rahman', 'Bagus Hernawan', 'Candra Kirana', 'Dennies Sumargo', 'Eko Purwanto',
    'Farhan Attamimi', 'Galih Permana', 'Hanif Sjahbandi', 'Irfano Bachdim', 'Jeffry Runtu',
    'Krisna Muktijo', 'Leo Situmorang', 'Mario walata', 'Nicos Siahaan', 'Okta Maniani',
    'Panji Trihatmodjo', 'Raffi Faridz', 'Sandy Arifin', 'Teguh Prabowo', 'Ucok Baba',
    'Verdi Solaiman', 'Wawan Setiawan', 'Yanto Basuki', 'Zaki Mubarok', 'Aldis Taher'

  ];

  // ─────────────────────────────────────────────────────────
  // NAMA WANITA INDONESIA (51 nama = sesuai jumlah foto)
  // ─────────────────────────────────────────────────────────
  static const List<String> femaleNames = [
    'Putri Anggraini', 'Sari Dewi', 'Rina Wulandari', 'Maya Saptari', 'Dian Sastro',
    'Ayu Lestari', 'Bellania Saphira', 'Citra Kirana', 'Dewi Eka', 'Eka Gusti',
    'Fitri Carlina', 'Gita Gutawati', 'Happy Salmani', 'Indah Permatasari', 'Jessica Isdar',
    'Kartika Putri', 'Maya lunawati', 'Maudy Ayu', 'Nana Mira', 'Olivia Zalty',
    'Prilly Consina', 'Queen Viodelya', 'Risa Andriana', 'Syifa Hadju', 'Titi Kamalaputri',
    'Lusi Sulistiawaty', 'Vanesha Prescilla', 'Widi Mulia', 'Xena Angelina', 'Yunika Shara',
    'Zaznah Sungkar', 'Adinia Wirasti', 'Bunga Citra', 'Chel Islana', 'Dinda Hava',
    'Enva Storia', 'Febby Rastanty', 'Gracia Indria', 'Hesti Adinata', 'Ira Widi',
    'Juwita Sari', 'Kim Ryder', 'CLaudya Bella', 'Marsha Timothius', 'Nikita Williar',
    'Olgana Lydia', 'Paula Boeven', 'Ririn Ekawati', 'Sarah Sekunta', 'Tamara Blessing',
    'Uli Auliani'
  ];

  // ─────────────────────────────────────────────────────────
  // BIO TEMPLATES
  // ─────────────────────────────────────────────────────────
  static const List<String> bioTemplates = [
    'Anak Tuhan yang sedang mencari pasangan hidup seiman. Suka traveling dan kuliner.',
    'Pelayan Tuhan di gereja lokal. Hobi main musik dan baca buku rohani.',
    'Percaya bahwa Tuhan sudah siapkan jodoh terbaik. Coffee lover ☕',
    'Bekerja di bidang {profession}. Aktif di pelayanan pemuda gereja.',
    'Suka hiking dan explore alam ciptaan Tuhan. Looking for a godly partner.',
    'Passionate about worship music. Mencari teman hidup yang seiman.',
    'Sederhana, setia, dan takut akan Tuhan. Love dogs 🐕',
    'Introvert yang suka deep talk tentang iman dan kehidupan.',
    'Entrepreneur muda yang ingin membangun keluarga Kristen.',
    'Guru sekolah minggu. Suka anak-anak dan ingin punya keluarga.',
    'Work-life balance enthusiast. Prioritas: Tuhan, keluarga, karir.',
    'Foodie yang suka masak. Siap jadi partner hidup yang supportive.',
    'Cinephile dan bookworm. Mencari seseorang untuk diskusi film & buku.',
    'Fitness enthusiast. Believe in healthy body, healthy soul.',
    'Musisi gereja yang mencari duet partner seumur hidup 🎵',
    'Software engineer yang masih percaya cinta sejati ada.',
    'Medical professional. Caring inside out.',
    'Creative director. Suka hal-hal aesthetic dan meaningful.',
    'Accountant by profession, worship leader by passion.',
    'Teacher who believes in shaping future generations with faith.',
  ];

  static const List<String> professions = [
    'IT', 'perbankan', 'kesehatan', 'pendidikan', 'marketing',
    'keuangan', 'desain', 'engineering', 'retail', 'hospitality'
  ];

  // ─────────────────────────────────────────────────────────
  // FAITH ANSWER TEMPLATES
  // ─────────────────────────────────────────────────────────
  static const List<String> faithAnswers = [
    'Yesus Kristus adalah Tuhan dan Juruselamat pribadiku. Dia yang sudah menebus dosaku di kayu salib dan memberiku hidup yang kekal.',
    'Bagi saya, Yesus adalah segalanya. Dia adalah jalan, kebenaran, dan hidup. Tanpa Dia, hidup saya tidak akan bermakna.',
    'Yesus adalah sahabat terbaik yang selalu ada di saat suka dan duka. Dia mengubah hidup saya 180 derajat.',
    'Kristus adalah fondasi hidup saya. Saya sudah merasakan kasih-Nya yang luar biasa dalam setiap aspek kehidupan.',
    'Yesus adalah Raja di atas segala raja. Kasih-Nya tidak terbatas dan tidak bersyarat.',
    'Bagi saya Yesus adalah teladan sempurna bagaimana menjalani hidup dengan kasih dan kerendahan hati.',
    'Yesus Kristus adalah Anak Allah yang hidup, yang datang untuk menyelamatkan orang berdosa seperti saya.',
    'Dia adalah Gembala yang baik yang rela menyerahkan nyawa-Nya untuk domba-domba-Nya.',
    'Yesus adalah cahaya dalam kegelapan hidup saya. Dia memberikan harapan baru setiap hari.',
    'Kristus bukan hanya figur sejarah, tapi Tuhan yang hidup dan bekerja dalam kehidupan saya setiap hari.',
  ];

  // ─────────────────────────────────────────────────────────
  // KOTA-KOTA DI INDONESIA
  // ─────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> indonesianCities = [
    {'name': 'Jakarta', 'lat': -6.2088, 'lng': 106.8456},
    {'name': 'Surabaya', 'lat': -7.2575, 'lng': 112.7521},
    {'name': 'Bandung', 'lat': -6.9175, 'lng': 107.6191},
    {'name': 'Medan', 'lat': 3.5952, 'lng': 98.6722},
    {'name': 'Semarang', 'lat': -6.9666, 'lng': 110.4196},
    {'name': 'Makassar', 'lat': -5.1477, 'lng': 119.4327},
    {'name': 'Tangerang', 'lat': -6.1702, 'lng': 106.6403},
    {'name': 'Depok', 'lat': -6.4025, 'lng': 106.7942},
    {'name': 'Bekasi', 'lat': -6.2383, 'lng': 106.9756},
    {'name': 'Yogyakarta', 'lat': -7.7956, 'lng': 110.3695},
    {'name': 'Denpasar', 'lat': -8.6500, 'lng': 115.2167},
    {'name': 'Malang', 'lat': -7.9666, 'lng': 112.6326},
    {'name': 'Bogor', 'lat': -6.5971, 'lng': 106.8060},
    {'name': 'Manado', 'lat': 1.4748, 'lng': 124.8421},
    {'name': 'Balikpapan', 'lat': -1.2654, 'lng': 116.8313},
  ];

  // ─────────────────────────────────────────────────────────
  // GENERATE PHOTO URL
  // ─────────────────────────────────────────────────────────
  static String _getPhotoUrl(String gender, int index) {
    final folder = gender == 'male' ? 'men' : 'women';
    final photoNumbers = gender == 'male' ? malePhotoNumbers : femalePhotoNumbers;
    final photoNum = photoNumbers[index % photoNumbers.length];

    return 'https://firebasestorage.googleapis.com/v0/b/$_bucketName/o/dummy_photos%2F$folder%2F$photoNum.jpg?alt=media';
  }

  // ─────────────────────────────────────────────────────────
  // GENERATE ALL DUMMY USERS
  // ─────────────────────────────────────────────────────────
  static Future<void> generateAll({
    required BuildContext context,
    Function(int current, int total)? onProgress,
  }) async {
    final List<Map<String, dynamic>> users = [];

    // Generate pria (49 users)
    for (int i = 0; i < maleNames.length; i++) {
      users.add(_generateUser(
        name: maleNames[i],
        gender: 'male',
        photoIndex: i,
      ));
    }

    // Generate wanita (51 users)
    for (int i = 0; i < femaleNames.length; i++) {
      users.add(_generateUser(
        name: femaleNames[i],
        gender: 'female',
        photoIndex: i,
      ));
    }

    // Shuffle
    users.shuffle();

    // Upload ke Firestore
    int count = 0;
    for (final user in users) {
      try {
        final String gender = user['profile']['gender'];
        final String name = user['profile']['name'].toString().toLowerCase().replaceAll(' ', '_');
        final String uid = 'dummy_${gender}_$name';

        await _firestore.collection('profiles').doc(uid).set(user['profile']);
        await _firestore.collection('users').doc(uid).set(user['user']);
        await _firestore.collection('preferences').doc(uid).set(user['preferences']);

        count++;
        onProgress?.call(count, users.length);
        debugPrint('✅ Created $count/${users.length}: ${user['profile']['name']}');

        await Future.delayed(const Duration(milliseconds: 30));

      } catch (e) {
        debugPrint('❌ Error: $e');
      }
    }

    debugPrint('🎉 Done! Created $count dummy users.');
  }

  // ─────────────────────────────────────────────────────────
  // GENERATE SINGLE USER
  // ─────────────────────────────────────────────────────────
  static Map<String, dynamic> _generateUser({
    required String name,
    required String gender,
    required int photoIndex,
  }) {
    final city = indonesianCities[_random.nextInt(indonesianCities.length)];
    final age = 22 + _random.nextInt(18);
    final now = Timestamp.now();

    final daysAgo = _random.nextInt(14);
    final hoursAgo = _random.nextInt(24);
    final lastActive = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: daysAgo, hours: hoursAgo))
    );

    final photoUrl = _getPhotoUrl(gender, photoIndex);

    String bio = bioTemplates[_random.nextInt(bioTemplates.length)];
    if (bio.contains('{profession}')) {
      bio = bio.replaceAll('{profession}', professions[_random.nextInt(professions.length)]);
    }

    final faithAnswer = faithAnswers[_random.nextInt(faithAnswers.length)];

    final latOffset = (_random.nextDouble() - 0.5) * 0.1;
    final lngOffset = (_random.nextDouble() - 0.5) * 0.1;

    return {
      'profile': {
        'name': name,
        'email': '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
        'age': age,
        'gender': gender,
        'aboutMe': bio,
        'faithAnswer': faithAnswer,
        'photos': [photoUrl],
        'location': GeoPoint(city['lat'] + latOffset, city['lng'] + lngOffset),
        'isPremium': _random.nextDouble() < 0.1,
        'role': 'user',
        'createdAt': now,
        'updatedAt': now,
        'lastActiveAt': lastActive,
        'isVisible': true,
        'accountStatus': 'active',
      },
      'user': {
        'email': '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
        'isAdmin': false,
        'isPremium': _random.nextDouble() < 0.1,
        'isSuspended': false,
        'role': 'user',
        'createdAt': now,
      },
      'preferences': {
        'preferredGender': gender == 'male' ? 'female' : 'male',
        'ageMin': age - 5 < 18 ? 18 : age - 5,
        'ageMax': age + 10 > 60 ? 60 : age + 10,
        'maxDistanceKm': 50 + _random.nextInt(150),
      },
    };
  }

  // ─────────────────────────────────────────────────────────
  // DELETE ALL DUMMIES
  // ─────────────────────────────────────────────────────────
  static Future<void> deleteAllDummies({
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final profiles = await _firestore.collection('profiles').get();
      final dummyDocs = profiles.docs.where((doc) => doc.id.startsWith('dummy_')).toList();

      int count = 0;
      final total = dummyDocs.length;

      for (final doc in dummyDocs) {
        final uid = doc.id;

        await _firestore.collection('profiles').doc(uid).delete();
        await _firestore.collection('users').doc(uid).delete();
        await _firestore.collection('preferences').doc(uid).delete();

        try {
          await _firestore.collection('likes').doc(uid).delete();
          await _firestore.collection('passes').doc(uid).delete();
        } catch (_) {}

        count++;
        onProgress?.call(count, total);
      }

      debugPrint('🎉 Deleted $count dummy users.');
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }
}

// ============================================================
// WIDGET
// ============================================================

class DummyGeneratorWidget extends StatefulWidget {
  const DummyGeneratorWidget({super.key});

  @override
  State<DummyGeneratorWidget> createState() => _DummyGeneratorWidgetState();
}

class _DummyGeneratorWidgetState extends State<DummyGeneratorWidget> {
  bool _isGenerating = false;
  bool _isDeleting = false;
  int _progress = 0;
  int _total = 100;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  'Dummy Data Generator',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate 101 dummy users (50 pria, 51 wanita) dengan foto custom.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            if (_isGenerating || _isDeleting) ...[
              LinearProgressIndicator(
                value: _total > 0 ? _progress / _total : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isDeleting ? Colors.red : Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(_status, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating || _isDeleting ? null : _generate,
                    icon: const Icon(Icons.add),
                    label: const Text('Generate 101'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGenerating || _isDeleting ? null : _delete,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _progress = 0;
      _total = 101;
      _status = 'Starting...';
    });

    await DummyDataGenerator.generateAll(
      context: context,
      onProgress: (current, total) {
        setState(() {
          _progress = current;
          _total = total;
          _status = 'Creating $current of $total...';
        });
      },
    );

    setState(() {
      _isGenerating = false;
      _status = 'Done!';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 101 dummy users created!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Dummies?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _progress = 0;
      _status = 'Finding...';
    });

    await DummyDataGenerator.deleteAllDummies(
      onProgress: (current, total) {
        setState(() {
          _progress = current;
          _total = total;
          _status = 'Deleting $current of $total...';
        });
      },
    );

    setState(() {
      _isDeleting = false;
      _status = 'Done!';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ All dummies deleted!'), backgroundColor: Colors.orange),
      );
    }
  }
}