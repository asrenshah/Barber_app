import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(userType: 'customer')),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen(userType: 'customer');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log Keluar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("No profile data"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${userData?['name'] ?? '-'}",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text("Email: ${userData?['email'] ?? '-'}",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text("Phone: ${userData?['phone'] ?? '-'}",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text("Role: ${userData?['role'] ?? '-'}",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        "Created At: ${userData?['createdAt'] != null ? userData!['createdAt'].toDate().toString() : '-'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      if ((userData?['shopName'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text("Shop Name: ${userData?['shopName'] ?? '-'}",
                            style: const TextStyle(fontSize: 18)),
                      ],
                      if ((userData?['shopAddress'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text("Shop Address: ${userData?['shopAddress'] ?? '-'}",
                            style: const TextStyle(fontSize: 18)),
                      ],
                    ],
                  ),
                ),
    );
  }
}