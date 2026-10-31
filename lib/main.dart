import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NileApp());
}

class NileApp extends StatelessWidget {
  const NileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NILE Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0A1C),
        primaryColor: const Color(0xFFFFD700),
      ),
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // If Firebase failed to initialize
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFF0D0A1C),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        "Firebase Initialization Error",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Once Firebase is successfully connected
          if (snapshot.connectionState == ConnectionState.done) {
            return const MainNavigationScreen();
          }

          // Loading screen while initializing
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
