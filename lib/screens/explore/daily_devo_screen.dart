// ============================================================
// 📁 lib/screens/explore/daily_devo_screen.dart
// ✅ FIXED: Only show today and past devotionals
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sepadan/models/daily_devo.dart';
import 'package:sepadan/screens/explore/upgrade_screen.dart';
import 'package:sepadan/screens/explore/daily_devo_detail_screen.dart';

class DailyDevoScreen extends StatefulWidget {
  const DailyDevoScreen({super.key});

  @override
  State<DailyDevoScreen> createState() => _DailyDevoScreenState();
}

class _DailyDevoScreenState extends State<DailyDevoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _hasFullAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        final profileDoc = await _firestore.collection('profiles').doc(uid).get();

        final isAdmin = userDoc.data()?['isAdmin'] == true;
        final isPremium = userDoc.data()?['isPremium'] == true ||
            profileDoc.data()?['isPremium'] == true;

        setState(() {
          _hasFullAccess = isAdmin || isPremium;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error checking access: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Devotional'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(child: _buildDevoList()),
          _buildPremiumBanner(),
        ],
      ),
    );
  }

  Widget _buildDevoList() {
    // Get end of today (23:59:59)
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('daily_devotionals')
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday)) // Only today and past
          .orderBy('date', descending: true)
          .limit(_hasFullAccess ? 50 : 3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Firestore error: ${snapshot.error}');
          return _buildErrorState('Gagal memuat renungan');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs;
        final devos = <DailyDevo>[];

        for (final doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            devos.add(DailyDevo(
              id: doc.id,
              title: data['title'] ?? 'Tanpa Judul',
              content: data['content'] ?? '',
              author: data['author'] ?? 'Admin',
              date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ));
          } catch (e) {
            debugPrint('Error parsing devo ${doc.id}: $e');
          }
        }

        if (devos.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: devos.length + (_hasFullAccess ? 0 : 1),
          itemBuilder: (context, index) {
            if (!_hasFullAccess && index == devos.length) {
              return _buildUpgradeCard();
            }
            return _buildDevoPreviewCard(devos[index]);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada renungan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Renungan harian akan segera tersedia.\nSilakan cek kembali nanti.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevoPreviewCard(DailyDevo devo) {
    final plainContent = _stripHtmlTags(devo.content);
    final preview = plainContent.length > 100
        ? '${plainContent.substring(0, 100)}...'
        : plainContent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openDevoDetail(devo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDate(devo.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                devo.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Author
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    devo.author,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Preview text
              Text(
                preview,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Read more
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Baca Selengkapnya',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.deepPurple.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.deepPurple.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDevoDetail(DailyDevo devo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyDevoDetailScreen(devo: devo),
      ),
    );
  }

  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final devoDate = DateTime(date.year, date.month, date.day);

    if (devoDate == today) {
      return 'Hari Ini';
    } else if (devoDate == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  Widget _buildUpgradeCard() {
    return Card(
      color: Colors.deepPurple.shade50,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open,
                size: 32,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock Semua Renungan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade ke Premium untuk akses seluruh koleksi renungan harian.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UpgradeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Upgrade ke Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.amber.shade100,
      child: const Text(
        'Become Premium Member to Support Ministry & Get More Blessings',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}