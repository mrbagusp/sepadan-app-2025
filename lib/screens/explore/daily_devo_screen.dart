import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/models/daily_devo.dart';
import 'package:sepadan/services/firestore_service.dart';
import 'package:sepadan/screens/explore/upgrade_screen.dart';

class DailyDevoScreen extends StatefulWidget {
  const DailyDevoScreen({super.key});

  @override
  State<DailyDevoScreen> createState() => _DailyDevoScreenState();
}

class _DailyDevoScreenState extends State<DailyDevoScreen> {
  @override
  Widget build(BuildContext context) {
    // Gracefully handle potential missing providers
    UserProfile? userProfile;
    FirestoreService? firestoreService;
    
    try {
      userProfile = Provider.of<UserProfile?>(context);
      firestoreService = Provider.of<FirestoreService>(context);
    } catch (_) {
      // Providers not found, will use dummy data
    }

    final bool isPremium = userProfile?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Devotional'),
      ),
      body: firestoreService == null 
        ? _buildDummyList()
        : StreamBuilder<List<DailyDevo>>(
            stream: isPremium 
                ? firestoreService.getDevotionals() 
                : firestoreService.getLatestDevotional(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildDummyList();
              }

              final devos = snapshot.data!;

              return ListView.builder(
                itemCount: devos.length + (isPremium ? 0 : 1), 
                itemBuilder: (context, index) {
                  if (!isPremium && index == devos.length) {
                    return _buildUpgradeCard(context);
                  }
                  
                  final devo = devos[index];
                  return _buildDevoCard(devo);
                },
              );
            },
          ),
    );
  }

  Widget _buildDevoCard(DailyDevo devo) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(devo.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8.0),
            Text('By ${devo.author}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8.0),
            Text(devo.content),
          ],
        ),
      ),
    );
  }

  Widget _buildDummyList() {
    return ListView(
      children: [
        _buildDevoCard(DailyDevo(
          id: 'dummy1',
          title: 'Berjalan dalam Kasih',
          content: 'Kasih adalah pengikat yang mempersatukan kita semua. Dalam perjalanan iman kita, mari kita belajar untuk saling mengasihi seperti Kristus telah mengasihi kita.',
          author: 'Admin Sepadan',
          date: DateTime.now(),
        )),
        _buildDevoCard(DailyDevo(
          id: 'dummy2',
          title: 'Kekuatan dalam Kesabaran',
          content: 'Menanti janji Tuhan memerlukan kesabaran yang luar biasa. Ingatlah bahwa waktu Tuhan selalu yang terbaik bagi hidup kita.',
          author: 'Admin Sepadan',
          date: DateTime.now().subtract(const Duration(days: 1)),
        )),
        _buildUpgradeCard(context),
      ],
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.lock_open, size: 40, color: Theme.of(context).colorScheme.onSecondaryContainer),
            const SizedBox(height: 16.0),
            Text(
              'Unlock All Devotionals',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Upgrade to a premium account to access our full library of daily devotionals and other exclusive content.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpgradeScreen()),
                );
              },
              child: const Text('Upgrade to Premium'),
            )
          ],
        ),
      ),
    );
  }
}
