import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('${UserService.serverUrl}/api/register-user'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': 'device_${DateTime.now().millisecondsSinceEpoch}',
              'userName': 'Guest_User',
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          await UserService().setUserData(data['user']);
        }
      }
    } catch (_) {
      // ሰርቨሩ 404 ቢል ወይም ኢንተርኔት ባይኖር እንኳ ወደ ውስጥ ያሳልፋል
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // በቀጥታ ወደ ዋናው የክፍል መመልከቻ ገጽ ይወስዳል
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo & Title
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFC107),
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.black,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'NILE VOICE',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFFFFC107),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Next-Gen Live Voice Streaming',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),

              const Spacer(),

              // Google Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [

Text(
                              'G',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white38,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
