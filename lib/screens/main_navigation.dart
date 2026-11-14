import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'room_screen.dart';
import '../services/agora_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _coins = 0;
  int _numericId = 100001;
  String _displayName = "Host";
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  final AgoraService _agoraService = AgoraService();
  Offset _floatingOffset = const Offset(16, 120);

  static const Color navBgColor = Color(0xFF161426);
  static const Color activeGold = Color(0xFFFFD700);
  static const Color inactiveColor = Color(0xFF8E8A9F);

  @override
  void initState() {
    super.initState();
    _listenToUserData();
    _agoraService.addListener(_onRoomStateChanged);
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _agoraService.removeListener(_onRoomStateChanged);
    super.dispose();
  }

  void _onRoomStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _listenToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (mounted) {
            setState(() {
              _coins = (data['coins'] as num?)?.toInt() ?? 0;
              _numericId = (data['numericId'] as num?)?.toInt() ?? 100001;
              _displayName =
                  (data['name'] ?? data['displayName'] ?? "User").toString();
            });
          }
        }
      });
    }
  }

  void _updateCoins(int newCoins) {
    setState(() {
      _coins = newCoins;
    });
  }

  void _joinRoom(String roomTitle) {
    _agoraService.restoreRoom();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomScreen(
          roomTitle: roomTitle,
          initialCoins: _coins,
          onCoinUpdate: _updateCoins,
          seatCount: _agoraService.currentSeatCount,
        ),
      ),
    );
  }

  Widget _buildFloatingMiniRoom() {
    return Positioned(
      right: _floatingOffset.dx,
      bottom: _floatingOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _floatingOffset = Offset(
              (_floatingOffset.dx - details.delta.dx)
                  .clamp(8.0, MediaQuery.of(context).size.width - 210),
              (_floatingOffset.dy - details.delta.dy)
                  .clamp(80.0, MediaQuery.of(context).size.height - 140),
            );
          });
        },
        onTap: () {
          final title = _agoraService.currentRoomTitle.isNotEmpty
              ? _agoraService.currentRoomTitle
              : "VIP Voice Room";
          _joinRoom(title);
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFD49B42), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,

offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD49B42),
                  ),
                  child: const Icon(Icons.graphic_eq,
                      color: Color(0xFF3E2723), size: 20),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _agoraService.currentRoomTitle.isNotEmpty
                            ? _agoraService.currentRoomTitle
                            : "Live Room",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Tap to return",
                        style:
                            TextStyle(color: Color(0xFFD49B42), fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () =>
                      _agoraService.setMicrophoneMute(!_agoraService.isMicMuted),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: Icon(
                      _agoraService.isMicMuted ? Icons.mic_off : Icons.mic,
                      color: _agoraService.isMicMuted
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _agoraService.leaveRoom(),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.redAccent, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        coins: _coins,
        onCoinUpdate: _updateCoins,
        onJoinRoom: _joinRoom,
      ),
      const MessagesScreen(),
      ProfileScreen(
        currentCoins: _coins,
        onCoinsUpdated: _updateCoins,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          if (_agoraService.isInRoom && _agoraService.isMinimized)
            _buildFloatingMiniRoom(),
        ],
      ),
      bottomNavigationBar: Container(

height: 64,
        decoration: BoxDecoration(
          color: navBgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(
                index: 0,
                icon: Icons.home_filled,
                label: "Home",
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 1,
                icon: Icons.chat_bubble_outline,
                label: "Message",
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 2,
                icon: Icons.person_outline,
                label: "Me",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? activeGold : inactiveColor,
            size: 23,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeGold : inactiveColor,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
