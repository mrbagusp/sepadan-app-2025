import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';

class CreatePrayerScreen extends StatefulWidget {
  const CreatePrayerScreen({super.key});

  @override
  State<CreatePrayerScreen> createState() => _CreatePrayerScreenState();
}

class _CreatePrayerScreenState extends State<CreatePrayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isUrgent = false;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    final userProfile = Provider.of<UserProfile?>(context, listen: false);

    try {
      await FirebaseFirestore.instance.collection('prayer_requests').add({
        'title': _titleController.text.trim(),
        'details': _detailsController.text.trim(),
        'submittedBy': user?.uid,
        'userName': userProfile?.name ?? 'Anonymous',
        'status': 'pending',
        'approved': false, // Admin will approve
        'prayCount': 0,
        'comments': [],
        'isUrgent': _isUrgent,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permohonan doa terkirim dan menunggu persetujuan admin.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kirim Pokok Doa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Doa', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(labelText: 'Detail Permohonan', border: OutlineInputBorder()),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Detail tidak boleh kosong' : null,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Urgent / Mendesak'),
                value: _isUrgent,
                onChanged: (v) => setState(() => _isUrgent = v),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting ? const CircularProgressIndicator() : const Text('Kirim Sekarang'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
