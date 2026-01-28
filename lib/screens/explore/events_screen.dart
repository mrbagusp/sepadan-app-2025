import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'upgrade_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final Map<String, TextEditingController> _commentControllers = {};

  void _showPremiumPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fitur Premium'),
        content: const Text('Upgrade to Premium to Add New Event'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile?>(context);
    final bool isAdmin = userProfile?.role == 'admin';
    final bool isPremium = userProfile?.isPremium ?? false;
    final bool hasFullAccess = isAdmin || isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('Community Events')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('approved', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Belum ada event mendatang.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String eventId = docs[index].id;
                    final String fullDesc = data['description'] ?? '';
                    final String displayDesc = !hasFullAccess && fullDesc.length > 100 
                        ? '${fullDesc.substring(0, 100)}...' 
                        : fullDesc;

                    if (!_commentControllers.containsKey(eventId)) {
                      _commentControllers[eventId] = TextEditingController();
                    }

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['imageUrl'] != null && data['imageUrl'] != '')
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.network(
                                data['imageUrl'],
                                height: 150, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(height: 150, color: Colors.grey[200], child: const Icon(Icons.event)),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(displayDesc, style: const TextStyle(fontSize: 14)),
                                if (!hasFullAccess && fullDesc.length > 100)
                                  TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen())),
                                    child: const Text('Read More (Upgrade Premium)'),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(data['location'] ?? '', style: const TextStyle(color: Colors.grey))),
                                  ],
                                ),
                                const Divider(),
                                const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ... (List<String>.from(data['comments'] ?? [])).map((c) => Text('- $c', style: const TextStyle(fontSize: 12))),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _commentControllers[eventId],
                                        decoration: const InputDecoration(hintText: 'Add a comment...', isDense: true),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send, size: 20, color: Colors.blue),
                                      onPressed: () {
                                        final txt = _commentControllers[eventId]!.text.trim();
                                        if (txt.isNotEmpty) {
                                          FirebaseFirestore.instance.collection('events').doc(eventId).update({
                                            'comments': FieldValue.arrayUnion([txt])
                                          });
                                          _commentControllers[eventId]!.clear();
                                        }
                                      },
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!hasFullAccess) {
            _showPremiumPopup();
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEventScreen()));
          }
        },
        label: const Text('Create New Event'),
        icon: const Icon(Icons.add),
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
