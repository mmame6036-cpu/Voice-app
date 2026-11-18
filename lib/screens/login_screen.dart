import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/user_service.dart';
import 'profil_sub_screen.dart';
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

  static const Color kGold = Color(0xFFFFD700);
  static const Color kSheetBg = Color(0xFF141226);

  Future<void> _handleUserRouting(User user, {String enteredPhone = ''}) async {
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
      String phoneToPass = enteredPhone;
      if (phoneToPass.isEmpty && user.phoneNumber != null) {
        phoneToPass = user.phoneNumber!;
      }

      String nameToPass = '';
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        nameToPass = user.displayName!.trim();
      } else if (user.email != null && user.email!.contains('@')) {
        nameToPass = user.email!.split('@').first;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            uid: user.uid,
            defaultName: nameToPass,
            phoneNumber: phoneToPass,
          ),
        ),
      );
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.redAccent.shade700 : const Color(0xFF107C41),
      ),
    );
  }

  String _friendlyAuthError(Object e) {
    final raw = e.toString();
    if (raw.contains('ApiException: 10') ||
        raw.contains('DEVELOPER_ERROR') ||
        raw.contains('sign_in_failed')) {
      return "Configuration error: Add SHA-1 & SHA-256 in Firebase Console.";
    }
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return "Incorrect email or password.";
    }
    if (raw.contains('user-not-found')) {
      return "No account found with this email. Tap 'Create Account' first.";
    }
    if (raw.contains('email-already-in-use')) {
      return "This Gmail/Email is already registered. Please Sign In.";
    }
    if (raw.contains('weak-password')) {
      return "Password must be at least 6 characters.";
    }
    if (raw.contains('invalid-email')) {
      return "Please enter a valid Gmail or email address.";
    }
    if (raw.contains('invalid-phone-number')) {
      return "Invalid phone number format. Check country code and digits.";
    }
    if (raw.contains('invalid-verification-code')) {
      return "Incorrect 6-digit SMS code. Please check and try again.";
    }
    if (raw.contains('too-many-requests')) {
      return "Too many attempts. Please wait a moment and try again.";
    }
    if (raw.contains('network-request-failed')) {
      return "No internet connection. Please check your network.";
    }
    return "Authentication failed. Please try again.";
  }

  // 1. GOOGLE SIGN-IN (Global)
  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadingMessage = "Connecting to Google...";
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential cred = await _auth.signInWithCredential(credential);
      if (cred.user != null && mounted) {
        await _handleUserRouting(cred.user!);
      }
    } catch (e) {
      _showMessage(_friendlyAuthError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. GMAIL / EMAIL & PASSWORD (Global)
  void _openEmailAuthSheet() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isRegisterMode = false;
    bool obscurePass = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          Future<void> submitEmail() async {
            final email = emailCtrl.text.trim();
            final pass = passCtrl.text.trim();

            if (email.isEmpty || !email.contains('@')) {
              _showMessage("Please enter a valid Gmail address.");
              return;
            }
            if (pass.length < 6) {
              _showMessage("Password must be at least 6 characters.");
              return;
            }

            setSheetState(() => isSubmitting = true);

            try {
              UserCredential cred;
              if (isRegisterMode) {
                cred = await _auth.createUserWithEmailAndPassword(
                  email: email,
                  password: pass,
                );
              } else {
                cred = await _auth.signInWithEmailAndPassword(
                  email: email,
                  password: pass,
                );
              }

              if (sheetCtx.mounted) Navigator.pop(sheetCtx);

              if (cred.user != null && mounted) {
                setState(() {
                  _isLoading = true;
                  _loadingMessage = "Loading account...";
                });
                await _handleUserRouting(cred.user!);
              }
            } catch (e) {
              _showMessage(_friendlyAuthError(e));
            } finally {
              if (sheetCtx.mounted) {
                setSheetState(() => isSubmitting = false);
              }
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          }

          Future<void> resetPassword() async {
            final email = emailCtrl.text.trim();
            if (email.isEmpty || !email.contains('@')) {
              _showMessage("Enter your Gmail address first to reset password.");
              return;
            }
            try {
              await _auth.sendPasswordResetEmail(email: email);
              _showMessage(
                "Password reset link sent to $email",
                isError: false,
              );
            } catch (e) {
              _showMessage(_friendlyAuthError(e));
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
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
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setSheetState(() => isRegisterMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isRegisterMode
                                ? kGold
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Sign In",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !isRegisterMode
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => isRegisterMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isRegisterMode
                                ? kGold
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Create Account",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isRegisterMode
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: kGold),
                    hintText: "example@gmail.com",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: obscurePass,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: kGold),

suffixIcon: IconButton(
                      icon: Icon(
                        obscurePass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () =>
                          setSheetState(() => obscurePass = !obscurePass),
                    ),
                    hintText: "Password (min 6 characters)",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (!isRegisterMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: resetPassword,
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: kGold, fontSize: 12),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isSubmitting ? null : submitEmail,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isRegisterMode
                                ? "Register with Gmail"
                                : "Login with Gmail",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. GLOBAL PHONE NUMBER + SMS OTP (All Countries Supported)
  void _openPhoneAuthSheet() {
    final phoneCtrl = TextEditingController();
    final customCodeCtrl = TextEditingController(text: "+");
    final otpCtrl = TextEditingController();
    String selectedCode = "+251";
    String? verificationId;
    bool isSendingCode = false;
    bool isVerifyingCode = false;

    final List globalCountries = [
      {"label": "🇪🇹 +251", "code": "+251"},
      {"label": "🇦🇪 +971", "code": "+971"},
      {"label": "🇸🇦 +966", "code": "+966"},
      {"label": "🇶🇦 +974", "code": "+974"},
      {"label": "🇰🇼 +965", "code": "+965"},
      {"label": "🇧🇭 +973", "code": "+973"},
      {"label": "🇴🇲 +968", "code": "+968"},
      {"label": "🇱🇧 +961", "code": "+961"},
      {"label": "🇯🇴 +962", "code": "+962"},
      {"label": "🇪🇬 +20", "code": "+20"},
      {"label": "🇸🇩 +249", "code": "+249"},
      {"label": "🇰🇪 +254", "code": "+254"},
      {"label": "🇺🇬 +256", "code": "+256"},
      {"label": "🇪🇷 +291", "code": "+291"},
      {"label": "🇩🇯 +253", "code": "+253"},

{"label": "🇸🇴 +252", "code": "+252"},
      {"label": "🇿🇦 +27", "code": "+27"},
      {"label": "🇳🇬 +234", "code": "+234"},
      {"label": "🇺🇸 +1", "code": "+1"},
      {"label": "🇬🇧 +44", "code": "+44"},
      {"label": "🇩🇪 +49", "code": "+49"},
      {"label": "🇫🇷 +33", "code": "+33"},
      {"label": "🇮🇹 +39", "code": "+39"},
      {"label": "🇸🇪 +46", "code": "+46"},
      {"label": "🇳🇴 +47", "code": "+47"},
      {"label": "🇳🇱 +31", "code": "+31"},
      {"label": "🇹🇷 +90", "code": "+90"},
      {"label": "🇮🇳 +91", "code": "+91"},
      {"label": "🇨🇳 +86", "code": "+86"},
      {"label": "🇦🇺 +61", "code": "+61"},
      {"label": "🌍 Other (+)", "code": "OTHER"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          String resolveCountryCode() {
            if (selectedCode != "OTHER") return selectedCode;
            String raw = customCodeCtrl.text.replaceAll(RegExp(r'[^0-9+]'), '');
            if (!raw.startsWith('+')) raw = '+$raw';
            return raw;
          }

          String formatPhoneNumber() {
            final cCode = resolveCountryCode();
            String digits = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
            while (digits.startsWith('0')) {
              digits = digits.substring(1);
            }
            return "$cCode$digits";
          }

          Future<void> sendOtpCode() async {
            final cCode = resolveCountryCode();
            if (cCode.length < 2) {
              _showMessage("Please enter a valid country code (e.g. +251).");
              return;
            }
            final cleanDigits =
                phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
            if (cleanDigits.length < 6) {
              _showMessage("Please enter a valid phone number.");
              return;
            }

            final fullPhone = formatPhoneNumber();
            setSheetState(() => isSendingCode = true);

            await _auth.verifyPhoneNumber(
              phoneNumber: fullPhone,
              timeout: const Duration(seconds: 60),
              verificationCompleted: (PhoneAuthCredential credential) async {
                try {
                  final cred = await _auth.signInWithCredential(credential);
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  if (cred.user != null && mounted) {
                    await _handleUserRouting(cred.user!,
                        enteredPhone: fullPhone);
                  }
                } catch (e) {
                  _showMessage(_friendlyAuthError(e));
                }
              },
              verificationFailed: (FirebaseAuthException e) {
                if (sheetCtx.mounted) {
                  setSheetState(() => isSendingCode = false);
                }
                _showMessage(e.message ?? _friendlyAuthError(e));
              },
              codeSent: (String verId, int? resendToken) {
                if (sheetCtx.mounted) {
                  setSheetState(() {
                    verificationId = verId;
                    isSendingCode = false;
                  });
                }
                _showMessage("SMS code sent to $fullPhone", isError: false);
              },
              codeAutoRetrievalTimeout: (String verId) {
                verificationId = verId;
              },
            );
          }

          Future<void> verifyOtpCode() async {
            final code = otpCtrl.text.trim();
            if (verificationId == null || code.length < 6) {
              _showMessage("Please enter the 6-digit SMS code.");
              return;
            }

            final fullPhone = formatPhoneNumber();
            setSheetState(() => isVerifyingCode = true);

try {
              final PhoneAuthCredential credential =
                  PhoneAuthProvider.credential(
                verificationId: verificationId!,
                smsCode: code,
              );

              final UserCredential cred =
                  await _auth.signInWithCredential(credential);

              if (sheetCtx.mounted) Navigator.pop(sheetCtx);

              if (cred.user != null && mounted) {
                setState(() {
                  _isLoading = true;
                  _loadingMessage = "Verifying account...";
                });
                await _handleUserRouting(cred.user!, enteredPhone: fullPhone);
              }
            } catch (e) {
              _showMessage(_friendlyAuthError(e));
            } finally {
              if (sheetCtx.mounted) {
                setSheetState(() => isVerifyingCode = false);
              }
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
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
                  "International Phone Login (SMS OTP)",
                  style: TextStyle(
                    color: kGold,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCode,
                          dropdownColor: kSheetBg,
                          style: const TextStyle(
                            color: kGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          items: globalCountries
                              .map((item) => DropdownMenuItem(
                                    value: item["code"],
                                    child: Text(item["label"]!),
                                  ))
                              .toList(),
                          onChanged: verificationId != null
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setSheetState(() => selectedCode = val);
                                  }
                                },
                        ),
                      ),
                    ),
                    if (selectedCode == "OTHER") ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 68,
                        child: TextField(

controller: customCodeCtrl,
                          enabled: verificationId == null,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: kGold,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: "+...",
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        enabled: verificationId == null,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Phone number",
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (verificationId != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      color: kGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "------",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (isSendingCode || isVerifyingCode)
                        ? null
                        : (verificationId == null
                            ? sendOtpCode
                            : verifyOtpCode),
                    child: (isSendingCode || isVerifyingCode)

? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            verificationId == null
                                ? "Send SMS Code"
                                : "Verify & Login",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTermsAndPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSheetBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: kGold, width: 1.0),
        ),
        title: const Text(
          "NILE Live Terms & Privacy Policy",
          style: TextStyle(
            color: kGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            "1. Account & Profile Data:\n"
            "We collect your nickname, user ID, email/phone, and optional profile photo to operate voice chat rooms and protect your coins and rewards.\n\n"
            "2. Microphone Permission:\n"
            "Audio access is used strictly when you join a speaker seat in a voice room.\n\n"
            "3. Community Safety:\n"
            "Harassment, fraud, or abuse will result in permanent account suspension.\n\n"
            "4. Account & Data Deletion:\n"
            "You can permanently delete your account and personal data anytime inside the app under Me -> Settings -> Delete Account.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "I Understand",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          Positioned.fill(
            child: CustomPaint(
              painter: StarfieldPainter(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

color: kGold.withOpacity(0.12),
                      boxShadow: [
                        BoxShadow(
                          color: kGold.withOpacity(0.3),
                          blurRadius: 22,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.graphic_eq,
                      color: kGold,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "NILE",
                    style: TextStyle(
                      color: kGold,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
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
                  const Spacer(flex: 2),
                  if (_isLoading)
                    Column(
                      children: [
                        const CircularProgressIndicator(color: kGold),
                        const SizedBox(height: 12),
                        Text(
                          _loadingMessage,
                          style: const TextStyle(color: kGold, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  _actionButton(
                    icon: const Icon(Icons.g_mobiledata_rounded,
                        size: 28, color: Colors.black87),
                    text: "Continue with Google",
                    bgColor: Colors.white,
                    textColor: Colors.black87,
                    borderColor: Colors.white,
                    onTap: _isLoading ? null : _handleGoogleLogin,
                  ),
                  const SizedBox(height: 12),
                  _actionButton(
                    icon: const Icon(Icons.email_rounded,
                        size: 20, color: Colors.black87),
                    text: "Continue with Gmail",
                    bgColor: kGold,
                    textColor: Colors.black87,
                    borderColor: Colors.transparent,
                    onTap: _isLoading ? null : _openEmailAuthSheet,
                  ),
                  const SizedBox(height: 12),
                  _actionButton(
                    icon: const Icon(Icons.phone_android_rounded,
                        size: 20, color: kGold),
                    text: "Continue with Phone",
                    bgColor: const Color(0xFF261D4E).withOpacity(0.9),
                    textColor: kGold,
                    borderColor: kGold.withOpacity(0.6),
                    onTap: _isLoading ? null : _openPhoneAuthSheet,
                  ),
                  const Spacer(flex: 1),
                  GestureDetector(
                    onTap: _showTermsAndPrivacyDialog,
                    child: const Text(
                      "By continuing, you agree to our Terms & Privacy Policy.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,

decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          disabledBackgroundColor: bgColor.withOpacity(0.5),
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
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final starPaint = Paint()..color = Colors.white.withOpacity(0.8);
    final goldPaint = Paint()..color = const Color(0xFFFFD700).withOpacity(0.7);
    final bluePaint =
        Paint()..color = const Color(0xFF00E5FF).withOpacity(0.65);

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
