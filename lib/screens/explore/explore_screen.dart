import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'daily_devo_screen.dart';
import 'prayer_request_screen.dart';
import 'events_screen.dart';
import 'testimonials_screen.dart';
import '../admin/admin_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Hub'),
        actions: [
          if (user != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  if (data['role'] == 'admin') {
                    return IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminScreen()),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuThumbnail(
            context,
            'Daily Devo',
            Icons.book,
            Colors.blue,
            const DailyDevoScreen(),
          ),
          _buildMenuThumbnail(
            context,
            'Prayer Requests',
            Icons.front_hand,
            Colors.green,
            const PrayerRequestScreen(),
          ),
          _buildMenuThumbnail(
            context,
            'Events',
            Icons.event,
            Colors.orange,
            const EventsScreen(),
          ),
          _buildMenuThumbnail(
            context,
            'Testimonials',
            Icons.favorite,
            Colors.red,
            const TestimonialsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuThumbnail(BuildContext context, String title, IconData icon, Color color, Widget targetScreen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
