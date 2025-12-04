import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/auth/splash_screen.dart'; // ✅ TAMBAH INI SAHAJA
import 'screens/auth/profile_selector.dart';
import 'screens/owner/owner_app.dart';
import 'screens/customer/customer_app.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🚀 Apps started - Premium Splash Screen');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyleCutz',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // ✅ UBAH INI SAHAJA: AuthWrapper → SplashScreen
    );
  }
}

// ======================================================
//  ✅ FIXED AUTH WRAPPER — CACHE ROLE, NO MORE MISMATCH
// ======================================================

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _cachedRole;
  bool _loadingRole = false;

  Future<void> _loadRole(User user) async {
    if (_cachedRole != null || _loadingRole) return; // 🔥 prevent multiple loads
    _loadingRole = true;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      _cachedRole =
          (doc.data()?['role'] ?? 'customer').toString().toLowerCase();

      if (mounted) setState(() {});
    } catch (e) {
      _cachedRole = 'customer';
    }

    _loadingRole = false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (user == null) {
          _cachedRole = null; // reset role bila user logout
          return const ProfileSelector();
        }

        // 🔥 Load role sekali sahaja selepas login
        _loadRole(user);

        if (_cachedRole == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        print("🎯 Role Cached: $_cachedRole");

        if (_cachedRole == 'owner') return const OwnerApp();

        return const CustomerApp();
      },
    );
  }
}
