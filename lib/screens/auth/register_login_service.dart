import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterLoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 REGISTER USER DENGAN EMAIL & PASSWORD
  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String role, // "owner" atau "customer"
  }) async {
    try {
      // Cipta akaun baru
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = cred.user;
      if (user == null) return 'Registration failed';

      // Simpan maklumat ke Firestore (merge supaya tak overwrite)
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // ✅ tambahkan merge: true

      return null; // Tiada error
    } on FirebaseAuthException catch (e) {
      return e.message; // Hantar mesej error dari Firebase
    } catch (e) {
      return e.toString();
    }
  }

  // 🔹 LOGIN USER DENGAN EMAIL & PASSWORD
  Future<String?> loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      // Login akaun
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = cred.user;
      if (user == null) return 'Login failed';

      // Ambil role dari Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'customer';

      // Navigate berdasarkan role - guna temporary screens dulu
      if (role == 'owner') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => _buildOwnerDashboard()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => _buildCustomerProfileScreen()),
          (route) => false,
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 🔹 RESET PASSWORD
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Temporary Owner Dashboard Screen
  Widget _buildOwnerDashboard() {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome Owner!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to actual owner dashboard
              },
              child: const Text('Continue to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  // Temporary Customer Profile Screen
  Widget _buildCustomerProfileScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome Customer!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to actual customer screen
              },
              child: const Text('Continue to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}