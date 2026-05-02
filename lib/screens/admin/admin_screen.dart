import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sepadan/screens/admin/dummy_data_generator.dart';


class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: ListView(
        children: [
          // 🔥 TAMBAHKAN INI
          const DummyGeneratorWidget(),

          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Content Moderation'),
            onTap: () => context.go('/admin/content-moderation'),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('User Management'),
            onTap: () => context.go('/admin/user-management'),
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Payment Gateway Settings'),
            onTap: () => context.go('/admin/payment-gateway-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('Daily Devo Management'),
            onTap: () => context.go('/admin/daily-devo-management'),
          ),
        ],
      ),
    );
  }
}