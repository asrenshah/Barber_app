import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final LocalAuth _localAuth = LocalAuth();
  
  bool _loading = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
    _checkBiometricAvailability();
  }

  // CHECK IF DEVICE SUPPORTS BIOMETRIC
  Future<void> _checkBiometricAvailability() async {
    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics;
      
      if (_biometricAvailable) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
      }
      
      debugPrint('Biometric available: $_biometricAvailable');
      debugPrint('Available types: $_availableBiometrics');
    } catch (e) {
      debugPrint('Error checking biometric: $e');
      _biometricAvailable = false;
    }
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading security settings: $e');
      setState(() => _loading = false);
    }
  }

  // REAL BIOMETRIC AUTHENTICATION
  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enable biometric - test authentication first
      final didAuthenticate = await _authenticateWithBiometric();
      
      if (didAuthenticate) {
        await _saveBiometricSetting(true);
        setState(() => _biometricEnabled = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication enabled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Authentication failed or cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric setup cancelled or failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Disable biometric
      await _saveBiometricSetting(false);
      setState(() => _biometricEnabled = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication disabled'),
        ),
      );
    }
  }

  Future<bool> _authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  Future<void> _saveBiometricSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  // TWO FACTOR AUTH - COMING SOON
  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, size: 50, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'This feature is coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'We\'re working on adding SMS/Email verification for enhanced security.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // CHANGE PASSWORD
  Future<void> _changePassword() async {
    if (_currentUser?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email associated with account'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _currentUser!.email!,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildBiometricStatus() {
    if (!_biometricAvailable) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange.shade700, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Biometric not available on this device',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final biometricType = _availableBiometrics.isNotEmpty 
        ? _availableBiometrics.first 
        : BiometricType.weak;
    
    String biometricName = 'Biometric';
    IconData biometricIcon = Icons.fingerprint;
    
    if (biometricType == BiometricType.face) {
      biometricName = 'Face ID';
      biometricIcon = Icons.face;
    } else if (biometricType == BiometricType.fingerprint) {
      biometricName = 'Fingerprint';
      biometricIcon = Icons.fingerprint;
    } else if (biometricType == BiometricType.iris) {
      biometricName = 'Iris Scan';
      biometricIcon = Icons.remove_red_eye;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(biometricIcon, color: Colors.green.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Available: $biometricName',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Security'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              const Text('Loading security settings...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authentication',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage how you sign in to your account',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Biometric Authentication
            _buildSecurityItem(
              icon: Icons.fingerprint,
              title: 'Biometric Authentication',
              subtitle: 'Use fingerprint or face ID to login',
              iconColor: Colors.purple,
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: _biometricAvailable ? _toggleBiometric : null,
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
            
            _buildBiometricStatus(),

            // Two-Factor Authentication
            _buildSecurityItem(
              icon: Icons.enhanced_encryption,
              title: 'Two-Factor Authentication',
              subtitle: 'Add extra security with SMS/Email verification',
              iconColor: Colors.orange,
              trailing: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: _showTwoFactorDialog,
                color: Colors.blue,
              ),
              onTap: _showTwoFactorDialog,
            ),

            const SizedBox(height: 24),
            const Text(
              'Account Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Protect your account and data',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Change Password
            _buildSecurityItem(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your login password',
              iconColor: Colors.blue,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: _changePassword,
            ),

            // Delete Account (Danger zone)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade100),
              ),
              color: Colors.red.shade50,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text(
                  'Permanently delete your account and all data',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deletion feature coming soon'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            
            // Security Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Security Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: _currentUser?.emailVerified == true 
                            ? Colors.green 
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentUser?.emailVerified == true
                              ? 'Email verified'
                              : 'Email not verified',
                          style: TextStyle(
                            color: _currentUser?.emailVerified == true
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: _biometricEnabled ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _biometricEnabled
                              ? 'Biometric authentication enabled'
                              : 'Biometric authentication disabled',
                          style: TextStyle(
                            color: _biometricEnabled ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Last Login Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Use a strong, unique password\n'
                          '• Enable biometric authentication\n'
                          '• Log out from shared devices\n'
                          '• Update app regularly',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'App Version: 1.0.0',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Helper class untuk LocalAuth (biar mudah)
class LocalAuth {
  final localAuth = local_auth.LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      return await localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticate({
    required String localizedReason,
    AuthenticationOptions options = const AuthenticationOptions(
      biometricOnly: false,
      stickyAuth: true,
      sensitiveTransaction: false,
    ),
  }) async {
    try {
      return await localAuth.authenticate(
        localizedReason: localizedReason,
        options: options,
      );
    } catch (e) {
      return false;
    }
  }
}