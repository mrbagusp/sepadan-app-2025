import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TipsPdktManagementScreen extends StatefulWidget {
  const TipsPdktManagementScreen({super.key});

  @override
  State<TipsPdktManagementScreen> createState() => _TipsPdktManagementScreenState();
}

class _TipsPdktManagementScreenState extends State<TipsPdktManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  void _insertFormatting(String tag) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start == -1) return;

    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(selection.start, selection.end, '<$tag>$selectedText</$tag>');

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + tag.length + 2 + selectedText.length + tag.length + 3),
    );
  }

  Future<void> _submitTip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('dating_tips').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tips PDKT berhasil ditambahkan!')));
        _titleController.clear();
        _contentController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Tips PDKT Baru', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Tips', 
                labelStyle: TextStyle(color: Colors.black54),
                filled: true, 
                fillColor: Colors.black12,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.black),
              validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.format_bold, color: Colors.black), onPressed: () => _insertFormatting('b')),
                IconButton(icon: const Icon(Icons.format_italic, color: Colors.black), onPressed: () => _insertFormatting('i')),
              ],
            ),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Konten Artikel', 
                labelStyle: TextStyle(color: Colors.black54),
                filled: true, 
                fillColor: Colors.black12, 
                hintText: 'Gunakan <b>tebal</b> dan <i>miring</i>',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.black),
              maxLines: 10,
              validator: (v) => v!.isEmpty ? 'Konten wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _submitTip,
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Tips'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
