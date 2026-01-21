
import 'package:flutter/material.dart';
import 'package:sepadan/screens/explore/daily_devo_screen.dart';
import 'package:sepadan/screens/explore/events_screen.dart';
import 'package:sepadan/screens/explore/prayer_request_screen.dart';
import 'package:sepadan/screens/explore/testimonials_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: ListView(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.book,
            title: 'Daily Devotional',
            subtitle: 'Start your day with inspiration',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DailyDevoScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.lightbulb,
            title: 'Testimonials',
            subtitle: 'Read stories of faith and transformation',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestimonialsScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.calendar_today,
            title: 'Events',
            subtitle: 'Find and join community events',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventsScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.volunteer_activism,
            title: 'Prayer Requests',
            subtitle: 'Share and pray for one another',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrayerRequestScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 40.0),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
