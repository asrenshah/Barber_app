import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SocialLoginButtons extends StatelessWidget {
  final bool loading;
  final VoidCallback onGoogle;
  final VoidCallback onPhone;

  const SocialLoginButtons({
    super.key,
    required this.loading,
    required this.onGoogle,
    required this.onPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: SignInButton(
              Buttons.Google,
              text: 'Sign in with Google',
              onPressed: loading ? null : onGoogle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.grey),
              ),
              onPressed: loading ? null : onPhone,
              icon: const Icon(Icons.smartphone, color: Colors.green),
              label: const Text('Sign in with Phone'),
            ),
          ),
        ),
      ],
    );
  }
}