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
  final _ipaymuVaController = TextEditingController();
  final _xenditKeyController = TextEditingController();
  
  bool _isSaving = false;
  bool _isProduction = false;
  bool _isPremiumEnabled = false; // 🔥 NEW: Toggle Premium Status Global
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
        _midtransClientKeyController.text = data['midtransClientKey'] ?? '';
        _midtransMerchantIdController.text = data['midtransMerchantId'] ?? '';
        _ipaymuKeyController.text = data['ipaymuApiKey'] ?? '';
        _ipaymuVaController.text = data['ipaymuVa'] ?? '';
        _xenditKeyController.text = data['xenditSecretKey'] ?? '';
        _activeGateway = data['activeGateway'] ?? 'ipaymu';
        _isProduction = data['isProduction'] ?? false;
        _isPremiumEnabled = data['isPremiumEnabled'] ?? false; // 🔥 Load status
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('payment_gateway').set({
        'midtransClientKey': _midtransClientKeyController.text.trim(),
        'midtransMerchantId': _midtransMerchantIdController.text.trim(),
        'ipaymuApiKey': _ipaymuKeyController.text.trim(),
        'ipaymuVa': _ipaymuVaController.text.trim(),
        'xenditSecretKey': _xenditKeyController.text.trim(),
        'activeGateway': _activeGateway,
        'isProduction': _isProduction,
        'isPremiumEnabled': _isPremiumEnabled, // 🔥 Simpan status
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurasi Berhasil Disimpan!'), backgroundColor: Colors.green),
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
        title: const Text('Payment & Premium Settings', style: TextStyle(color: Colors.white)),
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
              _buildSectionTitle('GLOBAL PREMIUM STATUS'),
              Container(
                decoration: BoxDecoration(
                  color: _isPremiumEnabled ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isPremiumEnabled ? Colors.orange : Colors.green),
                ),
                child: SwitchListTile(
                  title: const Text('Aktifkan Fitur Berbayar', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_isPremiumEnabled 
                    ? 'Fitur premium terkunci (User harus bayar setelah trial)' 
                    : 'Masa Soft Launching: Semua fitur GRATIS selamanya'),
                  value: _isPremiumEnabled,
                  activeColor: Colors.orange,
                  onChanged: (val) => setState(() => _isPremiumEnabled = val),
                ),
              ),
              const SizedBox(height: 30),
              
              _buildSectionTitle('GATEWAY CONFIGURATION'),
              const Text('Pilih Gateway Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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
              
              _buildSectionTitle('iPaymu'),
              _buildTextField(_ipaymuKeyController, 'iPaymu API Key', isSecret: true),
              _buildTextField(_ipaymuVaController, 'iPaymu Virtual Account (VA)'),
              
              const SizedBox(height: 30),
              _buildSectionTitle('Midtrans'),
              _buildTextField(_midtransClientKeyController, 'Client Key'),
              _buildTextField(_midtransMerchantIdController, 'Merchant ID'),
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
