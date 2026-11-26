/// Main application shell with playful bottom navigation bar.
///
/// 5 tabs (max 5): Home | Talk | Characters | Missions | Profile
/// All tap targets >= 48px.
library;

import 'package:flutter/material.dart';
import '../widgets/playful/playful.dart';
import 'characters_screen.dart';
import 'home_screen.dart';
import 'missions_screen.dart';
import 'profile_screen.dart';
import 'talk_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _selectTab),
      const TalkScreen(),
      const CharactersScreen(),
      const MissionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: PlayfulBottomNav(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        items: const [
          PlayfulNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          PlayfulNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Talk',
          ),
          PlayfulNavItem(
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            label: 'Characters',
          ),
          PlayfulNavItem(
            icon: Icons.flag_outlined,
            activeIcon: Icons.flag_rounded,
            label: 'Missions',
          ),
          PlayfulNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
