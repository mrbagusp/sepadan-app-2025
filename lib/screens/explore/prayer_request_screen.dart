// ============================================================
// 📁 lib/screens/explore/prayer_request_screen.dart
// ✅ FIXED: Sender name displayed next to "Oleh:"
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_prayer_screen.dart';

class PrayerRequestScreen extends StatefulWidget {
  const PrayerRequestScreen({super.key});

  @override
  State<PrayerRequestScreen> createState() => _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends State<PrayerRequestScreen> {
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Requests'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('prayer_requests')
                  .where('approved', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error: ${snapshot.error}', 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada pokok doa yang disetujui.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String prayerId = doc.id;
                    final bool isUrgent = data['isUrgent'] ?? false;
                    final List<String> comments = List<String>.from(data['comments'] ?? []);
                    final int prayCount = data['prayCount'] ?? 0;
                    
                    // ✅ Get sender name - check multiple possible fields
                    final String senderName = data['userName'] ?? 
                                               data['authorName'] ?? 
                                               data['name'] ?? 
                                               data['submittedBy'] ??
                                               'Anonim';

                    if (!_commentControllers.containsKey(prayerId)) {
                      _commentControllers[prayerId] = TextEditingController();
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isUrgent 
                            ? const BorderSide(color: Colors.red, width: 1) 
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Urgent badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold, 
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isUrgent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'URGENT', 
                                      style: TextStyle(
                                        color: Colors.white, 
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // ✅ FIXED: Sender name displayed properly
                            Row(
                              children: [
                                Text(
                                  'Oleh: ',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    senderName,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Prayer details
                            Text(
                              data['details'] ?? '',
                              style: const TextStyle(color: Colors.black87, fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            
                            // Pray button
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('prayer_requests')
                                        .doc(prayerId)
                                        .update({'prayCount': FieldValue.increment(1)});
                                  },
                                  icon: const Icon(Icons.front_hand, size: 18),
                                  label: Text('Mendoakan ($prayCount)'),
                                ),
                              ],
                            ),
                            
                            const Divider(),
                            
                            // Comments section
                            const Text(
                              'Komentar:', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12, 
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...comments.map((c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '- $c', 
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            )),
                            
                            // Comment input
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentControllers[prayerId],
                                      style: const TextStyle(color: Colors.black87),
                                      decoration: const InputDecoration(
                                        hintText: 'Tulis komentar...',
                                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Colors.blue, size: 20),
                                    onPressed: () {
                                      final val = _commentControllers[prayerId]!.text.trim();
                                      if (val.isNotEmpty) {
                                        FirebaseFirestore.instance
                                            .collection('prayer_requests')
                                            .doc(prayerId)
                                            .update({
                                          'comments': FieldValue.arrayUnion([val])
                                        });
                                        _commentControllers[prayerId]!.clear();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildPremiumBanner(),
        ],
      ),
      // ✅ FREE: Anyone can create prayer request
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const CreatePrayerScreen()),
          );
        },
        child: const Icon(Icons.add),
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
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }
}