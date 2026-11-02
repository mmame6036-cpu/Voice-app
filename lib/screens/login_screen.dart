import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  // Render Server URL
  static const String _serverBaseUrl = "https://nile-token-server.onrender.com";

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

  // --- Direct Server-Side Custom Token Authentication ---
  Future<void> _loginWithServer(String identifier) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Connecting to NILE server...";
    });

    try {
      final response = await http.post(
        Uri.parse("$_serverBaseUrl/auth/custom-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"identifier": identifier}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["token"] != null) {
          final String customToken = data["token"];

          // Authenticate with Firebase directly using Custom Token
          final UserCredential cred = await _auth.signInWithCustomToken(customToken);

          if (cred.user != null && mounted) {
            await _handleUserRouting(cred.user!);
          }
        } else {
          throw Exception("Server failed to generate token");
        }
      } else {
        throw Exception("Server returned code ${response.statusCode}");
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

  // Quick Guest Login
  Future<void> _handleGuestLogin() async {
    final guestId = "guest_${DateTime.now().millisecondsSinceEpoch}";
    await _loginWithServer(guestId);
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
                  color: Colors.white,
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
                          await _loginWithServer("251$rawNumber");
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
      backgroundColor: const Color(0xFF0A0714),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(
                Icons.graphic_eq,
                color: Color(0xFFFFD700),
                size: 54,
              ),
              const SizedBox(height: 12),
              const Text(
                "NILE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,

letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Live Voice Lounge",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
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
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              _actionButton(
                icon: const Icon(Icons.phone_android, size: 20, color: Colors.white),
                text: "Continue with Phone",
                bgColor: const Color(0xFF1E2235),
                textColor: Colors.white,
                onTap: _isLoading ? () {} : _handlePhoneSheet,
              ),
              const SizedBox(height: 14),
              _actionButton(
                icon: const Icon(Icons.person_outline, size: 20, color: Colors.black87),
                text: "Quick Guest Entry",
                bgColor: const Color(0xFFFFD700),
                textColor: Colors.black87,
                onTap: _isLoading ? () {} : _handleGuestLogin,
              ),
              const Spacer(flex: 1),
              const Text(
                "By continuing, you agree to our Terms & Privacy Policy.",
                style: TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required Widget icon,
    required String text,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
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
