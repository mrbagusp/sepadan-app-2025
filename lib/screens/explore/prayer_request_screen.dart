import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'upgrade_screen.dart';
import 'create_prayer_screen.dart';

class PrayerRequestScreen extends StatefulWidget {
  const PrayerRequestScreen({super.key});

  @override
  State<PrayerRequestScreen> createState() => _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends State<PrayerRequestScreen> {
  final Map<String, TextEditingController> _commentControllers = {};

  void _showPremiumPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fitur Premium'),
        content: const Text('Jadilah member premium untuk submit pokok doa'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
            },
            child: const Text('Upgrade Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile?>(context);
    final bool isAdmin = userProfile?.role == 'admin';
    final bool isPremium = userProfile?.isPremium ?? false;
    final bool hasFullAccess = isAdmin || isPremium;

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
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return const Center(child: Text('Belum ada pokok doa yang disetujui.'));
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

                    if (!_commentControllers.containsKey(prayerId)) {
                      _commentControllers[prayerId] = TextEditingController();
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isUrgent ? const BorderSide(color: Colors.red, width: 1) : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ),
                                if (isUrgent)
                                  const Chip(
                                    label: Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // 🔥 FIX: MENAMPILKAN NAMA USER DENGAN WARNA KONTRAS
                            Text(
                              'Oleh: ${data['userName'] ?? 'Anonymous'}', 
                              style: const TextStyle(
                                color: Colors.blueAccent, 
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data['details'] ?? '',
                              style: const TextStyle(color: Colors.black87, fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            
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
                            const Text('Komentar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                            ... comments.map((c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('- $c', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            )).toList(),
                            
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!hasFullAccess) {
            _showPremiumPopup();
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePrayerScreen()));
          }
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
        'Become Premium Member is Support Ministry to Get More Blessings',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }
}
