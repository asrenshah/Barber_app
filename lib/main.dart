import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/auth/splash_screen.dart';
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
  
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode') ?? false;
  
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _startThemeListener();
  }

  void _startThemeListener() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final currentDarkMode = _prefs.getBool('dark_mode') ?? false;
        if (currentDarkMode != _isDarkMode) {
          setState(() {
            _isDarkMode = currentDarkMode;
          });
        }
        _startThemeListener();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyleCutz',
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _cachedRole;
  bool _loadingRole = false;

  Future<void> _loadRole(User user) async {
    if (_cachedRole != null || _loadingRole) return;
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
          _cachedRole = null;
          return const ProfileSelector();
        }

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