import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'upgrade_screen.dart';

class PrayerRequestScreen extends StatefulWidget {
  const PrayerRequestScreen({super.key});

  @override
  State<PrayerRequestScreen> createState() => _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends State<PrayerRequestScreen> {
  final List<Map<String, dynamic>> dummyPrayers = [
    {
      'title': 'Kesembuhan Orang Tua',
      'author': 'Andi',
      'details': 'Mohon doa untuk kesembuhan ayah saya yang sedang dirawat di RS karena sakit jantung.',
      'status': 'urgent',
      'prayCount': 12,
      'comments': ['Amin, Tuhan memberkati', 'Semangat bro Andi!'],
    },
    {
      'title': 'Pekerjaan Baru',
      'author': 'Sari',
      'details': 'Mohon dukungan doa agar proses interview pekerjaan saya besok berjalan lancar.',
      'status': 'normal',
      'prayCount': 5,
      'comments': ['Semoga lancar ya kak'],
    },
  ];

  final Map<int, TextEditingController> _commentControllers = {};

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
    final bool isPremium = userProfile?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Requests'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dummyPrayers.length,
              itemBuilder: (context, index) {
                final prayer = dummyPrayers[index];
                final bool isUrgent = prayer['status'] == 'urgent';
                
                if (!_commentControllers.containsKey(index)) {
                  _commentControllers[index] = TextEditingController();
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
                            Text(
                              prayer['title']!,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (isUrgent)
                              const Chip(
                                label: Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 10)),
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        Text('Oleh: ${prayer['author']}', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        Text(prayer['details']!),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  prayer['prayCount']++;
                                });
                              },
                              icon: const Icon(Icons.front_hand, size: 18),
                              label: Text('Mendoakan (${prayer['prayCount']})'),
                            ),
                          ],
                        ),
                        
                        const Divider(),
                        const Text('Komentar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ... (prayer['comments'] as List<String>).map((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('- $c', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        )).toList(),
                        
                        if (isPremium)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentControllers[index],
                                    decoration: const InputDecoration(
                                      hintText: 'Tulis komentar...',
                                      hintStyle: TextStyle(fontSize: 12),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send, color: Colors.blue, size: 20),
                                  onPressed: () {
                                    final val = _commentControllers[index]!.text;
                                    if (val.isNotEmpty) {
                                      setState(() {
                                        prayer['comments'].add(val);
                                        _commentControllers[index]!.clear();
                                      });
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
            ),
          ),
          _buildPremiumBanner(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!isPremium) {
            _showPremiumPopup();
          } else {
            // Flow submit prayer (premium only)
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
