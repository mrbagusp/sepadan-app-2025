import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentGatewaySettingsScreen extends StatefulWidget {
  const PaymentGatewaySettingsScreen({super.key});

  @override
  _PaymentGatewaySettingsScreenState createState() => _PaymentGatewaySettingsScreenState();
}

class _PaymentGatewaySettingsScreenState extends State<PaymentGatewaySettingsScreen> {
  Future<String> _getApiKeyStatus() async {
    try {
      final response = await http.get(Uri.parse('/api/admin/payment-gateway-key'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'];
      } else {
        return 'Error: Unable to fetch status';
      }
    } catch (e) {
      return 'Error: Could not connect to the server';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<String>(
          future: _getApiKeyStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Failed to load API Key status.'));
            }

            final status = snapshot.data!;
            final isKeySet = !status.contains('Not Set');

            return ListView(
              children: [
                ListTile(
                  leading: Icon(
                    isKeySet ? Icons.check_circle : Icons.warning,
                    color: isKeySet ? Colors.green : Colors.amber,
                  ),
                  title: const Text('API Key Status'),
                  subtitle: Text(status),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKeySet ? 'Update API Key' : 'Set API Key',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'To set or update the Payment Gateway API Key, please run the following command in your terminal. This keeps the key secure on the server.',
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const SelectableText(
                            'firebase functions:config:set payment.gateway_api_key="YOUR_API_KEY_HERE"',
                            style: TextStyle(fontFamily: 'monospace', backgroundColor: Colors.transparent),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'After running the command, you need to redeploy your functions for the changes to take effect:',
                        ),
                        const SizedBox(height: 12),
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const SelectableText(
                            'firebase deploy --only functions',
                             style: TextStyle(fontFamily: 'monospace', backgroundColor: Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
