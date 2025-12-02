import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String userType;
  const ForgotPasswordScreen({super.key, required this.userType});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  Future<void> _sendResetLink() async {
    final email = _emailCtrl.text.trim();
    
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan email yang sah')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Gagal menghantar link reset')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Kata Laluan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _emailSent ? _buildSuccessUI() : _buildFormUI(),
      ),
    );
  }

  Widget _buildFormUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Illustration/Icon
        Icon(Icons.lock_reset, size: 80, color: Theme.of(context).primaryColor),
        const SizedBox(height: 20),
        
        // Title & Instruction
        const Text(
          'Lupa Kata Laluan?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Masukkan alamat email anda dan kami akan hantar link untuk reset kata laluan.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        
        // Email Input
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Alamat Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 20),
        
        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendResetLink,
            child: _loading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Hantar Link Reset'),
          ),
        ),
        
        // Back to Login
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        
        const Text(
          'Semak Email Anda',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        
        const Text(
          'Kami telah menghantar arahan reset kata laluan ke:',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Text(
          _emailCtrl.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        
        const Text(
          'Jika tidak menerima email, semak folder spam atau cuba lagi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke Login'),
          ),
        ),
        
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text('Cuba Email Lain'),
        ),
      ],
    );
  }
}