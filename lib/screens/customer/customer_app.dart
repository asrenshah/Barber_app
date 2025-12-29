import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ TAMBAH IMPORT
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/discover/feed_screen.dart';
import 'screens/book/booking_screen.dart';
import 'screens/profile/customer_profile_screen.dart';
import '../auth/profile_selector.dart';
import '../shared/exit_confirmation_dialog.dart'; // ✅ TAMBAH IMPORT

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  int _currentIndex = 0;

  // ✅ Function untuk get user role
  Future<String> _getUserRole(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return 'customer';
      
      return (userDoc.data()?['role'] ?? 'customer').toString().toLowerCase();
    } catch (e) {
      return 'customer';
    }
  }

  // ✅ Profile tab dengan auth state check
  Widget _buildProfileTab() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        
        // ✅ JIKA USER SUDAH LOGIN - tunjuk CustomerProfileScreen
        if (user != null) {
          return FutureBuilder<String>(
            future: _getUserRole(user),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              final userRole = roleSnapshot.data ?? 'customer';
              print('👤 CustomerApp - User Role: $userRole');
              
              // ✅ PASTI user adalah customer, bukan owner
              if (userRole == 'customer') {
                return const CustomerProfileScreen();
              } else {
                // ❌ JIKA OWNER MASUK CUSTOMER APP - redirect ke ProfileSelector
                return _buildRoleErrorScreen();
              }
            },
          );
        }
        
        // ✅ JIKA USER TAK LOGIN - tunjuk ProfileSelector
        return const ProfileSelector();
      },
    );
  }

  // ✅ SCREEN ERROR jika owner cuba akses customer app
  Widget _buildRoleErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Error'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Account Type Mismatch',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your account is registered as Shop Owner. '
                'Please use the Shop Owner login.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Redirect ke ProfileSelector untuk pilih role betul
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const ProfileSelector()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Go to Profile Selector'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  // Logout dan redirect ke ProfileSelector
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const ProfileSelector()),
                    (route) => false,
                  );
                },
                child: const Text('Logout & Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Screens dengan profile tab yang dynamic
    final List<Widget> screens = [
      const FeedScreen(),
      const BookingScreen(),
      _buildProfileTab(), // ✅ Dynamic profile tab
    ];

    return PopScope(
      canPop: false, // 🚫 BLOCK DEFAULT BACK BEHAVIOR
      onPopInvoked: (didPop) async {
        if (didPop) return; // Jika sudah pop, return
        
        // 🎯 IMPLEMENTASI PATTERN ANDA:
        
        // 1. JIKA BUKAN DI FEED SCREEN (index 0) → BACK TO FEED
        if (_currentIndex != 0) {
          print('🔙 Back to Feed Screen (was at index $_currentIndex)');
          setState(() => _currentIndex = 0);
          return;
        }
        
        // 2. JIKA SUDAH DI FEED SCREEN → SHOW EXIT DIALOG
        print('🚪 Exit dialog from Feed Screen');
        final shouldExit = await showExitConfirmationDialog(context);
        if (shouldExit) {
          // Keluar dari aplikasi
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Book',
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