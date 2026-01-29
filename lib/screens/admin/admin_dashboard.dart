import 'package:flutter/material.dart';
import 'user_management_screen.dart';
import 'moderation_screen.dart';
import 'daily_devo_management_screen.dart';
import 'payment_gateway_settings_screen.dart';
import 'tips_pdkt_management_screen.dart'; // Import baru
import 'dummy_data_generator.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Diubah dari 4 menjadi 5
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Panel',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Generate Dummy Users',
              onPressed: () => _showGenerateDialog(context),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people, color: Colors.white), text: 'Users'),
              Tab(icon: Icon(Icons.gavel, color: Colors.white), text: 'Moderation'),
              Tab(icon: Icon(Icons.book, color: Colors.white), text: 'Daily Devo'),
              Tab(icon: Icon(Icons.lightbulb, color: Colors.white), text: 'Tips PDKT'), // Tab Baru
              Tab(icon: Icon(Icons.payment, color: Colors.white), text: 'Payments'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserManagementScreen(),
            ModerationScreen(),
            DailyDevoManagementScreen(),
            TipsPdktManagementScreen(), // Halaman Baru
            PaymentGatewaySettingsScreen(),
          ],
        ),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Dummy Users'),
        content: const Text('Berapa banyak user dummy yang ingin Anda buat?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DummyDataGenerator.generateDummyUsers(context, 20);
            },
            child: const Text('Buat 20'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              DummyDataGenerator.generateDummyUsers(context, 40);
            },
            child: const Text('Buat 40'),
          ),
        ],
      ),
    );
  }
}
