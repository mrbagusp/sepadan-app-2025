import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';

class CreateTestimonialScreen extends StatefulWidget {
  const CreateTestimonialScreen({super.key});

  @override
  State<CreateTestimonialScreen> createState() => _CreateTestimonialScreenState();
}

class _CreateTestimonialScreenState extends State<CreateTestimonialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storyController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    final userProfile = Provider.of<UserProfile?>(context, listen: false);

    try {
      await FirebaseFirestore.instance.collection('testimonials').add({
        'story': _storyController.text.trim(),
        'uid': user?.uid,
        'name': userProfile?.name ?? 'Anonymous',
        'photoUrl': userProfile?.photos.isNotEmpty == true ? userProfile?.photos[0] : '',
        'status': 'pending',
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kesaksian Anda telah terkirim dan akan ditinjau oleh admin.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bagikan Kesaksian')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Ceritakan kebaikan Tuhan dalam hidup Anda untuk menguatkan orang lain.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _storyController,
                decoration: const InputDecoration(labelText: 'Tulis Kesaksian Anda', border: OutlineInputBorder()),
                maxLines: 10,
                validator: (v) => v!.isEmpty ? 'Mohon tuliskan cerita Anda' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting ? const CircularProgressIndicator() : const Text('Bagikan Sekarang'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
