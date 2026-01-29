import 'package:flutter/material.dart';
import 'package:sepadan/screens/premium/payment_screen.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Membership'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.star, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                'SUPPORT MINISTRY AND GET MORE BLESSINGS',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Dengan menjadi member premium anda telah mendukung pelayanan SEPADAN dan akan mendapatkan benefit sebagai berikut:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildBenefitItem(context, Icons.swipe, '1. Unlimited Swipe'),
              _buildBenefitItem(context, Icons.chat, '2. Unlimited chat'),
              _buildBenefitItem(context, Icons.notifications_active, '3. Mendapatkan renungan harian dan notifikasi setiap pagi'),
              _buildBenefitItem(context, Icons.event, '4. Bisa membaca full dan submit new events'),
              _buildBenefitItem(context, Icons.front_hand, '5. Bisa membaca full dan submit prayer request'),
              _buildBenefitItem(context, Icons.favorite, '6. Bisa membaca dan submit new testimonial. Kisah hidup Anda bisa menjadi harapan bagi orang lain.'),
              const SizedBox(height: 32),
              const Text(
                'Hanya seharga makan siang Rp.24,000/bulan, Anda telah melayani dan kiranya semakin terbuka jalan untuk menemukan jodoh Anda didalam Tuhan',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                'UPGRADE MEMBERSHIP ANDA SEKARANG!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentScreen()),
                  );
                },
                child: const Text('Pay Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
