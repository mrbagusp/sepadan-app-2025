import 'package:flutter/material.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/chat_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final DateTime dateTime = (timestamp as dynamic).toDate();
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getMatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final bool hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
          
          if (!hasData) {
            // Log error if any, but show empty state UI
            if (snapshot.hasError) {
              debugPrint("ChatList Error: ${snapshot.error}");
            }
            
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, color: Colors.grey, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada matches', 
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)
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
              final match = matches[index];
              final UserProfile user = match['profile'];
              final String matchId = match['matchId'];
              final String lastMsg = match['lastMessage'];
              final String time = _formatTimestamp(match['lastMessageTimestamp']);

              return ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: user.photos.isNotEmpty ? NetworkImage(user.photos[0]) : null,
                  child: user.photos.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                   context.go('/chat', extra: {'matchId': matchId, 'otherUser': user});
                },
              );
            },
          );
        },
      ),
    );
  }
}
