import 'package:flutter/material.dart';
import 'login/login_screen.dart';
import '../customer/customer_app.dart';

class ProfileSelector extends StatelessWidget {
  const ProfileSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ FIXED: TIDAK REDIRECT KE MANA-MANA, TETAP DI PROFILE SELECTOR
        // Atau jika mahu keluar app, gunakan SystemNavigator.pop()
        return false; // Prevent back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('StyleCutz'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // ✅ FIXED: TIDAK REDIRECT KE CUSTOMER_APP
              // Tutup app atau biarkan empty
              Navigator.maybePop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Select Account Type',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(240, 48),
                          shape: const StadiumBorder()),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(userType: 'customer'),
                          ),
                        );
                      },
                      child: const Text('Login as Customer'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(240, 48),
                          shape: const StadiumBorder()),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(userType: 'owner'),
                          ),
                        );
                      },
                      child: const Text('Login as Shop Owner'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}