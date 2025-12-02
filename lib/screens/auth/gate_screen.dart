import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_selector.dart';
import '../owner/owner_app.dart';
import '../customer/customer_app.dart';

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
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

  void _initializeApp() async {
    print('🚀 GateScreen - Starting initialization');
    
    // ✅ WAIT FOR EVERYTHING TO BE READY
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final user = FirebaseAuth.instance.currentUser;
    print('🔍 GateScreen - User: ${user?.uid}');

    if (user != null) {
      final role = await _getUserRole(user);
      print('🎯 GateScreen - User Role: $role');
      
      if (!mounted) return;
      
      if (role == 'owner') {
        print('➡️ GateScreen - Redirecting to OwnerApp');
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const OwnerApp())
        );
      } else {
        print('➡️ GateScreen - Redirecting to CustomerApp');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerApp())
        );
      }
    } else {
      print('➡️ GateScreen - Redirecting to ProfileSelector');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSelector())
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Preparing StyleCutz...',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}