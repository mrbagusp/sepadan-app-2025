import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/services/auth_service.dart';
import 'package:sepadan/services/profile_service.dart';
import '../screens/match/match_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _profileIsComplete = false;
  bool _isLoading = true;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _checkProfileAndRole();
  }

  Future<void> _checkProfileAndRole() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authService = AuthService();
    final user = await authService.getUser();
    final profileService = ProfileService();
    final userProfile = await profileService.getUserProfile();
    final isComplete =
        userProfile != null &&
        userProfile.name.isNotEmpty &&
        userProfile.photos.isNotEmpty &&
        userProfile.age > 0;

    if (mounted) {
      setState(() {
        _profileIsComplete = isComplete;
        _userRole = user?.role ?? 'user';
        _isLoading = false;
      });
    }
  }

  // Allows profile page to trigger a refresh
  void onProfileUpdated() {
    _checkProfileAndRole();
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      context.go('/admin');
      return;
    }
    // Allow navigation to Explore (1) and Profile (3) anytime
    if (index == 1 || index == 3) {
       setState(() {
        _selectedIndex = index;
      });
      return;
    }

    // Block Match (0) and Chat (2) if profile is incomplete
    if (!_profileIsComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile to use this feature.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _userRole == 'admin';

    // Dynamically build the screens and navigation items
    final List<Widget> screens = [
      const MatchScreen(),
      const ExploreScreen(),
      const ChatListScreen(),
      ProfileScreen(onProfileUpdate: onProfileUpdated),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.favorite),
        label: 'Match',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore),
        label: 'Explore',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat),
        label: 'Chat',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
      if (isAdmin) 
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    // Adjust selected index if it's out of bounds after a role change
    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: navItems, // Use the dynamic list of items
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: _profileIsComplete || _selectedIndex == 1 || _selectedIndex == 3 
            ? Theme.of(context).primaryColor 
            : Colors.grey,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
