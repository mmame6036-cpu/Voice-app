import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'Profile_setup_screen.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  bool _isLoading = false;
  String _loadingMessage = "";

  Future<void> _handleUserRouting(User user) async {
    final existingUser = await _userService.getUser(user.uid);

    if (!mounted) return;

    if (existingUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            uid: user.uid,
            defaultName: user.displayName ?? '',
            phoneNumber: user.phoneNumber ?? '',
          ),
        ),
      );
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Signing in...";
    });

    try {
      final UserCredential cred = await _auth.signInAnonymously();
      if (cred.user != null && mounted) {
        await _handleUserRouting(cred.user!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handlePhoneSheet() {
    final phoneController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Phone Login",
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFFFFD700)),
                  hintText: "9XXXXXXXX",
                  prefixText: "+251 ",
                  prefixStyle: const TextStyle(color: Colors.white),
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),

border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final rawNumber = phoneController.text.trim();
                          if (rawNumber.length < 9) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a valid phone number")),
                            );
                            return;
                          }

                          setSheetState(() => isSubmitting = true);
                          Navigator.pop(ctx);
                          await _handleGuestLogin();
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Rich Cosmic Gradient Background (Not too dark)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B1238),
                    Color(0xFF121B3A),
                    Color(0xFF0F1A30),
                    Color(0xFF1F1032),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 2. Custom Painted Glowing Starfield
          Positioned.fill(
            child: CustomPaint(
              painter: StarfieldPainter(),
            ),
          ),

          // 3. Foreground Login Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700).withOpacity(0.12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.graphic_eq,
                      color: Color(0xFFFFD700),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),

const Text(
                    "NILE",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Live Voice Lounge",
                    style: TextStyle(
                      color: Color(0xFFE0D4FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(flex: 3),
                  if (_isLoading)
                    Column(
                      children: [
                        const CircularProgressIndicator(color: Color(0xFFFFD700)),
                        const SizedBox(height: 14),
                        Text(
                          _loadingMessage,
                          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  _actionButton(
                    icon: const Icon(Icons.phone_android, size: 20, color: Color(0xFFFFD700)),
                    text: "Continue with Phone",
                    bgColor: const Color(0xFF261D4E).withOpacity(0.85),
                    textColor: const Color(0xFFFFD700),
                    borderColor: const Color(0xFFFFD700).withOpacity(0.5),
                    onTap: _isLoading ? () {} : _handlePhoneSheet,
                  ),
                  const SizedBox(height: 14),
                  _actionButton(
                    icon: const Icon(Icons.person_outline, size: 20, color: Colors.black87),
                    text: "Quick Guest Entry",
                    bgColor: const Color(0xFFFFD700),
                    textColor: Colors.black87,
                    borderColor: Colors.transparent,
                    onTap: _isLoading ? () {} : _handleGuestLogin,
                  ),
                  const Spacer(flex: 1),
                  const Text(
                    "By continuing, you agree to our Terms & Privacy Policy.",
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required Widget icon,
    required String text,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 5,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to render sparkling stars

class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // fixed seed for stable stars
    final starPaint = Paint()..color = Colors.white.withOpacity(0.8);
    final goldPaint = Paint()..color = const Color(0xFFFFD700).withOpacity(0.7);
    final bluePaint = Paint()..color = const Color(0xFF00E5FF).withOpacity(0.65);

    for (int i = 0; i < 90; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.8 + 0.6;

      Paint p = starPaint;
      if (i % 7 == 0) p = goldPaint;
      if (i % 5 == 0) p = bluePaint;

      canvas.drawCircle(Offset(dx, dy), radius, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
