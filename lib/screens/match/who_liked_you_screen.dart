// ============================================================
// 📁 lib/screens/match/who_liked_you_screen.dart
// ✅ NEW: See who liked you (Premium feature)
// - Free users: see count + blurred photos
// - Premium users: see full profiles + can like back
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/match_service.dart';
import 'package:sepadan/services/premium_service.dart';
import 'package:sepadan/screens/explore/upgrade_screen.dart';

class WhoLikedYouScreen extends StatefulWidget {
  const WhoLikedYouScreen({super.key});

  @override
  State<WhoLikedYouScreen> createState() => _WhoLikedYouScreenState();
}

class _WhoLikedYouScreenState extends State<WhoLikedYouScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MatchService _matchService = MatchService();
  final PremiumService _premiumService = PremiumService();

  List<UserProfile> _likedByUsers = [];
  bool _isLoading = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Check premium status
      _premiumService.getPremiumStatus().listen((status) {
        if (mounted) setState(() => _isPremium = status);
      });

      // Get users who liked current user
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      // Query: find all users who have liked the current user
      // Structure: likes/{otherUserId}/liked/{currentUserId}
      // We need to search across all users' liked subcollections
      // Alternative: use collectionGroup query
      final likedBySnapshot = await _firestore
          .collectionGroup('liked')
          .where(FieldPath.documentId, isEqualTo: currentUid)
          .get();

      // Get the parent document IDs (users who liked us)
      final Set<String> likerUids = {};
      for (final doc in likedBySnapshot.docs) {
        // Path: likes/{likerUid}/liked/{currentUid}
        final pathSegments = doc.reference.path.split('/');
        if (pathSegments.length >= 2) {
          likerUids.add(pathSegments[1]); // likerUid
        }
      }

      // Filter out users we've already matched with
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUid)
          .get();

      final Set<String> matchedUids = {};
      for (final doc in matchesSnapshot.docs) {
        final users = doc.data()['users'] as List<dynamic>;
        matchedUids.addAll(users.cast<String>());
      }

      // Remove already matched users
      likerUids.removeAll(matchedUids);
      likerUids.remove(currentUid);

      // Also remove users we've already liked (since that would have created a match)
      final myLikesSnapshot = await _firestore
          .collection('likes')
          .doc(currentUid)
          .collection('liked')
          .get();
      
      final Set<String> myLikedUids = myLikesSnapshot.docs.map((d) => d.id).toSet();
      likerUids.removeAll(myLikedUids);

      // Fetch profiles
      final List<UserProfile> profiles = [];
      for (final uid in likerUids) {
        try {
          final profileDoc = await _firestore.collection('profiles').doc(uid).get();
          if (profileDoc.exists) {
            profiles.add(UserProfile.fromFirestore(profileDoc));
          }
        } catch (e) {
          debugPrint('Error fetching profile $uid: $e');
        }
      }

      if (mounted) {
        setState(() {
          _likedByUsers = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading who liked you: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yang Menyukaimu'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedByUsers.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Header with count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_likedByUsers.length}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'orang menyukai profilmu!',
                            style: TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                          if (!_isPremium) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '🔒 Upgrade Premium untuk lihat siapa mereka!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Grid of users
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _likedByUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(_likedByUsers[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final hasPhoto = user.photos.isNotEmpty;
    final photoUrl = hasPhoto ? user.photos[0] : null;

    return GestureDetector(
      onTap: () {
        if (_isPremium) {
          _showProfileDetail(user);
        } else {
          _showUpgradePrompt();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              if (photoUrl != null)
                Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 60, color: Colors.grey),
                ),

              // ✅ BLUR for free users
              if (!_isPremium)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),

              // Bottom gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPremium ? '${user.name}, ${user.age}' : '???',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_isPremium)
                        Text(
                          user.gender == 'male' ? 'Pria' : 'Wanita',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Lock icon for free users
              if (!_isPremium)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.deepPurple,
                      size: 32,
                    ),
                  ),
                ),

              // ❤️ Like indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SHOW FULL PROFILE (Premium only)
  // ─────────────────────────────────────────────────────────
  void _showProfileDetail(UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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

            // Photo
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (user.photos.isNotEmpty)
                      SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: user.photos.length,
                          itemBuilder: (context, index) => Image.network(
                            user.photos[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.person, size: 80),
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.name}, ${user.age}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                user.gender == 'male' ? 'Pria' : 'Wanita',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          if (user.aboutMe.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Tentang',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.aboutMe,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Pass
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Lewati'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Like back
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _matchService.likeUser(user.uid);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('💕 Kamu menyukai ${user.name}! Match akan segera terbentuk!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadData(); // Refresh list
                        }
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('Suka Balik!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // UPGRADE PROMPT
  // ─────────────────────────────────────────────────────────
  void _showUpgradePrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open, color: Colors.amber, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Siapa yang Suka Kamu?', textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          'Upgrade ke Premium untuk melihat siapa yang menyukai profilmu dan langsung like balik!',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpgradeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Premium'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_border, size: 64, color: Colors.deepPurple.shade300),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada yang menyukaimu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Lengkapi profilmu dan tambahkan foto terbaik untuk menarik perhatian!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}