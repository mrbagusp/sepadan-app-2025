import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DummyDataGenerator {
  static final List<String> _names = [
    'Budi Santoso', 'Sari Wijaya', 'Andi Pratama', 'Maria Ulfa', 'Kevin Christian',
    'Rina Permata', 'David Kurniawan', 'Linda Setia', 'Eko Saputra', 'Dewi Lestari',
    'Yanto Wijaya', 'Siska Amelia', 'Robby Hartono', 'Anita Putri', 'Ferry Irawan',
    'Yulia Citra', 'Agus Salim', 'Fitri Handayani', 'Hendra Gunawan', 'Santi Kurnia',
    'Samuel Hezkia', 'Rachel Maria', 'Timotius', 'Lydia', 'Paulus', 'Priskila',
    'Yosua', 'Debora', 'Gideon', 'Ester', 'Ishak', 'Ribka', 'Yusuf', 'Maria Magdalena',
    'Petrus', 'Yohanes', 'Matius', 'Lukas', 'Andreas', 'Filipus'
  ];

  static final List<String> _bios = [
    'Mencari pasangan yang takut akan Tuhan.',
    'Suka melayani di gereja.',
    'Hobi menyanyi lagu rohani.',
    'Ingin bertumbuh bersama dalam iman.',
    'Pecinta kopi dan diskusi teologi.',
    'Aktif di pelayanan kaum muda.',
    'Menyukai kegiatan sosial dan misi.',
    'Mencari sahabat hidup dalam Kristus.'
  ];

  static Future<void> generateDummyUsers(BuildContext context, int count) async {
    final firestore = FirebaseFirestore.instance;
    final random = Random();

    try {
      for (int i = 0; i < count; i++) {
        final String uid = 'dummy_user_${DateTime.now().millisecondsSinceEpoch}_$i';
        final String gender = i % 2 == 0 ? 'male' : 'female';
        final String name = _names[random.nextInt(_names.length)];
        
        await firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': 'dummy_${i}_${random.nextInt(1000)}@sepadan.com',
          'isAdmin': false,
          'isPremium': random.nextBool(),
          'isSuspended': false,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await firestore.collection('profiles').doc(uid).set({
          'name': name,
          'email': 'dummy$i@sepadan.com',
          'age': 20 + random.nextInt(20),
          'gender': gender,
          'aboutMe': _bios[random.nextInt(_bios.length)],
          'faithAnswer': 'Tuhan adalah segalanya bagi saya.',
          'location': const GeoPoint(-6.200000, 106.816666),
          'photos': ['https://i.pravatar.cc/400?u=$uid'],
          'isPremium': false,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await firestore.collection('preferences').doc(uid).set({
          'ageMin': 18,
          'ageMax': 50,
          'maxDistanceKm': 500,
          'preferredGender': gender == 'male' ? 'female' : 'male',
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count User Dummy Berhasil Dibuat!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat dummy: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
