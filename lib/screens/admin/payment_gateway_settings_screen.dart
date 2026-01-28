import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentGatewaySettingsScreen extends StatefulWidget {
  const PaymentGatewaySettingsScreen({super.key});

  @override
  _PaymentGatewaySettingsScreenState createState() => _PaymentGatewaySettingsScreenState();
}

class _PaymentGatewaySettingsScreenState extends State<PaymentGatewaySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _midtransClientKeyController = TextEditingController();
  final _midtransMerchantIdController = TextEditingController();
  final _ipaymuKeyController = TextEditingController();
  final _xenditKeyController = TextEditingController();
  
  bool _isSaving = false;
  String _activeGateway = 'midtrans';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('payment_gateway').get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _midtransClientKeyController.text = data['midtrans_client_key'] ?? '';
        _midtransMerchantIdController.text = data['midtrans_merchant_id'] ?? '';
        _ipaymuKeyController.text = data['ipaymu_key'] ?? '';
        _xenditKeyController.text = data['xendit_key'] ?? '';
        _activeGateway = data['active_gateway'] ?? 'midtrans';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('payment_gateway').set({
        'midtrans_client_key': _midtransClientKeyController.text.trim(),
        'midtrans_merchant_id': _midtransMerchantIdController.text.trim(),
        'ipaymu_key': _ipaymuKeyController.text.trim(),
        'xendit_key': _xenditKeyController.text.trim(),
        'active_gateway': _activeGateway,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway Setup', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white)))
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveSettings,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Gateway Aktif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _activeGateway,
                isExpanded: true,
                items: ['midtrans', 'ipaymu', 'xendit'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _activeGateway = val!),
              ),
              const SizedBox(height: 30),
              
              _buildSectionTitle('Midtrans Configuration'),
              _buildTextField(_midtransClientKeyController, 'Client Key'),
              _buildTextField(_midtransMerchantIdController, 'Merchant ID'),
              
              const SizedBox(height: 20),
              _buildSectionTitle('iPaymu Configuration'),
              _buildTextField(_ipaymuKeyController, 'API Key iPaymu'),
              
              const SizedBox(height: 20),
              _buildSectionTitle('Xendit Configuration'),
              _buildTextField(_xenditKeyController, 'Secret Key Xendit'),
              
              const SizedBox(height: 40),
              const Text(
                'Note: API keys are stored in your Firestore "settings" collection. In production, ensure these are used via Firebase Functions for security.',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
