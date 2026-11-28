import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/room_session_manager.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<bool> appOnlineNotifier = ValueNotifier<bool>(true);

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
    FirebaseApp app;
    try {
      app = await Firebase.initializeApp();
    } catch (_) {
      app = await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBO33tukIxbGozgCfIkDAV5i5kyyZ20Ymc",
          appId: "1:582032682620:android:094d02520856e8a74263f9",
          messagingSenderId: "582032682620",
          projectId: "nilevoiceapp",
          storageBucket: "nilevoiceapp.firebasestorage.app",
        ),
      );
    }

    // Disable offline persistence so the app never runs on stale offline cache
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    } catch (_) {}

    return app;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
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
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }
        return _StrictNetworkGuard(
          child: FloatingRoomOverlay(child: child),
        );
      },
      home: FutureBuilder<FirebaseApp>(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const AuthWrapper();
          }

          if (snapshot.hasError) {
            return const LoginScreen();
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

class _StrictNetworkGuard extends StatefulWidget {
  final Widget child;
  const _StrictNetworkGuard({required this.child});

  @override
  State<_StrictNetworkGuard> createState() => _StrictNetworkGuardState();
}

class _StrictNetworkGuardState extends State<_StrictNetworkGuard> {
  Timer? _netTimer;
  bool _isOnline = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkInternetNow();
    // Fast 2-second check so offline state is detected immediately
    _netTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkInternetNow();
    });
  }

  @override
  void dispose() {
    _netTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInternetNow() async {
    if (_isChecking) return;
    _isChecking = true;
    bool connected = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 1500));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        connected = true;
      }
    } catch (_) {
      try {
        final socket = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(milliseconds: 1200),
        );
        socket.destroy();
        connected = true;
      } catch (_) {
        connected = false;
      }
    } finally {
      _isChecking = false;
    }

    if (connected != _isOnline) {
      appOnlineNotifier.value = connected;
      if (!connected) {
        // Immediately drop any minimized room session on network loss
        try {
          if (RoomSessionManager.instance.hasActiveRoom) {
            RoomSessionManager.instance.closeMinimizedRoom();
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isOnline = connected;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isOnline)
          Positioned.fill(
            child: Material(
              color: const Color(0xFF0A1628).withOpacity(0.96),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withOpacity(0.18),
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "No Internet Connection",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Network disconnected. Please turn on Mobile Data or Wi-Fi to continue using NILE Live.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD49B42),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          onPressed: _checkInternetNow,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            "Retry Now",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
