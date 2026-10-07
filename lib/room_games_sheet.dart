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
    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF090D1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // የላይኛው መጎተቻ
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          // ራስጌ
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

          // ጌም ሲመረጥ ወደ Ocean Hunt ይገባል
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
      {'title': 'Ocean Hunt', 'subtitle': 'አሳ አደን እና ሳንቲም', 'icon': Icons.water_drop_rounded, 'color': Colors.blueAccent},
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
// እውነተኛው OCEAN HUNT (የአሳ አደን) ጨዋታ
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
  int reward;
  bool isMovingRight;

  _FishTarget({
    required this.x,
    required this.y,
    required this.speed,
    required this.name,
    required this.emoji,
    required this.reward,
    required this.isMovingRight,
  });
}

class _Bullet {
  double x;
  double y;
  double targetX;
  double targetY;
  _Bullet({required this.x, required this.y, required this.targetX, required this.targetY});
}

class _OceanHuntGameViewState extends State<OceanHuntGameView> with SingleTickerProviderStateMixin {
  late Timer _gameLoopTimer;
  final Random _rnd = Random();
  int selectedBet = 50; // የመድፍ ጥይት ዋጋ
  List<_FishTarget> fishes = [];
  List<_Bullet> bullets = [];
  String statusMsg = 'አሳዎቹን ለመምታት ስክሪኑን ይንኩ! 🎯';

  @override
  void initState() {
    super.initState();
    _spawnInitialFishes();

    // የጨዋታው ሉፕ (አሳዎቹ እንዲዋኙ የሚያደርግ)
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) return;
      setState(() {
        for (var f in fishes) {
          if (f.isMovingRight) {
            f.x += f.speed;
            if (f.x > 1.1) f.x = -0.2;
          } else {
            f.x -= f.speed;
            if (f.x < -0.2) f.x = 1.1;
          }
        }
      });
    });
  }

void _spawnInitialFishes() {
    fishes = [
      _FishTarget(x: 0.1, y: 0.2, speed: 0.007, name: 'Clownfish', emoji: '🐠', reward: 30, isMovingRight: true),
      _FishTarget(x: 0.6, y: 0.35, speed: 0.005, name: 'Turtle', emoji: '🐢', reward: 80, isMovingRight: false),
      _FishTarget(x: 0.2, y: 0.5, speed: 0.009, name: 'Blue Tang', emoji: '🐟', reward: 50, isMovingRight: true),
      _FishTarget(x: 0.8, y: 0.65, speed: 0.004, name: 'Shark', emoji: '🦈', reward: 250, isMovingRight: false),
      _FishTarget(x: -0.1, y: 0.3, speed: 0.003, name: 'Golden Whale', emoji: '🐋', reward: 600, isMovingRight: true),
    ];
  }

  @override
  void dispose() {
    _gameLoopTimer.cancel();
    super.dispose();
  }

  // ስክሪኑ ሲነካ ጥይት ይተኩሳል
  void _shootAt(TapDownDetails details, Size size) {
    if (AppData.userCoins < selectedBet) {
      setState(() => statusMsg = 'በቂ ሳንቲም የለዎትም!');
      return;
    }

    setState(() {
      AppData.userCoins -= selectedBet;
    });
    widget.onCoinsChanged();

    double tapX = details.localPosition.dx / size.width;
    double tapY = details.localPosition.dy / size.height;

    // አሳ ተመቷል ወይ ማረጋገጥ
    bool hitAny = false;
    for (var f in fishes) {
      double dx = (f.x - tapX).abs();
      double dy = (f.y - tapY).abs();

      if (dx < 0.12 && dy < 0.10) {
        // አሳው ተመቷል!
        hitAny = true;
        int winAmount = (f.reward * (selectedBet / 50)).round();
        setState(() {
          AppData.userCoins += winAmount;
          statusMsg = '🎯 ${f.name} ተመታ! +$winAmount ሳንቲም አሸነፉ!';
          // አሳው ሲመታ ቦታውን ይቀይራል
          f.x = f.isMovingRight ? -0.2 : 1.1;
        });
        widget.onCoinsChanged();

        // ትልቅ አሳ ከሆነ ለክፍሉ ማሳወቅ
        if (winAmount >= 200 && widget.socket != null) {
          widget.socket.emit('game_win', {
            'winner': AppData.currentUserName,
            'game': 'Ocean Hunt',
            'amount': winAmount,
          });
        }
        break;
      }
    }

    if (!hitAny) {
      setState(() {
        statusMsg = 'አልመታም! በድጋሚ ይሞክሩ 🎯';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapDown: (details) => _shootAt(details, size),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF0D47A1), // የባህር ሰማያዊ
                  Color(0xFF001026), // ጥልቅ ውቅያኖስ
                ],
              ),
            ),
            child: Stack(
              children: [
                // የውቅያኖስ አረፋዎች
                Positioned(top: 20, left: 30, child: _buildBubble(18)),
                Positioned(top: 80, right: 40, child: _buildBubble(26)),
                Positioned(top: 180, left: 80, child: _buildBubble(14)),

                // የሚዋኙ አሳዎች
                ...fishes.map((f) {
                  return Positioned(
                    left: f.x * size.width,
                    top: f.y * size.height,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(f.isMovingRight ? 1.0 : -1.0, 1.0),
                      child: Column(
                        children: [
                          Text(f.emoji, style: const TextStyle(fontSize: 38)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(

color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
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

                // የውጤት ጽሁፍ
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                      ),
                      child: Text(
                        statusMsg,
                        style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                // የመድፍ መቆጣጠሪያና ውርርድ (Bottom Turret Bar)
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF051026).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // መድፍ
                        Row(
                          children: const [
                            Icon(Icons.gps_fixed_rounded, color: Colors.cyanAccent, size: 28),
                            SizedBox(width: 6),
                            Text('CANNON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                        // የጥይት ሳንቲም ምርጫ
                        Row(
                          children: [10, 50, 100, 500].map((b) {
                            final sel = selectedBet == b;
                            return GestureDetector(
                              onTap: () => setState(() => selectedBet = b),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel ? const Color(0xFFFFD700) : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$b',
                                  style: TextStyle(
                                    color: sel ? Colors.black : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildBubble(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}
