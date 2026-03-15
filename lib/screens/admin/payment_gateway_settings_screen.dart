import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentGatewaySettingsScreen extends StatefulWidget {
  const PaymentGatewaySettingsScreen({super.key});

  @override
  _PaymentGatewaySettingsScreenState createState() => _PaymentGatewaySettingsScreenState();
}

class _PaymentGatewaySettingsScreenState extends State<PaymentGatewaySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _midtransClientKeyController = TextEditingController();
  final _midtransMerchantIdController = TextEditingController();
  final _ipaymuKeyController = TextEditingController();
  final _ipaymuVaController = TextEditingController(); // 🔥 NEW
  final _xenditKeyController = TextEditingController();
  
  bool _isSaving = false;
  bool _isProduction = false; // 🔥 NEW
  String _activeGateway = 'ipaymu';

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
        // 🔥 Sinkronisasi nama field dengan PremiumService
        _midtransClientKeyController.text = data['midtransClientKey'] ?? '';
        _midtransMerchantIdController.text = data['midtransMerchantId'] ?? '';
        _ipaymuKeyController.text = data['ipaymuApiKey'] ?? '';
        _ipaymuVaController.text = data['ipaymuVa'] ?? '';
        _xenditKeyController.text = data['xenditSecretKey'] ?? '';
        _activeGateway = data['activeGateway'] ?? 'ipaymu';
        _isProduction = data['isProduction'] ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // 🔥 Gunakan CamelCase agar sesuai dengan standard PremiumService.dart
      await FirebaseFirestore.instance.collection('settings').doc('payment_gateway').set({
        'midtransClientKey': _midtransClientKeyController.text.trim(),
        'midtransMerchantId': _midtransMerchantIdController.text.trim(),
        'ipaymuApiKey': _ipaymuKeyController.text.trim(),
        'ipaymuVa': _ipaymuVaController.text.trim(),
        'xenditSecretKey': _xenditKeyController.text.trim(),
        'activeGateway': _activeGateway,
        'isProduction': _isProduction,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurasi iPaymu Berhasil Disimpan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal Menyimpan: $e'), backgroundColor: Colors.red),
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
        title: const Text('Payment Gateway Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white)))
          else
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
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
              const Text('Gateway Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _activeGateway,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['midtrans', 'ipaymu', 'xendit'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _activeGateway = val!),
              ),
              const SizedBox(height: 20),
              
              SwitchListTile(
                title: const Text('Production Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isProduction ? 'Akun Riil (Live)' : 'Akun Percobaan (Sandbox)'),
                value: _isProduction,
                activeColor: Colors.green,
                onChanged: (val) => setState(() => _isProduction = val),
              ),
              
              const Divider(height: 40),
              
              _buildSectionTitle('iPaymu (REKOMENDASI)'),
              _buildTextField(_ipaymuKeyController, 'iPaymu API Key', isSecret: true),
              _buildTextField(_ipaymuVaController, 'iPaymu Virtual Account (VA)'),
              
              const SizedBox(height: 30),
              _buildSectionTitle('Midtrans (Optional)'),
              _buildTextField(_midtransClientKeyController, 'Client Key'),
              _buildTextField(_midtransMerchantIdController, 'Merchant ID'),
              
              const SizedBox(height: 30),
              _buildSectionTitle('Xendit (Optional)'),
              _buildTextField(_xenditKeyController, 'Secret Key', isSecret: true),
              
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pastikan API Key dan VA iPaymu sesuai dengan yang ada di Dashboard iPaymu Anda.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isSecret = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isSecret,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(isSecret ? Icons.vpn_key : Icons.badge),
        ),
      ),
    );
  }
}
