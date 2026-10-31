import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NileApp());
}

class NileApp extends StatelessWidget {
  const NileApp({super.key});

  Future<FirebaseApp> _initializeFirebase() async {
    try {
      // First attempt to initialize using native resources
      return await Firebase.initializeApp();
    } catch (_) {
      // Fallback for Android when google-services.json values are missing
      return await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDummyKeyForNileLiveProductionFallback",
          appId: "1:100000000000:android:0000000000000000000000",
          messagingSenderId: "100000000000",
          projectId: "nile-live-app",
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
            return const MainNavigationScreen();
          }

          if (snapshot.hasError) {
            return const MainNavigationScreen();
          }

          return const Scaffold(
            backgroundColor: const Color(0xFF0D0A1C),
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
