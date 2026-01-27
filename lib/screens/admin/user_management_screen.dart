import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final String? currentAdminUid = authService.currentUser?.uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by email or UID...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _adminService.streamUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading users'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final users = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final email = (data['email'] ?? '').toString().toLowerCase();
                final uid = doc.id.toLowerCase();
                return email.contains(_searchQuery) || uid.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final data = userDoc.data() as Map<String, dynamic>;
                  final String uid = userDoc.id;
                  final String email = data['email'] ?? 'No Email';
                  final bool isPremium = data['isPremium'] ?? false;
                  final bool isSuspended = data['isSuspended'] ?? false;
                  
                  // 🔥 Cek apakah ini user dummy untuk menampilkan tombol Like
                  final bool isDummy = uid.contains('dummy');

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(email),
                      subtitle: Text('UID: ${uid.substring(0, 8)}...'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔥 TOMBOL SIMULASI LIKE (Hanya untuk Dummy)
                          if (isDummy && currentAdminUid != null)
                            IconButton(
                              icon: const Icon(Icons.thumb_up, color: Colors.blue),
                              onPressed: () async {
                                await _adminService.simulateLikeMe(uid, currentAdminUid);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$email liked you!')),
                                  );
                                }
                              },
                              tooltip: 'Simulate Like Me',
                            ),
                          
                          IconButton(
                            icon: Icon(Icons.star, color: isPremium ? Colors.amber : Colors.grey),
                            onPressed: () => _adminService.togglePremium(uid, !isPremium),
                            tooltip: 'Toggle Premium',
                          ),
                          IconButton(
                            icon: Icon(Icons.block, color: isSuspended ? Colors.red : Colors.grey),
                            onPressed: () => _adminService.toggleSuspended(uid, !isSuspended),
                            tooltip: 'Toggle Suspension',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.black54),
                            onPressed: () => _confirmDelete(context, uid),
                            tooltip: 'Delete Document',
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
      ],
    );
  }

  void _confirmDelete(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Data?'),
        content: const Text('This will delete the Firestore document only. The Auth account remains.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _adminService.deleteUser(uid);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
