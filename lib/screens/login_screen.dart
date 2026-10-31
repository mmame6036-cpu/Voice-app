import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String _loadingMethod = "";

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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _loadingMethod = "Google";
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _handleUserRouting(userCredential.user!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google sign in failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handlePhoneSignIn() {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    bool codeSent = false;
    String currentVerificationId = "";
    bool isProcessing = false;

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
              Text(
                codeSent ? "Enter Verification Code" : "Phone Login",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,

fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (!codeSent) ...[
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
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final rawNumber = phoneController.text.trim();
                            if (rawNumber.length < 9) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a valid phone number")),
                              );
                              return;
                            }

                            setSheetState(() => isProcessing = true);
                            final fullPhone = "+251$rawNumber";

                            await _auth.verifyPhoneNumber(
                              phoneNumber: fullPhone,
                              verificationCompleted: (PhoneAuthCredential credential) async {
                                final result = await _auth.signInWithCredential(credential);
                                if (result.user != null && mounted) {
                                  Navigator.pop(ctx);
                                  await _handleUserRouting(result.user!);
                                }
                              },
                              verificationFailed: (FirebaseAuthException e) {
                                setSheetState(() => isProcessing = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed: ${e.message}")),
                                );
                              },
                              codeSent: (String verificationId, int? resendToken) {
                                setSheetState(() {
                                  currentVerificationId = verificationId;
                                  codeSent = true;
                                  isProcessing = false;
                                });
                              },
                              codeAutoRetrievalTimeout: (String verificationId) {
                                currentVerificationId = verificationId;
                              },
                            );
                          },

child: isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Text("Send Code (OTP)", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Text(
                  "Code sent to +251 ${phoneController.text.trim()}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 18),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "123456",
                    hintStyle: const TextStyle(color: Colors.white24),
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
                      backgroundColor: const Color(0xFF00C9A7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final code = otpController.text.trim();
                            if (code.length < 6) return;

                            setSheetState(() => isProcessing = true);

                            try {
                              final credential = PhoneAuthProvider.credential(
                                verificationId: currentVerificationId,
                                smsCode: code,
                              );
                              final result = await _auth.signInWithCredential(credential);
                              if (result.user != null && mounted) {
                                Navigator.pop(ctx);
                                await _handleUserRouting(result.user!);
                              }
                            } catch (e) {
                              setSheetState(() => isProcessing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Invalid verification code: $e")),
                              );
                            }
                          },
                    child: isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Text("Verify & Login", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
                      "Signing in with $_loadingMethod...",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              _loginButton(
                icon: const Text(
                  "G",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4285F4),
                  ),
                ),
                text: "Continue with Google",
                bgColor: Colors.white,
                textColor: Colors.black87,
                onTap: _isLoading ? () {} : _handleGoogleSignIn,
              ),
              const SizedBox(height: 14),
              _loginButton(
                icon: const Icon(Icons.phone_android, size: 20, color: Colors.white70),
                text: "Continue with Phone",
                bgColor: const Color(0xFF1E2235),
                textColor: Colors.white,
                onTap: _isLoading ? () {} : _handlePhoneSignIn,
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

  Widget _loginButton({
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
