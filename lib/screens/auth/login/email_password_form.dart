import 'package:flutter/material.dart';

class EmailPasswordForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController pwCtrl;
  final bool loading;
  final VoidCallback onLogin;
  final VoidCallback onForgot;

  const EmailPasswordForm({
    super.key,
    required this.emailCtrl,
    required this.pwCtrl,
    required this.loading,
    required this.onLogin,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Email or Username',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: pwCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgot,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onLogin,
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Login'),
          ),
        ),
      ],
    );
  }
}