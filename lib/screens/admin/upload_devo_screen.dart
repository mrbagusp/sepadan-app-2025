
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadDevoScreen extends StatefulWidget {
  const UploadDevoScreen({super.key});

  @override
  State<UploadDevoScreen> createState() => _UploadDevoScreenState();
}

class _UploadDevoScreenState extends State<UploadDevoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _contentController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _uploadDevo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('daily_devos').add({
          'title': _titleController.text,
          'author': _authorController.text,
          'content': _contentController.text,
          'thumbnailUrl': _thumbnailUrlController.text,
          'createdAt': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily Devo uploaded successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Daily Devo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Author'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an author';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: 'Content'),
                    maxLines: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the content';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _thumbnailUrlController,
                    decoration: const InputDecoration(labelText: 'Thumbnail URL'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a thumbnail URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _uploadDevo,
                    child: const Text('Upload Devo'),
                  ),
                ],
              ),
            ),
    );
  }
}
