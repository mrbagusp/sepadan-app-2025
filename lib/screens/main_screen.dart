import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sepadan/services/auth_service.dart';
import 'package:sepadan/services/profile_service.dart';
import '../screens/match/match_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_dashboard.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _profileIsComplete = false;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final uid = authService.currentUser?.uid;

      if (uid != null) {
        // 1. Ambil status Admin dari koleksi 'users'
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final userData = userDoc.data() ?? {};
        
        // 2. Ambil kelengkapan profil dari koleksi 'profiles'
        final userProfile = await ProfileService().getUserProfile();
        
        final isComplete = userProfile != null &&
            userProfile.name.isNotEmpty &&
            userProfile.photos.isNotEmpty &&
            userProfile.age > 0;

        if (mounted) {
          setState(() {
            _isAdmin = userData['isAdmin'] == true;
            _profileIsComplete = isComplete;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("MainScreen Init Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const MatchScreen(),
      const ExploreScreen(),
      const ChatListScreen(),
      ProfileScreen(onProfileUpdate: _initData),
      if (_isAdmin) const AdminDashboard(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Match'),
      const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
      const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      if (_isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
    ];

    int safeIndex = _selectedIndex;
    if (safeIndex >= screens.length) safeIndex = 0;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: safeIndex,
              children: screens,
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: navItems,
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
