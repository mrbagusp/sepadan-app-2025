// ============================================================
// 📁 lib/screens/match/match_screen.dart
// ✅ REDESIGNED: Tinder-style full screen layout
// ============================================================

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/screens/match/match_notifier.dart';
import 'package:sepadan/widgets/match_popup.dart';
import 'package:sepadan/services/match_service.dart';
import 'package:sepadan/services/profile_service.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with WidgetsBindingObserver {
  final CardSwiperController _controller = CardSwiperController();
  final MatchService _matchService = MatchService();

  // Track current photo index for each profile
  final Map<String, int> _currentPhotoIndex = {};

  // Current user's location for distance calculation
  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MatchNotifier>().fetchPotentialMatches(clearExisting: true);
        _matchService.updateLastActive();
        _loadCurrentUserProfile();
      }
    });
  }

  Future<void> _loadCurrentUserProfile() async {
    final profile = await ProfileService().getUserProfile();
    if (mounted) {
      setState(() {
        _currentUserProfile = profile;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _matchService.updateLastActive();
    }
  }

  String _calculateDistance(UserProfile profile) {
    if (_currentUserProfile?.location == null || profile.location == null) {
      return '';
    }

    try {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentUserProfile!.location!.latitude,
        _currentUserProfile!.location!.longitude,
        profile.location!.latitude,
        profile.location!.longitude,
      );

      final distanceKm = distanceInMeters / 1000;

      if (distanceKm < 1) {
        return '< 1 km';
      } else if (distanceKm < 10) {
        return '${distanceKm.toStringAsFixed(1)} km';
      } else {
        return '${distanceKm.round()} km';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Make status bar icons light (white) for dark background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Consumer<MatchNotifier>(
      builder: (context, notifier, child) {
        if (notifier.hasNewMatch && notifier.latestMatchId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              MatchPopup.show(
                context,
                matchId: notifier.latestMatchId!,
                matchedUser: notifier.latestMatchedUser,
                onDismiss: () {
                  notifier.resetMatchNotification();
                },
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: _buildBody(context, notifier),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MatchNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (notifier.profiles.isEmpty) {
      return _buildEmptyState(notifier);
    }

    return Stack(
      children: [
        // Full screen card swiper
        Positioned.fill(
          child: CardSwiper(
            controller: _controller,
            cardsCount: notifier.profiles.length,
            numberOfCardsDisplayed: min(notifier.profiles.length, 2),
            backCardOffset: const Offset(0, 0),
            padding: EdgeInsets.zero,
            onSwipe: (previousIndex, currentIndex, direction) {
              final didLike = direction == CardSwiperDirection.right;
              notifier.swipe(previousIndex ?? 0, didLike);
              return true;
            },
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              final profile = notifier.profiles[index];
              return _buildFullScreenCard(context, profile, percentThresholdX.toDouble());
            },
            allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
          ),
        ),

        // Action buttons at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildActionButtons(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(MatchNotifier notifier) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No more profiles',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try expanding your preferences\nor check back later!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => notifier.fetchPotentialMatches(clearExisting: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenCard(BuildContext context, UserProfile profile, double percentThresholdX) {
    final likeOpacity = percentThresholdX > 0 ? (percentThresholdX / 100).clamp(0.0, 1.0) : 0.0;
    final nopeOpacity = percentThresholdX < 0 ? (-percentThresholdX / 100).clamp(0.0, 1.0) : 0.0;

    // Get current photo index for this profile
    final currentIndex = _currentPhotoIndex[profile.uid] ?? 0;
    final distance = _calculateDistance(profile);

    return GestureDetector(
      onTapUp: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final tapX = details.globalPosition.dx;

        if (profile.photos.length > 1) {
          if (tapX < screenWidth / 3) {
            // Tap left - previous photo
            setState(() {
              _currentPhotoIndex[profile.uid] =
                  (currentIndex - 1).clamp(0, profile.photos.length - 1);
            });
          } else if (tapX > screenWidth * 2 / 3) {
            // Tap right - next photo
            setState(() {
              _currentPhotoIndex[profile.uid] =
                  (currentIndex + 1).clamp(0, profile.photos.length - 1);
            });
          } else {
            // Tap center - show full profile
            _showProfileBottomSheet(context, profile);
          }
        } else {
          // Single photo - tap anywhere to show profile
          _showProfileBottomSheet(context, profile);
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full screen photo
            if (profile.photos.isNotEmpty)
              Image.network(
                profile.photos[currentIndex.clamp(0, profile.photos.length - 1)],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPhotoLoading();
                },
              )
            else
              _buildPhotoPlaceholder(),

            // Photo indicators (top bar like Tinder)
            if (profile.photos.length > 1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                child: Row(
                  children: List.generate(
                    profile.photos.length,
                        (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index == currentIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Gradient overlay at bottom for text readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Profile info overlay (Name, Age, Distance, About Me)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110, // Space for action buttons
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name & Age row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      if (profile.isOnlineNow) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Distance
                  if (distance.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white.withOpacity(0.85),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // About Me
                  if (profile.aboutMe.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      profile.aboutMe,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // LIKE overlay
            if (likeOpacity > 0)
              Positioned.fill(
                child: Opacity(
                  opacity: likeOpacity,
                  child: Container(
                    color: Colors.green.withOpacity(0.2),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 50,
                          left: 24,
                        ),
                        child: Transform.rotate(
                          angle: -0.3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LIKE',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // NOPE overlay
            if (nopeOpacity > 0)
              Positioned.fill(
                child: Opacity(
                  opacity: nopeOpacity,
                  child: Container(
                    color: Colors.red.withOpacity(0.2),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 50,
                          right: 24,
                        ),
                        child: Transform.rotate(
                          angle: 0.3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NOPE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.person, size: 120, color: Colors.grey),
      ),
    );
  }

  Widget _buildPhotoLoading() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo
          _buildCircleButton(
            icon: Icons.replay,
            color: Colors.amber,
            size: 48,
            iconSize: 22,
            onPressed: () => _controller.undo(),
          ),

          // NOPE
          _buildCircleButton(
            icon: Icons.close,
            color: Colors.red,
            size: 64,
            iconSize: 32,
            onPressed: () => _controller.swipe(CardSwiperDirection.left),
          ),

          // Super Like
          _buildCircleButton(
            icon: Icons.star,
            color: Colors.blue,
            size: 48,
            iconSize: 22,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Super Like coming soon!')),
              );
            },
          ),

          // LIKE
          _buildCircleButton(
            icon: CupertinoIcons.heart_fill,
            color: Colors.green,
            size: 64,
            iconSize: 32,
            onPressed: () => _controller.swipe(CardSwiperDirection.right),
          ),

          // Boost
          _buildCircleButton(
            icon: Icons.flash_on,
            color: Colors.purple,
            size: 48,
            iconSize: 22,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Boost coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BOTTOM SHEET: Full Profile View
  // ─────────────────────────────────────────────────────────
  void _showProfileBottomSheet(BuildContext context, UserProfile profile) {
    final distance = _calculateDistance(profile);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Gallery
                      SizedBox(
                        height: 450,
                        child: PageView.builder(
                          itemCount: profile.photos.isEmpty ? 1 : profile.photos.length,
                          itemBuilder: (context, index) {
                            if (profile.photos.isEmpty) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 100, color: Colors.grey),
                              );
                            }
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  profile.photos[index],
                                  fit: BoxFit.cover,
                                ),
                                if (profile.photos.length > 1)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${index + 1}/${profile.photos.length}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name & Age
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${profile.name}, ${profile.age}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (profile.isOnlineNow)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Online',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),

                            // Distance
                            if (distance.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.grey[600], size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    distance,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 24),

                            // About Me
                            _buildSectionTitle('About Me'),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                profile.aboutMe.isNotEmpty ? profile.aboutMe : 'No description provided.',
                                style: const TextStyle(fontSize: 16, height: 1.6),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Faith Answer
                            _buildSectionTitle('Who is Jesus Christ to me?'),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.deepPurple.shade50, Colors.purple.shade50],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.format_quote, color: Colors.deepPurple.shade300),
                                  const SizedBox(height: 8),
                                  Text(
                                    profile.faithAnswer.isNotEmpty ? profile.faithAnswer : 'No answer provided.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      height: 1.6,
                                      color: Colors.deepPurple.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _controller.swipe(CardSwiperDirection.left);
                                    },
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    label: const Text('NOPE', style: TextStyle(color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.red, width: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _controller.swipe(CardSwiperDirection.right);
                                    },
                                    icon: const Icon(Icons.favorite),
                                    label: const Text('LIKE'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}