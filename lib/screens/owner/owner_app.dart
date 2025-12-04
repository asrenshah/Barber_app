import 'package:flutter/material.dart';
import 'owner_dashboard.dart';

import 'owner_bookings_screen.dart';
import 'owner_reels_screen.dart';
import 'owner_profile_tab.dart';

class OwnerApp extends StatefulWidget {
  const OwnerApp({super.key});

  @override
  State<OwnerApp> createState() => _OwnerAppState();
}

class _OwnerAppState extends State<OwnerApp> {
  int _currentIndex = 0;

  // ❗️ FIX: Pastikan screens tidak rebuild — letak final + const jika boleh
  late final List<Widget> _screens = [
    const OwnerDashboard(),
    const OwnerBookingsScreen(),
    const OwnerReelsScreen(),
    const OwnerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Content',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
