import 'package:flutter/material.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border,
              size: 64, color: kBrandRed.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('Favorites Page',
              style: TextStyle(color: kTextDark, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Your favorite items will appear here',
              style: TextStyle(color: kTextMuted, fontSize: 14)),
        ],
      ),
    );
  }
}