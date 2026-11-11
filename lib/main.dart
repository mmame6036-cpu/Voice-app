import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NileApp());
}

class NileApp extends StatelessWidget {
  const NileApp({super.key});

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFD49B42);

  Future<FirebaseApp> _initializeFirebase() async {
    try {
      return await Firebase.initializeApp();
    } catch (_) {
      return await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBO33tukIxbGozgCfIkDAV5i5kyyZ20Ymc",
          appId: "1:582032682620:android:094d02520856e8a74263f9",
          messagingSenderId: "582032682620",
          projectId: "nilevoiceapp",
          storageBucket: "nilevoiceapp.firebasestorage.app",
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NILE Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bgColor,
        primaryColor: primaryBrown,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentGold,
          primary: primaryBrown,
          secondary: accentGold,
        ),
      ),
      home: FutureBuilder<FirebaseApp>(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const AuthWrapper();
          }

          if (snapshot.hasError) {
            return const MainNavigationScreen();
          }

          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: CircularProgressIndicator(
                color: accentGold,
                strokeWidth: 2.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color accentGold = Color(0xFFD49B42);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: CircularProgressIndicator(
                color: accentGold,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
