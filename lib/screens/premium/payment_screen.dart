import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/notifiers/premium_notifier.dart';
import 'package:go_router/go_router.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Complete Your Subscription',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Total Amount: Rp 99.000 / month',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              if (_isProcessing)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() => _isProcessing = true);
                    
                    // Simulate network delay
                    await Future.delayed(const Duration(seconds: 2));
                    
                    if (mounted) {
                      await context.read<PremiumNotifier>().upgradeToPremium();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment Successful! You are now Premium.'), backgroundColor: Colors.green),
                        );
                        context.go('/main');
                      }
                    }
                  },
                  child: const Text('Simulate Success (Upgrade Now)'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
