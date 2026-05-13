import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sepadan/services/premium_service.dart';

class PremiumUpsellScreen extends StatelessWidget {
  final String featureName;

  const PremiumUpsellScreen({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Membership')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.stars_rounded, size: 100, color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                'Buka Fitur $featureName',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Hanya seharga makan siang ${PremiumService.formattedPremiumPrice}/bulan, Anda telah melayani dan kiranya semakin banyak orang terberkati melalui Sepadan.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _buildFeatureItem(Icons.visibility, 'Lihat Siapa yang Suka Kamu'),
              _buildFeatureItem(Icons.swipe, 'Unlimited Swipe & Likes'),
              _buildFeatureItem(Icons.chat, 'Chat Tanpa Batas'),
              _buildFeatureItem(Icons.menu_book, 'Akses Seluruh Renungan Harian'),
              _buildFeatureItem(Icons.verified, 'Lencana Profil Terverifikasi'),
              _buildFeatureItem(Icons.block, 'Tanpa Iklan'),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.push('/payment'),
                child: const Text('UPGRADE SEKARANG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mungkin Nanti', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}