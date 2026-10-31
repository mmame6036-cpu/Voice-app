import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // Prevents the white screen by showing an error box if something goes wrong
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0D0A1C),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Startup Notice:\n${details.exceptionAsString()}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      ),
    );
  };

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
      home: const MainNavigationScreen(),
    );
  }
}
