import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Events'),
              Tab(text: 'Testimony'),
              Tab(text: 'Prayers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PendingList(collection: 'events', titleKey: 'title'),
                _PendingList(collection: 'testimonials', titleKey: 'story'),
                _PendingList(collection: 'prayer_requests', titleKey: 'title'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final String collection;
  final String titleKey;
  final AdminService _adminService = AdminService();

  _PendingList({required this.collection, required this.titleKey});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.streamPending(collection),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading content'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pending items.'));
        }

        final items = snapshot.data!.docs;

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final data = doc.data() as Map<String, dynamic>;
            final String title = data[titleKey] ?? 'No Content';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('ID: ${doc.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _adminService.approve(collection, doc.id),
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _adminService.reject(collection, doc.id),
                      tooltip: 'Reject/Delete',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
