import 'package:flutter/material.dart';

// እያንዳንዱን ገጽ ከየራሱ ፋይል እዚህ እንጠራዋለን (Barrel imports)
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoicePartyApp());
}

class VoicePartyApp extends StatelessWidget {
  const VoicePartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '3D Voice Party',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        primaryColor: const Color(0xFFFFD700),
      ),
      home: const LoginScreen(),
    );
  }
}
