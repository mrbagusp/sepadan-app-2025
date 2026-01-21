
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publicKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  bool _isLoading = true;

  // Document reference for the payment gateway settings
  final DocumentReference _settingsRef = FirebaseFirestore.instance.collection('config').doc('payment_gateway');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _publicKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final snapshot = await _settingsRef.get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _publicKeyController.text = data['publicKey'] ?? '';
        _secretKeyController.text = data['secretKey'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _settingsRef.set({
          'publicKey': _publicKeyController.text,
          'secretKey': _secretKeyController.text,
          'lastUpdated': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save settings: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _publicKeyController,
                    decoration: const InputDecoration(labelText: 'Public Key'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a public key';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _secretKeyController,
                    decoration: const InputDecoration(labelText: 'Secret Key'),
                    obscureText: true, // Hide the secret key
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a secret key';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
    );
  }
}
