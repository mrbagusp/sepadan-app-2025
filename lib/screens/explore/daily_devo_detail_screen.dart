// ============================================================
// 📁 lib/screens/explore/daily_devo_detail_screen.dart
// ✅ FIXED: Bold/Italic formatting + Share functionality
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sepadan/models/daily_devo.dart';

class DailyDevoDetailScreen extends StatelessWidget {
  final DailyDevo devo;

  const DailyDevoDetailScreen({super.key, required this.devo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renungan Harian'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // ✅ Share button in AppBar
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareDevotional(context),
            tooltip: 'Bagikan',
          ),
        ],
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
            
            // Content with rich text formatting
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildRichContent(devo.content),
            ),
            
            // ✅ Share button (large)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareDevotional(context),
                  icon: const Icon(Icons.share),
                  label: const Text('Bagikan Renungan Ini'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  // ─────────────────────────────────────────────────────────
  // ✅ SHARE DEVOTIONAL WITH LOGO
  // ─────────────────────────────────────────────────────────
  Future<void> _shareDevotional(BuildContext context) async {
    // Clean content for sharing (remove HTML tags)
    final cleanContent = _cleanHtmlForShare(devo.content);
    
    // Build share message with branding
    final shareText = '''
📖 *${devo.title}*

${_formatDate(devo.date)}

$cleanContent

───────────────────
💍 *SEPADAN - Jodoh Kristen*
Temukan pasangan seiman yang sepadan denganmu!
Download di Google Play & App Store
''';

    try {
      // Share with logo image
      final byteData = await rootBundle.load('assets/logo.png');
      final tempDir = await getTemporaryDirectory();
      final logoFile = File('${tempDir.path}/sepadan_logo.png');
      await logoFile.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(logoFile.path)],
        text: shareText,
        subject: 'Renungan Harian: ${devo.title}',
      );
    } catch (e) {
      // Fallback: share text only if image fails
      debugPrint('Share with image failed: $e');
      await Share.share(
        shareText,
        subject: 'Renungan Harian: ${devo.title}',
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // Clean HTML for sharing (plain text)
  // ─────────────────────────────────────────────────────────
  String _cleanHtmlForShare(String html) {
    return html
        // Convert line breaks
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll('</p>', '\n\n')
        .replaceAll('<p>', '')
        // Bold tags - convert to markdown style for WhatsApp
        .replaceAllMapped(
          RegExp(r'<(b|strong)>(.*?)</\1>', caseSensitive: false, dotAll: true),
          (match) => '*${match.group(2)}*',
        )
        // Italic tags - convert to markdown style
        .replaceAllMapped(
          RegExp(r'<(i|em)>(.*?)</\1>', caseSensitive: false, dotAll: true),
          (match) => '_${match.group(2)}_',
        )
        // Remove remaining HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Clean HTML entities
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        // Clean up multiple newlines
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  // ─────────────────────────────────────────────────────────
  // Build rich content with bold, italic, and line breaks
  // ─────────────────────────────────────────────────────────
  Widget _buildRichContent(String content) {
    final lines = content
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll('</p>', '\n')
        .replaceAll('<p>', '')
        .split('\n');

    List<Widget> widgets = [];

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                color: Colors.black87,
              ),
              children: _parseInlineFormatting(line),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // ─────────────────────────────────────────────────────────
  // Parse inline formatting: <b>, </b>, <i>, </i>
  // ─────────────────────────────────────────────────────────
  List<TextSpan> _parseInlineFormatting(String text) {
    List<TextSpan> spans = [];
    
    final RegExp tagPattern = RegExp(
      r'<(b|strong|i|em)>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );

    int lastEnd = 0;
    
    for (final match in tagPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        final beforeText = _cleanHtmlEntities(text.substring(lastEnd, match.start));
        if (beforeText.isNotEmpty) {
          spans.add(TextSpan(text: beforeText));
        }
      }

      final tag = match.group(1)!.toLowerCase();
      final content = _cleanHtmlEntities(match.group(2) ?? '');
      
      TextStyle style;
      if (tag == 'b' || tag == 'strong') {
        style = const TextStyle(fontWeight: FontWeight.bold);
      } else if (tag == 'i' || tag == 'em') {
        style = const TextStyle(fontStyle: FontStyle.italic);
      } else {
        style = const TextStyle();
      }

      spans.add(TextSpan(text: content, style: style));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final remainingText = _cleanHtmlEntities(text.substring(lastEnd));
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(text: remainingText));
      }
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: _cleanHtmlEntities(text)));
    }

    return spans;
  }

  String _cleanHtmlEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id').format(date);
    } catch (e) {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }
}