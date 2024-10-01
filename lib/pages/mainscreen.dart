import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG usage
import 'package:mygamemaster/pages/game_cover.dart';
import 'homepage.dart';
import 'profile.dart';
import 'login.dart'; // Ensure you have the correct import for LoginPage
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const Profile(),
    const GameCoverPage(),
  ];

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors for light and dark mode
    final Color navBarColor = isDarkMode ? const Color(0xFF4A536B) : const Color(0xFF6B4226); // Parchment for light mode
    final Color backgroundColor = isDarkMode ? const Color.fromARGB(0, 255, 255, 255) : const Color.fromARGB(0, 255, 255, 255); // Dark/Light background

    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: _pages,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _pageIndex,
        height: 60.0,
        items: <Widget>[
          SvgPicture.asset(
            'assets/icons/home.svg',
            width: 40,
            height: 40,
          ),
          SvgPicture.asset(
            'assets/icons/swordsman.svg',
            width: 40,
            height: 40,
          ),
          SvgPicture.asset(
            'assets/icons/game.svg',
            width: 40,
            height: 40,
          ),
        ],
        color: navBarColor,
        buttonBackgroundColor: navBarColor, // Matches navigation bar color
        backgroundColor: backgroundColor,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
      ),
    );
  }
}
