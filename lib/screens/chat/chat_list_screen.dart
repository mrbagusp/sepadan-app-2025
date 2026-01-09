
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
    _matchesFuture = _chatService.getMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: FutureBuilder<List<(UserProfile, String)>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading matches.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No matches yet. Keep swiping!'));
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
                // You could show the last message here by enhancing the getMatches function
                subtitle: const Text('Tap to chat'),
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
