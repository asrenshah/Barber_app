import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_selector.dart';
import '../owner/owner_app.dart';
import '../customer/customer_app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _welcomeAnimation;
  late Animation<double> _textSlideAnimation;
  
  bool _checkingAuth = false;
  String? _cachedRole;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    
    _setupAnimations();
    
    Future.delayed(const Duration(milliseconds: 4000), () {
      _checkAuthentication();
    });
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.17, 0.5, curve: Curves.elasticOut),
      ),
    );

    _welcomeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.67, curve: Curves.bounceOut),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.67, 0.83, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkAuthentication() async {
    if (_checkingAuth) return;
    _checkingAuth = true;

    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSelector()),
        );
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      _cachedRole = (doc.data()?['role'] ?? 'customer').toString().toLowerCase();
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        if (_cachedRole == 'owner') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OwnerApp()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CustomerApp()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSelector()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (_controller.value > 0.5) {
            _checkAuthentication();
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFF8B4513), // Brown
                      const Color(0xFFFDF5E6).withOpacity(0.98), // White 98%
                      _backgroundAnimation.value,
                    )!,
                    Color.lerp(
                      const Color(0xFF8B4513), // Brown
                      const Color(0xFFF5DEB3).withOpacity(0.02), // Brown 2%
                      _backgroundAnimation.value,
                    )!,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO "SC" ANIMATION
                    Transform.scale(
                      scale: _logoAnimation.value,
                      child: CustomPaint(
                        painter: _StyleCutzLogoPainter(animationValue: _logoAnimation.value),
                        size: const Size(200, 200),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // "WELCOME" TEXT WITH CURVE
                    Transform.translate(
                      offset: Offset(0, -20 * (1 - _welcomeAnimation.value)),
                      child: Opacity(
                        opacity: _welcomeAnimation.value,
                        child: Transform.scale(
                          scale: 1.0 + 0.2 * _welcomeAnimation.value,
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TyperAnimatedText(
                                'Welcome',
                                textStyle: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD2691E),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                curve: Curves.elasticOut,
                              ),
                            ],
                            totalRepeatCount: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // "StyleCutz" & ".My" SLIDE ANIMATION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // "StyleCutz" slide dari kiri
                        Transform.translate(
                          offset: Offset(
                            -100 * (1 - _textSlideAnimation.value),
                            0,
                          ),
                          child: Opacity(
                            opacity: _textSlideAnimation.value,
                            child: const Text(
                              'StyleCutz',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                        ),

                        // ".My" slide dari kanan
                        Transform.translate(
                          offset: Offset(
                            50 * (1 - _textSlideAnimation.value),
                            0,
                          ),
                          child: Opacity(
                            opacity: _textSlideAnimation.value,
                            child: const Text(
                              '.My',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD2691E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // TAP TO CONTINUE
                    Opacity(
                      opacity: _controller.value > 0.9 ? 1.0 : 0.0,
                      child: Column(
                        children: [
                          if (_checkingAuth)
                            const CircularProgressIndicator(
                              color: Color(0xFFD2691E),
                              strokeWidth: 2,
                            )
                          else
                            const Text(
                              'Tap anywhere to continue',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF718096),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _StyleCutzLogoPainter extends CustomPainter {
  final double animationValue;

  _StyleCutzLogoPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF2D3748)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    // RAMBUT "S" - 2 helai rambut bentuk S
    final hairPath = Path();
    
    // Helai rambut pertama (S besar)
    hairPath.moveTo(center.dx - 60, center.dy - 40);
    hairPath.cubicTo(
      center.dx - 80, center.dy - 60,
      center.dx - 40, center.dy,
      center.dx - 60, center.dy + 40,
    );

    // Helai rambut kedua (S kecil)
    hairPath.moveTo(center.dx - 40, center.dy - 30);
    hairPath.cubicTo(
      center.dx - 50, center.dy - 40,
      center.dx - 30, center.dy,
      center.dx - 40, center.dy + 30,
    );

    // GUNTING "C" - bentuk C dengan hujung melengkung
    final scissorsPath = Path();
    
    // Bahagian gunting (bentuk C)
    scissorsPath.moveTo(center.dx + 40, center.dy - 50);
    scissorsPath.quadraticBezierTo(
      center.dx + 80, center.dy,
      center.dx + 40, center.dy + 50,
    );

    // Hujung gunting melengkung (detail)
    scissorsPath.moveTo(center.dx + 45, center.dy - 45);
    scissorsPath.quadraticBezierTo(
      center.dx + 60, center.dy - 30,
      center.dx + 50, center.dy - 15,
    );

    // Animate drawing paths
    final hairMetrics = hairPath.computeMetrics();
    final scissorsMetrics = scissorsPath.computeMetrics();

    for (final metric in hairMetrics) {
      final path = metric.extractPath(
        0.0,
        metric.length * animationValue,
      );
      canvas.drawPath(path, paint);
    }

    for (final metric in scissorsMetrics) {
      final path = metric.extractPath(
        0.0,
        metric.length * animationValue,
      );
      canvas.drawPath(path, paint);
    }

    // Add glow effect ketika animation complete
    if (animationValue > 0.95) {
      final glowPaint = Paint()
        ..color = const Color(0xFFD2691E).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      canvas.drawCircle(
        center,
        110,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}