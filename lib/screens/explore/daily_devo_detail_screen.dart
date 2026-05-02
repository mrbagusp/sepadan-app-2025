// ============================================================
// 📁 lib/screens/explore/daily_devo_detail_screen.dart
// ✅ SIMPLE VERSION - No complex parsing
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sepadan/models/daily_devo.dart';

class DailyDevoDetailScreen extends StatelessWidget {
  final DailyDevo devo;

  const DailyDevoDetailScreen({super.key, required this.devo});

  @override
  Widget build(BuildContext context) {
    // Clean content - remove HTML tags
    final cleanContent = _cleanHtml(devo.content);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renungan Harian'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.deepPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDate(devo.date),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    devo.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Author
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        devo.author,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                cleanContent,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: Colors.black87,
                ),
              ),
            ),

            // Back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _cleanHtml(String html) {
    // Replace HTML tags with readable format
    String cleaned = html
    // Line breaks
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll('</p>', '\n\n')
        .replaceAll('<p>', '')
    // Bold tags - convert to readable format
        .replaceAll('<b>', '')
        .replaceAll('</b>', '')
        .replaceAll('<strong>', '')
        .replaceAll('</strong>', '')
    // Italic tags
        .replaceAll('<i>', '')
        .replaceAll('</i>', '')
        .replaceAll('<em>', '')
        .replaceAll('</em>', '')
    // Other common tags
        .replaceAll('<div>', '')
        .replaceAll('</div>', '\n')
        .replaceAll('<span>', '')
        .replaceAll('</span>', '')
    // HTML entities
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
    // Remove any remaining HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
    // Clean up multiple newlines
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return cleaned;
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id').format(date);
    } catch (e) {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }
}