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
  static const Color centerButtonBorder = Color(0xFF352C58);

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
              _displayName = (data['name'] ?? data['displayName'] ?? "User").toString();
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

  void _openPartyGameHub() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.58,
        decoration: const BoxDecoration(
          color: Color(0xFF19162E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFFFFD700), width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.casino, color: Color(0xFFFFD700), size: 26),
                SizedBox(width: 8),
                Text(

"Party Game Center",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Play live multiplayer mini-games and earn coin multipliers",
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.25,
                children: [
                  _buildGameCard(
                    title: "Lucky Wheel",
                    subtitle: "Win up to 500x",
                    icon: Icons.auto_awesome,
                    accentColor: const Color(0xFFFFD700),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Launching Lucky Wheel Game...")),
                      );
                    },
                  ),
                  _buildGameCard(
                    title: "Chicken Road",
                    subtitle: "Cross & Win Coins",
                    icon: Icons.sports_esports,
                    accentColor: const Color(0xFFFF4081),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Launching Chicken Road...")),
                      );
                    },
                  ),
                  _buildGameCard(
                    title: "Fruit Slots",
                    subtitle: "Classic 777 Jackpot",
                    icon: Icons.stars,
                    accentColor: const Color(0xFF00E5FF),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Launching Fruit Slots...")),
                      );
                    },
                  ),
                  _buildGameCard(
                    title: "Treasure Island",
                    subtitle: "Find Hidden Chests",
                    icon: Icons.diamond,
                    accentColor: const Color(0xFF00E676),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Launching Treasure Island...")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF231F3F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

Icon(icon, color: accentColor, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: accentColor.withOpacity(0.85),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGiftVault() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.62,
        decoration: const BoxDecoration(
          color: Color(0xFF19162E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFFFF4081), width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.card_giftcard, color: Color(0xFFFF4081), size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Global Gift Vault",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "$_coins",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Exclusive 3D animations and Lucky Gifts with high drop rates",
                style: TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
                children: [
                  _buildVaultGiftTile("Prism Diamond", "1000 Coins", Icons.diamond, const Color(0xFF00E5FF)),

_buildVaultGiftTile("Rose Cruise", "30000 Coins", Icons.directions_boat, const Color(0xFFFF4081)),
                  _buildVaultGiftTile("Space Rocket", "5000 Coins", Icons.rocket_launch, const Color(0xFFFFD700)),
                  _buildVaultGiftTile("Lovers Heart", "520 Coins", Icons.favorite, const Color(0xFFE91E63)),
                  _buildVaultGiftTile("Gold Crown", "450 Coins", Icons.workspace_premium, const Color(0xFFFFB300)),
                  _buildVaultGiftTile("Supercar", "2000 Coins", Icons.directions_car, const Color(0xFF00E676)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultGiftTile(String name, String price, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF231F3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
              (_floatingOffset.dx - details.delta.dx).clamp(8.0, MediaQuery.of(context).size.width - 210),
              (_floatingOffset.dy - details.delta.dy).clamp(80.0, MediaQuery.of(context).size.height - 140),
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
                  child: const Icon(Icons.graphic_eq, color: Color(0xFF3E2723), size: 20),
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
                        style: TextStyle(color: Color(0xFFD49B42), fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _agoraService.setMicrophoneMute(!_agoraService.isMicMuted),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: Icon(
                      _agoraService.isMicMuted ? Icons.mic_off : Icons.mic,
                      color: _agoraService.isMicMuted ? Colors.redAccent : Colors.greenAccent,
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
                    child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
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
        height: 66,
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_filled,
              label: "Home",
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.chat_bubble_outline,
              label: "Message",
            ),
            GestureDetector(

onTap: _openPartyGameHub,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: centerButtonBorder, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_esports,
                  color: Color(0xFF161426),
                  size: 28,
                ),
              ),
            ),
            GestureDetector(
              onTap: _openGiftVault,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF4081).withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Color(0xFFFF4081),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Gifts",
                    style: TextStyle(
                      color: Color(0xFFFF4081),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.person_outline,
              label: "Me",
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
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeGold : inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
