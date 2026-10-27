import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  static const String abayFallsUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Blue_Nile_Falls_Ethiopia.jpg/1024px-Blue_Nile_Falls_Ethiopia.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ጀርባው ሙሉ በሙሉ የአባይ ፏፏቴ
          Positioned.fill(
            child: Image.network(
              abayFallsUrl,
              fit: BoxFit.cover,
            ),
          ),
          // ጥላ
          Positioned.fill(
            child: Container(
              color: const Color(0x8C000000),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                children: [
                  const Spacer(),
                  const Icon(Icons.graphic_eq, size: 70, color: Color(0xFFFFD700)),
                  const SizedBox(height: 12),
                  const Text(
                    "3D Voice Party",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    "Tis Abay Live Lounge",
                    style: TextStyle(fontSize: 14, color: Color(0xFFFFD700)),
                  ),
                  const Spacer(),

                  // በ Google መግቢያ
                  _loginButton(
                    text: "Continue with Google",
                    icon: Icons.g_mobiledata,
                    bgColor: Colors.white,
                    textColor: Colors.black87,
                    iconColor: Colors.red,
                    onTap: onLoginSuccess,
                  ),
                  const SizedBox(height: 14),

                  // በስልክ መግቢያ
                  _loginButton(
                    text: "Continue with Phone",
                    icon: Icons.phone_android,
                    bgColor: const Color(0xFF23233E),
                    textColor: Colors.white,
                    iconColor: const Color(0xFFFFD700),
                    onTap: onLoginSuccess,
                  ),
                  const SizedBox(height: 14),

                  // በ Facebook መግቢያ
                  _loginButton(
                    text: "Continue with Facebook",
                    icon: Icons.facebook,
                    bgColor: const Color(0xFF1877F2),
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    onTap: onLoginSuccess,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "By continuing, you agree to our Terms & Privacy Policy.",
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginButton({
    required String text,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 4,
        ),
        onPressed: onTap,

child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
