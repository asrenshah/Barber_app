import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'owner_dashboard.dart';
import 'booking/booking_screen.dart';
import 'reels/owner_reels_screen.dart';
import 'owner_profile_tab.dart';
import '../shared/exit_confirmation_dialog.dart';
import 'reels/owner_reels_upload.dart';

class OwnerApp extends StatefulWidget {
  const OwnerApp({super.key});

  @override
  State<OwnerApp> createState() => _OwnerAppState();
}

class _OwnerAppState extends State<OwnerApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OwnerDashboard(),
    const BookingScreen(),
    const OwnerReelsScreen(),
    const OwnerProfileTab(),
  ];

  // ===============================
  // BACK BUTTON HANDLER (SINGLE SOURCE OF TRUTH)
  // ===============================
  Future<void> _handleBack() async {
    // 1️⃣ Kalau bukan dashboard → balik dashboard
    if (_currentIndex != 0) {
      debugPrint('🔙 Back to Dashboard (was at index $_currentIndex)');
      setState(() => _currentIndex = 0);
      return;
    }

    // 2️⃣ Kalau dashboard → tanya exit
    final shouldExit = await showExitConfirmationDialog(context);
    if (shouldExit) {
      debugPrint('🚪 Exiting app from Dashboard');
      SystemNavigator.pop();
    }
  }

  // ===============================
  // NAVIGATE TO REELS UPLOAD
  // ===============================
  void _navigateToReelsUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OwnerReelsUpload(),
      ),
    );
  }

  // ===============================
  // BUILD
  // ===============================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),

        floatingActionButton: _currentIndex == 2
            ? FloatingActionButton(
                onPressed: () => _navigateToReelsUpload(context),
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.add),
              )
            : null,

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
      ),
    );
  }
}
