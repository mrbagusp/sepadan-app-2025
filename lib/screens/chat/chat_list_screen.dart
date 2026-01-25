import 'package:flutter/material.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/chat_service.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  Future<List<(UserProfile, String)>>? _matchesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMatches();
  }

  void _refreshMatches() {
    setState(() {
      _matchesFuture = _chatService.getMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMatches,
          ),
        ],
      ),
      body: FutureBuilder<List<(UserProfile, String)>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            debugPrint("ChatListScreen Error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Gagal memuat matches.'),
                  TextButton(
                    onPressed: _refreshMatches,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, color: Colors.grey, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada matches',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Terus geser untuk menemukan pasangan!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final matches = snapshot.data!;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final user = matches[index].$1;
              final matchId = matches[index].$2;

              return ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: user.photos.isNotEmpty
                      ? NetworkImage(user.photos[0])
                      : null,
                  child: user.photos.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Ketuk untuk memulai chat'),
                onTap: () {
                   context.go(
                    '/chat',
                    extra: {
                      'matchId': matchId,
                      'otherUser': user,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
