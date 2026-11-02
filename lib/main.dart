import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NileApp());
}

class NileApp extends StatelessWidget {
  const NileApp({super.key});

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0A1C),
        primaryColor: const Color(0xFFFFD700),
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
            backgroundColor: Color(0xFF0D0A1C),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final user = _authService.currentUser;
    if (mounted) {
      setState(() {
        _isLoggedIn = user != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0A1C),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFD700),
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      return const MainNavigationScreen();
    }

    return AuthScreen(
      onLoginSuccess: () {
        setState(() {
          _isLoggedIn = true;
        });
      },
    );
  }
}
