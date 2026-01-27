import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/screens/match/match_notifier.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  @override
  void initState() {
    super.initState();
    // Memastikan pengambilan data dilakukan saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MatchNotifier>().fetchPotentialMatches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchNotifier>(
      builder: (context, notifier, child) {
        // Handle dialog jika terjadi mutual match
        if (notifier.isMutualMatch && notifier.matchedUser != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMatchDialog(context, notifier, notifier.matchedUser!);
            notifier.resetMutualMatch();
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Find Your Match'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => notifier.fetchPotentialMatches(),
              ),
            ],
          ),
          body: _buildBody(context, notifier),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MatchNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No more profiles found.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const Text(
                'Try adjusting your preferences or click refresh!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => notifier.fetchPotentialMatches(),
                child: const Text('Refresh Search'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            cardsCount: notifier.profiles.length,
            // 🔥 FIX: Ensure numberOfCardsDisplayed is within bounds
            numberOfCardsDisplayed: min(notifier.profiles.length, 3),
            onSwipe: (previousIndex, currentIndex, direction) {
              final didLike = direction == CardSwiperDirection.right;
              notifier.swipe(previousIndex, didLike);
              return true;
            },
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              final profile = notifier.profiles[index];
              return _buildProfileCard(context, profile);
            },
            allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
          ),
        ),
        _buildActionButtons(context, notifier),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, UserProfile profile) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (profile.photos.isNotEmpty)
            Image.network(
              profile.photos[0],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 100, color: Colors.white),
              ),
            ),

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.6, 1.0],
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.name}, ${profile.age}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.aboutMe,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MatchNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(context, Icons.close, Colors.red, () {
           notifier.swipe(0, false);
        }),
        _buildActionButton(context, CupertinoIcons.heart_fill, Colors.green, () {
          notifier.swipe(0, true);
        }),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 5,
      ),
      child: Icon(icon, color: color, size: 35),
    );
  }

  void _showMatchDialog(BuildContext context, MatchNotifier notifier, UserProfile matchedUser) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("It's a Match!", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("You and ${matchedUser.name} have liked each other."),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const CircleAvatar(radius: 40, child: Icon(Icons.person)),
                const Icon(CupertinoIcons.heart_fill, color: Colors.red, size: 30),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: matchedUser.photos.isNotEmpty ? NetworkImage(matchedUser.photos[0]) : null,
                  child: matchedUser.photos.isEmpty ? const Icon(Icons.person) : null,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Say Hello!'),
            onPressed: () {
                Navigator.of(dialogContext).pop();
                // 🔥 FIX: Ensure matchId is not null
                final mId = notifier.matchId;
                if (mId != null) {
                  context.go(
                    '/chat',
                    extra: {
                      'matchId': mId,
                      'otherUser': matchedUser,
                    },
                  );
                }
            },
          ),
          TextButton(
            child: const Text('Keep Swiping'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }
}
