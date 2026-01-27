import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyDevoManagementScreen extends StatefulWidget {
  const DailyDevoManagementScreen({super.key});

  @override
  State<DailyDevoManagementScreen> createState() => _DailyDevoManagementScreenState();
}

class _DailyDevoManagementScreenState extends State<DailyDevoManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitDevo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      String imageUrl = '';
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('daily_devos')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('daily_devotionals').add({
        'title': _titleController.text,
        'content': _contentController.text,
        'author': _authorController.text,
        'imageUrl': imageUrl,
        'date': Timestamp.fromDate(_selectedDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily Devotional added successfully!')),
        );
        _titleController.clear();
        _contentController.clear();
        _authorController.clear();
        setState(() {
          _imageFile = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Daily Devotional', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? 'Please enter title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? 'Please enter author' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
              maxLines: 8,
              validator: (val) => val!.isEmpty ? 'Please enter content' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Schedule Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Change Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40),
                          Text('Add Thumbnail Image'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitDevo,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Devotional'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
