
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Premium Features'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Coming Soon!",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "We're preparing exciting new features to help you grow in your faith and community.",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            _buildFeatureTile(
              context,
              icon: Icons.book,
              title: 'Daily Devotional',
              subtitle: 'Start your day with inspiring scripture and reflections.',
            ),
            _buildFeatureTile(
              context,
              icon: Icons.support,
              title: 'Prayer Request',
              subtitle: 'Share your prayers and support others in the community.',
            ),
            _buildFeatureTile(
              context,
              icon: Icons.celebration,
              title: 'Testimonial',
              subtitle: 'Share your stories of faith and how God is working in your life.',
            ),
            _buildFeatureTile(
              context,
              icon: Icons.event,
              title: 'Events',
              subtitle: 'Find and join Christian events happening near you.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.lock, color: Colors.grey, size: 18),
      ),
    );
  }
}
