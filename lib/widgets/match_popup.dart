// ============================================================
// 📁 lib/widgets/match_popup.dart
// ✅ NEW: Tinder-style purple match popup with animations
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:confetti/confetti.dart';

class MatchPopup extends StatefulWidget {
  final String matchId;
  final UserProfile? currentUser;
  final UserProfile? matchedUser;
  final VoidCallback onDismiss;
  final Function(String message)? onSendMessage;

  const MatchPopup({
    super.key,
    required this.matchId,
    this.currentUser,
    this.matchedUser,
    required this.onDismiss,
    this.onSendMessage,
  });

  /// Show the match popup as a full-screen modal
  static Future<void> show(
    BuildContext context, {
    required String matchId,
    UserProfile? currentUser,
    UserProfile? matchedUser,
    VoidCallback? onDismiss,
    Function(String message)? onSendMessage,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MatchPopup(
          matchId: matchId,
          currentUser: currentUser,
          matchedUser: matchedUser,
          onDismiss: onDismiss ?? () => Navigator.of(context).pop(),
          onSendMessage: onSendMessage,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MatchPopup> createState() => _MatchPopupState();
}

class _MatchPopupState extends State<MatchPopup> with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _photoController;
  late AnimationController _textController;
  late ConfettiController _confettiController;
  
  final TextEditingController _messageController = TextEditingController();
  final List<String> _quickEmojis = ['👋', '😊', '❤️', '😍', '🙏', '✨'];
  
  bool _showMessageInput = false;

  @override
  void initState() {
    super.initState();
    
    // Heart pulse animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    // Photos slide in animation
    _photoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    // Text fade in animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Start text animation after photos
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });
    
    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    )..play();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _photoController.dispose();
    _textController.dispose();
    _confettiController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 🔥 Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B1FA2), // Deep Purple 700
                  const Color(0xFF9C27B0), // Purple 500
                  const Color(0xFFAB47BC), // Purple 400
                  const Color(0xFFBA68C8), // Purple 300
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
          
          // 🔥 Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.white,
                Colors.pink,
                Colors.amber,
                Colors.cyan,
                Colors.purple,
              ],
            ),
          ),
          
          // 🔥 Main content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDismiss();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Profile photos with heart
                _buildProfilePhotos(),
                
                const SizedBox(height: 32),
                
                // "It's a Match!" text
                _buildMatchText(),
                
                const SizedBox(height: 16),
                
                // Subtitle
                FadeTransition(
                  opacity: _textController,
                  child: Text(
                    'You and ${widget.matchedUser?.name ?? 'someone special'}\nhave liked each other!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Message section
                _buildMessageSection(),
                
                const SizedBox(height: 24),
                
                // Action buttons
                _buildActionButtons(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotos() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _photoController,
        curve: Curves.easeOutBack,
      )),
      child: FadeTransition(
        opacity: _photoController,
        child: SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Left photo (current user)
              Positioned(
                left: 60,
                child: _buildProfilePhoto(
                  photoUrl: widget.currentUser?.photos.isNotEmpty == true
                      ? widget.currentUser!.photos[0]
                      : null,
                  isLeft: true,
                ),
              ),
              
              // Right photo (matched user)
              Positioned(
                right: 60,
                child: _buildProfilePhoto(
                  photoUrl: widget.matchedUser?.photos.isNotEmpty == true
                      ? widget.matchedUser!.photos[0]
                      : null,
                  isLeft: false,
                ),
              ),
              
              // Center heart
              AnimatedBuilder(
                animation: _heartController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.9 + (_heartController.value * 0.2),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pink.shade400,
                            Colors.red.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto({String? photoUrl, required bool isLeft}) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.deepPurple.shade200,
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  Widget _buildMatchText() {
    return FadeTransition(
      opacity: _textController,
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE1BEE7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: const Text(
              "It's a Match!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSparkle(),
              const Text(
                '  💜  ',
                style: TextStyle(fontSize: 20),
              ),
              _buildSparkle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: const Text('✨', style: TextStyle(fontSize: 20)),
        );
      },
    );
  }

  Widget _buildMessageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Quick emoji row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _quickEmojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  _messageController.text += emoji;
                  setState(() => _showMessageInput = true);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Message input
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showMessageInput ? 56 : 56,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onTap: () => setState(() => _showMessageInput = true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Say something nice...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  if (_messageController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.deepPurple.shade600,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Keep Swiping button
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDismiss();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Keep Swiping',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Send Message / Chat button
          Expanded(
            child: ElevatedButton(
              onPressed: _goToChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chat_bubble_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Say Hello!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage?.call(message);
      _goToChat();
    }
  }

  void _goToChat() {
    Navigator.of(context).pop();
    context.go('/chat', extra: {
      'matchId': widget.matchId,
      'otherUser': widget.matchedUser,
    });
  }
}

// ============================================================
// 🔧 USAGE EXAMPLE:
// ============================================================
// 
// In match_screen.dart, replace _showMatchDialog with:
//
// void _showMatchDialog(BuildContext context, String matchId, UserProfile? matchedUser) {
//   MatchPopup.show(
//     context,
//     matchId: matchId,
//     matchedUser: matchedUser,
//     onDismiss: () {
//       // Optional: do something when dismissed
//     },
//   );
// }
//
// ============================================================
