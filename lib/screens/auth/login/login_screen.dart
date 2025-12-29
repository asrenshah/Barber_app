import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'email_password_form.dart';
import 'social_login_buttons.dart';
import '../register_email_screen.dart';
import 'forgot_password_screen.dart';
import '../profile_selector.dart';
import '../../shared/universal_profile_form.dart';
import '../../owner/owner_app.dart';
import '../../customer/customer_app.dart';

class LoginScreen extends StatefulWidget {
  final String userType;
  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailOrUsernameCtrl = TextEditingController();
  final TextEditingController _pwCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailOrUsernameCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _emailOrUsernameLogin() async {
    final identifier = _emailOrUsernameCtrl.text.trim();
    final pw = _pwCtrl.text.trim();

    if (identifier.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan email/username & password')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String email = identifier;
      if (!identifier.contains('@')) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username tidak wujud')),
          );
          setState(() => _loading = false);
          return;
        }
        email = query.docs.first['email'];
      }

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pw,
      );

      await _afterLogin(cred.user);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login gagal')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _afterLogin(User? user, {bool isGoogleSignIn = false}) async {
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    bool hasData = userDoc.exists && userDoc.data() != null;
    final userRole = userDoc.data()?['role'] ?? 'customer';

    print('🔍 DEBUG: User has data: $hasData');
    print('🔍 DEBUG: User role: $userRole');

    if (!hasData) {
      print('🔍 DEBUG: No data → Redirect to Universal Form');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => UniversalProfileForm(
            mode: isGoogleSignIn ? 'google-first-time' : 'create',
            userType: widget.userType,
          ),
        ),
        (r) => false,
      );
    } else if (userRole == 'owner') {
      print('🔍 DEBUG: Owner with data → Redirect to OwnerApp');
      
      // ✅ OWNER: Direct ke OwnerApp
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OwnerApp()),
        (route) => false,
      );
    } else {
      print('🔍 DEBUG: Customer with data → Redirect to CustomerApp');
      
      // ✅ CUSTOMER: Ke CustomerApp
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerApp()),
        (route) => false,
      );
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      await _afterLogin(userCred.user, isGoogleSignIn: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in gagal: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileSelector()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Login (${widget.userType})'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ProfileSelector()),
                (route) => false,
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(18.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                EmailPasswordForm(
                  emailCtrl: _emailOrUsernameCtrl,
                  pwCtrl: _pwCtrl,
                  loading: _loading,
                  onLogin: _emailOrUsernameLogin,
                  onForgot: _forgotPassword,
                ),
                const SizedBox(height: 20),
                SocialLoginButtons(
                  loading: _loading,
                  onGoogle: _googleSignIn,
                  onPhone: _startPhoneAuth,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterEmailScreen(userType: widget.userType),
                        ),
                      );
                    },
                    child: const Text('First time here? Create an account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Phone auth function (simplified)
  Future<void> _startPhoneAuth() async {
    // ... (phone auth code tetap sama)
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(userType: widget.userType),
      ),
    );
  }
}
