import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'upgrade_screen.dart';
import 'create_testimonial_screen.dart';

class TestimonialsScreen extends StatelessWidget {
  const TestimonialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile?>(context);
    final bool isAdmin = userProfile?.role == 'admin';
    final bool isPremium = userProfile?.isPremium ?? false;
    final bool hasFullAccess = isAdmin || isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('Testimonials')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('testimonials')
                  .where('approved', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return const Center(child: Text('Belum ada kesaksian. Bagikan milik Anda!'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: data['photoUrl'] != '' ? NetworkImage(data['photoUrl']) : null,
                              child: data['photoUrl'] == '' ? const Icon(Icons.person, size: 40) : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data['story'] ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '- ${data['name'] ?? 'Anonymous'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
            _showPremiumPopup(context);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTestimonialScreen()));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPremiumPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fitur Premium'),
        content: const Text('Jadilah member premium untuk membagikan kesaksian Anda.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
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
