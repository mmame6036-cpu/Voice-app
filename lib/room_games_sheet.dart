import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class RoomGamesSheet extends StatefulWidget {
  final dynamic socket;
  final VoidCallback onCoinsChanged;

  const RoomGamesSheet({Key? key, this.socket, required this.onCoinsChanged}) : super(key: key);

  static void show(BuildContext context, {dynamic socket, required VoidCallback onCoinsChanged}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoomGamesSheet(socket: socket, onCoinsChanged: onCoinsChanged),
    );
  }

  @override
  State<RoomGamesSheet> createState() => _RoomGamesSheetState();
}

class _RoomGamesSheetState extends State<RoomGamesSheet> {
  String? activeGameTitle;

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF070C1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (activeGameTitle != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => setState(() => activeGameTitle = null),
                  )
                else
                  const SizedBox(width: 32),
                Text(
                  activeGameTitle ?? 'Room Games',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${AppData.userCoins}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: activeGameTitle == null
                ? _buildGameCards()
                : OceanHuntGameView(
                    socket: widget.socket,
                    onCoinsChanged: widget.onCoinsChanged,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCards() {
    final games = [
      {'title': 'Ocean Hunt', 'subtitle': 'የአሳ አደን እና ሳንቲም', 'icon': Icons.water_drop_rounded, 'color': Colors.blueAccent},
      {'title': 'Chicken Road', 'subtitle': 'የዕድል መንገድ', 'icon': Icons.egg_rounded, 'color': Colors.amber},
      {'title': 'Fruit Party', 'subtitle': 'የፍራፍሬ ስፒን', 'icon': Icons.fastfood_rounded, 'color': Colors.orangeAccent},
      {'title': 'GaroGems', 'subtitle': 'የዕንቁ ሳጥን', 'icon': Icons.diamond_rounded, 'color': Colors.purpleAccent},
    ];

return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: games.length,
      itemBuilder: (context, idx) {
        final g = games[idx];
        return GestureDetector(
          onTap: () {
            setState(() {
              activeGameTitle = g['title'] as String;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [(g['color'] as Color).withOpacity(0.35), Colors.white.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (g['color'] as Color).withOpacity(0.6), width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(g['icon'] as IconData, color: g['color'] as Color, size: 40),
                const SizedBox(height: 8),
                Text(
                  g['title'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  g['subtitle'] as String,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('PLAY NOW', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// የተሻሻለው እውነተኛ OCEAN HUNT ጨዋታ
// ==========================================
class OceanHuntGameView extends StatefulWidget {
  final dynamic socket;
  final VoidCallback onCoinsChanged;

  const OceanHuntGameView({Key? key, this.socket, required this.onCoinsChanged}) : super(key: key);

  @override
  State<OceanHuntGameView> createState() => _OceanHuntGameViewState();
}

class _FishTarget {
  double x;
  double y;
  double speed;
  String name;
  String emoji;
  double size;
  int reward;
  bool isMovingRight;

  _FishTarget({
    required this.x,
    required this.y,
    required this.speed,
    required this.name,
    required this.emoji,
    required this.size,
    required this.reward,
    required this.isMovingRight,
  });
}

class _NetBurst {
  final Offset pos;
  final int reward;
  final String text;
  double scale = 0.2;
  double opacity = 1.0;
  _NetBurst({required this.pos, required this.reward, required this.text});
}

class _OceanHuntGameViewState extends State<OceanHuntGameView> {
  late Timer _gameLoopTimer;
  int selectedBet = 50;
  List<_FishTarget> fishes = [];
  List<_NetBurst> bursts = [];
  double cannonAngle = 0.0;
  String statusMsg = '🎯 አሳዎችን ለመምታት ይንኩ!';

  @override
  void initState() {
    super.initState();
    _spawnFishes();

    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) return;
      setState(() {
        for (var f in fishes) {
          if (f.isMovingRight) {
            f.x += f.speed;
            if (f.x > 1.15) {
              f.x = -0.2;
              f.y = 0.15 + (Random().nextDouble() * 0.55);
            }
          } else {
            f.x -= f.speed;
            if (f.x < -0.25) {
              f.x = 1.15;
              f.y = 0.15 + (Random().nextDouble() * 0.55);
            }
          }
        }

// የመረብ ፍንዳታ አኒሜሽን ማዘመን
        for (var b in bursts) {
          b.scale += 0.08;
          b.opacity -= 0.06;
        }
        bursts.removeWhere((b) => b.opacity <= 0.0);
      });
    });
  }

  void _spawnFishes() {
    fishes = [
      _FishTarget(x: -0.1, y: 0.18, speed: 0.007, name: 'Clownfish', emoji: '🐠', size: 36, reward: 20, isMovingRight: true),
      _FishTarget(x: 1.1, y: 0.28, speed: 0.005, name: 'Turtle', emoji: '🐢', size: 42, reward: 60, isMovingRight: false),
      _FishTarget(x: -0.2, y: 0.42, speed: 0.008, name: 'Blue Tang', emoji: '🐟', size: 34, reward: 40, isMovingRight: true),
      _FishTarget(x: 1.05, y: 0.55, speed: 0.004, name: 'Shark', emoji: '🦈', size: 54, reward: 250, isMovingRight: false),
      _FishTarget(x: -0.3, y: 0.32, speed: 0.003, name: 'Golden Whale', emoji: '🐋', size: 64, reward: 600, isMovingRight: true),
      _FishTarget(x: 1.2, y: 0.68, speed: 0.006, name: 'Octopus', emoji: '🐙', size: 44, reward: 120, isMovingRight: false),
    ];
  }

  @override
  void dispose() {
    _gameLoopTimer.cancel();
    super.dispose();
  }

  void _fireCannon(TapDownDetails details, Size size) {
    if (AppData.userCoins < selectedBet) {
      setState(() => statusMsg = 'በቂ ሳንቲም የለዎትም!');
      return;
    }

    setState(() {
      AppData.userCoins -= selectedBet;
    });
    widget.onCoinsChanged();

    final tapPos = details.localPosition;
    final cannonPos = Offset(size.width / 2, size.height - 40);

    // የመድፉን አቅጣጫ ማስተካከል
    final dx = tapPos.dx - cannonPos.dx;
    final dy = tapPos.dy - cannonPos.dy;
    setState(() {
      cannonAngle = atan2(dx, -dy);
    });

    final tapXRatio = tapPos.dx / size.width;
    final tapYRatio = tapPos.dy / size.height;

    bool hit = false;
    for (var f in fishes) {
      double fdx = (f.x - tapXRatio).abs();
      double fdy = (f.y - tapYRatio).abs();

      if (fdx < 0.12 && fdy < 0.10) {
        hit = true;
        int win = (f.reward * (selectedBet / 50)).round();

        setState(() {
          AppData.userCoins += win;
          statusMsg = '🎉 ${f.name} ተመታ! +$win ሳንቲም!';
          bursts.add(_NetBurst(pos: tapPos, reward: win, text: '+$win 💰'));
          // አሳው ሲመታ ወደ መነሻ ይመለሳል
          f.x = f.isMovingRight ? -0.25 : 1.15;
          f.y = 0.15 + (Random().nextDouble() * 0.55);
        });
        widget.onCoinsChanged();

        if (win >= 200 && widget.socket != null) {
          widget.socket.emit('game_win', {
            'winner': AppData.currentUserName,
            'game': 'Ocean Hunt',
            'amount': win,
          });
        }
        break;
      }
    }

    if (!hit) {
      setState(() {
        bursts.add(_NetBurst(pos: tapPos, reward: 0, text: 'MISS'));
        statusMsg = 'አልደረሰም! በድጋሚ ይሞክሩ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapDown: (details) => _fireCannon(details, size),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.3,
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF041936),
                  Color(0xFF010814),
                ],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // የውሃ ውስጥ አረፋዎች
                Positioned(top: 30, left: 20, child: _buildBubble(14)),
                Positioned(top: 100, right: 30, child: _buildBubble(22)),
                Positioned(top: 220, left: 70, child: _buildBubble(18)),
                Positioned(top: 320, right: 80, child: _buildBubble(12)),

// የሚዋኙ አሳዎች
                ...fishes.map((f) {
                  return Positioned(
                    left: f.x * size.width,
                    top: f.y * size.height,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(f.isMovingRight ? 1.0 : -1.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(f.emoji, style: TextStyle(fontSize: f.size)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 0.6),
                            ),
                            child: Text(
                              '+${f.reward}',
                              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                // የመረብና የሳንቲም ፍንዳታ (Net Burst FX)
                ...bursts.map((b) {
                  return Positioned(
                    left: b.pos.dx - 45,
                    top: b.pos.dy - 45,
                    child: Opacity(
                      opacity: b.opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: b.scale.clamp(0.2, 1.8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: b.reward > 0 ? const Color(0xFFFFD700) : Colors.redAccent,
                                  width: 3,
                                ),
                                gradient: RadialGradient(
                                  colors: [
                                    (b.reward > 0 ? const Color(0xFFFFD700) : Colors.redAccent).with
