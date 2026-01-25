import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'upgrade_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // Dummy Data with images and descriptions
  final List<Map<String, dynamic>> dummyEvents = [
    {
      'title': 'KKR Pemuda Sepadan',
      'date': '25 Mar 2025, 18:00',
      'location': 'Gedung Serbaguna Jakarta',
      'category': 'Ibadah',
      'description': 'Kebaktian Kebangunan Rohani khusus untuk pemuda-pemudi Kristen yang rindu akan api kegerakan Tuhan di generasi ini.',
      'imageUrl': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=1470&auto=format&fit=crop',
      'comments': ['Saya akan datang!', 'Amin.'],
    },
    {
      'title': 'Seminar Pranikah Online',
      'date': '02 Apr 2025, 10:00',
      'location': 'Zoom Cloud Meetings',
      'category': 'Seminar',
      'description': 'Mempersiapkan pernikahan Kristen yang kokoh berdasarkan Firman Tuhan di tengah tantangan zaman modern.',
      'imageUrl': 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?q=80&w=1470&auto=format&fit=crop',
      'comments': ['Link Zoom-nya di mana?', 'Sangat membantu.'],
    },
  ];

  void _showPremiumPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fitur Premium'),
        content: const Text('Upgrade to Premium to Add New Event'),
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
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile?>(context);
    final bool isPremium = userProfile?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Events'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dummyEvents.length,
              itemBuilder: (context, index) {
                final event = dummyEvents[index];
                final String fullDesc = event['description']!;
                
                // Partial reading for non-premium
                final String displayDesc = !isPremium && fullDesc.length > 100 
                    ? '${fullDesc.substring(0, 100)}...' 
                    : fullDesc;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.network(
                          event['imageUrl']!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(event['category']!, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                Text(event['date']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(event['title']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(displayDesc, style: const TextStyle(fontSize: 14)),
                            if (!isPremium && fullDesc.length > 100)
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen())),
                                child: const Text('Read More (Upgrade Premium)'),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(event['location']!, style: const TextStyle(color: Colors.grey))),
                              ],
                            ),
                            if (isPremium) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                                ],
                              ),
                            ],
                            const Divider(),
                            const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ... (event['comments'] as List<String>).map((c) => Text('- $c', style: const TextStyle(fontSize: 12))),
                            TextField(
                              decoration: const InputDecoration(hintText: 'Add a comment...', hintStyle: TextStyle(fontSize: 12)),
                              onSubmitted: (val) {
                                if (val.isNotEmpty) {
                                  setState(() {
                                    event['comments'].add(val);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildPremiumBanner(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!isPremium) {
            _showPremiumPopup();
          } else {
            // Navigate to Create Event Page
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
