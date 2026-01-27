import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/notifiers/premium_notifier.dart';
import 'package:sepadan/screens/premium/payment_screen.dart';

class PremiumUpsellScreen extends StatelessWidget {
  final String featureName;

  const PremiumUpsellScreen({
    super.key,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              'Unlock $featureName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Become a Premium Member to access unlimited features and support our ministry.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildBenefitItem(context, Icons.swipe, 'Unlimited Swipes'),
            _buildBenefitItem(context, Icons.chat, 'Unlimited Chats'),
            _buildBenefitItem(context, Icons.book, 'Full Daily Devotionals'),
            _buildBenefitItem(context, Icons.event, 'Create Community Events'),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentScreen()),
                );
              },
              child: const Text('Upgrade to Premium', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
