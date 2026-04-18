import 'package:flutter/material.dart';
import '../search_page.dart';   // ✅
import '../wishlist_page.dart'; // ✅
import '../profile_page.dart';  // ✅
import '../home_page.dart';     // ✅

class UserHomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserHomePage({super.key, required this.userData});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F7), // Changed to light
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(userData: widget.userData),     // ✅ index 0
            const SearchPage(),   // ✅ index 1
            const WishlistPage(), // ✅ index 2
            ProfilePage(userData: widget.userData),  // ✅ index 3
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFE4252A), // kBrandRed
          unselectedItemColor: const Color(0xFF6B6B6B), // kTextMuted
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled),      label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search),            label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border),   label: 'Favorites'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline),    label: 'Profile'),
          ],
        ),
      ),
    );
  }
}