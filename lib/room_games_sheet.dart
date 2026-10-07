import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';
import 'chicken_road_game.dart';

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
    final double sheetHeight = activeGameTitle != null
        ? MediaQuery.of(context).size.height * 0.58
        : MediaQuery.of(context).size.height * 0.50;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (activeGameTitle != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    onPressed: () => setState(() => activeGameTitle = null),
                  )
                else
                  const SizedBox(width: 32),
                Text(
                  activeGameTitle ?? 'Room Games',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${AppData.userCoins}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                : activeGameTitle == 'Chicken Road'
                    ? ChickenRoadGameView(
                        socket: widget.socket,
                        onCoinsChanged: widget.onCoinsChanged,
                      )
                    : activeGameTitle == 'Ocean Hunt'
                        ? OceanHuntGameView(
                            socket: widget.socket,
                            onCoinsChanged: widget.onCoinsChanged,
                          )
                        : TreasuresSlotGameView(
                            gameName: activeGameTitle!,
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
      {'title': 'Chicken Road', 'subtitle': 'የዶሮዋ መንገድ (30 ደረጃዎች)', 'icon': Icons.egg_rounded, 'color': Colors.amber},
      {'title': 'Treasures', 'subtitle': 'ባለ 5-ሪል ስፒን', 'icon': Icons.casino_rounded, 'color': Colors.deepOrangeAccent},
      {'title': 'Ocean Hunt', 'subtitle': 'የአሳ አደን እና መድፍ', 'icon': Icons.water_drop_rounded, 'color': Colors.blueAccent},
      {'title': 'Fruit Party', 'subtitle': 'የፍራፍሬ ስፒን', 'icon': Icons.fastfood_rounded, 'color': Colors.orangeAccent},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: games.length,
      itemBuilder: (context, idx) {
        final g = games[idx];
        return GestureDetector(
          onTap: () => setState(() => activeGameTitle = g['title'] as String),
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
                Icon(g['icon'] as IconData, color: g['color'] as Color, size: 36),
                const SizedBox(height: 6),
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
                  child: const Text('PLAY', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
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
// TREASURES (5-REEL SLOT MACHINE)
// ==========================================
class TreasuresSlotGameView extends StatefulWidget {
  final String gameName;
  final dynamic socket;
  final VoidCallback onCoinsChanged;

  const TreasuresSlotGameView({
    Key? key,
    required this.gameName,
    this.socket,
    required this.onCoinsChanged,
  }) : super(key: key);

  @override
  State<TreasuresSlotGameView> createState() => _TreasuresSlotGameViewState();
}

class _TreasuresSlotGameViewState extends State<TreasuresSlotGameView> {
  final List<String> symbols = ['🐙', '10', '👾', 'J', '🐢', 'K', 'Q', '💎', '⭐'];
  late List<List<String>> reels;
  bool isSpinning = false;
  int singleLineBet = 10;
  final int winningLines = 12;
  int winAmount = 0;
  Timer? _spinTimer;

  int get totalBet => singleLineBet * winningLines;

  @override
  void initState() {
    super.initState();
    reels = [
      ['🐙', '10', '🐢'],
      ['10', '👾', 'Q'],
      ['👾', 'K', '🐢'],
      ['J', 'Q', '💎'],
      ['🐢', '💎', '⭐'],
    ];
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  void _spin() {
    if (isSpinning) return;
    if (AppData.userCoins < totalBet) return;

    setState(() {
      isSpinning = true;
      AppData.userCoins -= totalBet;
      winAmount = 0;
    });
    widget.onCoinsChanged();

    final rnd = Random();
    int ticks = 0;

_spinTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      ticks++;
      setState(() {
        for (int c = 0; c < 5; c++) {
          for (int r = 0; r < 3; r++) {
            reels[c][r] = symbols[rnd.nextInt(symbols.length)];
          }
        }
      });

      if (ticks >= 12) {
        timer.cancel();
        final won = rnd.nextBool();
        int calculatedWin = won ? (totalBet * (2 + rnd.nextInt(4))) : 0;

        setState(() {
          isSpinning = false;
          winAmount = calculatedWin;
          if (calculatedWin > 0) AppData.userCoins += calculatedWin;
        });
        widget.onCoinsChanged();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A0845), Color(0xFF100720)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.purple, Colors.deepPurpleAccent])),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.gameName.toUpperCase(), style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                Text('WIN: $winAmount', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (colIdx) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (rowIdx) {
                      return Container(
                        width: 52,
                        height: 48,
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Text(reels[colIdx][rowIdx], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black54,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('TOTAL BET', style: TextStyle(color: Colors.white54, fontSize: 9)),

Text('$totalBet 🪙', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF76FF03),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSpinning ? null : _spin,
                    child: Text(
                      isSpinning ? 'SPINNING...' : 'SPIN',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// OCEAN HUNT (የአሳ አደን እና መድፍ)
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

class _OceanHuntGameViewState extends State<OceanHuntGameView> {
  late Timer _gameLoopTimer;
  int selectedBet = 50;
  List<_FishTarget> fishes = [];
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
            if (f.x > 1.15) f.x = -0.2;
          } else {
            f.x -= f.speed;
            if (f.x < -0.25) f.x = 1.15;
          }
        }
      });
    });
  }

  void _spawnFishes() {
    fishes = [
      _FishTarget(x: -0.1, y: 0.20, speed: 0.007, name: 'Clownfish', emoji: '🐠', size: 36, reward: 20, isMovingRight: true),
      _FishTarget(x: 1.1, y: 0.35, speed: 0.005, name: 'Turtle', emoji: '🐢', size: 42, reward: 60, isMovingRight: false),
      _FishTarget(x: -0.2, y: 0.50, speed: 0.004, name: 'Shark', emoji: '🦈', size: 54, reward: 250, isMovingRight: true),
      _FishTarget(x: 1.15, y: 0.65, speed: 0.006, name: 'Octopus', emoji: '🐙', size: 44, reward: 120, isMovingRight: false),
    ];
  }

  @override
  void dispose() {
    _gameLoopTimer.cancel();
    super.dispose();
  }

  void _fireCannon(TapDownDetails details, Size size) {
    if (AppData.userCoins < selectedBet) return;

    setState(() {
      AppData.userCoins -= selectedBet;
    });
    widget.onCoinsChanged();

    final tapPos = details.localPosition;
    final cannonPos = Offset(size.width / 2, size.height - 40);
    final dx = tapPos.dx - cannonPos.dx;
    final dy = tapPos.dy - cannonPos.dy;
    setState(() {
      cannonAngle = atan2(dx, -dy);
    });

    final tapXRatio = tapPos.dx / size.width;
    final tapYRatio = tapPos.dy / size.height;

    for (var f in fishes) {
      if ((f.x - tapXRatio).abs() < 0.12 && (f.y - tapYRatio).abs() < 0.10) {
        int win = (f.reward * (selectedBet / 50)).round();
        setState(() {
          AppData.userCoins += win;
          statusMsg = '🎉 ${f.name} ተመታ! +$win ሳንቲም!';
          f.x = f.isMovingRight ? -0.25 : 1.15;
        });
        widget.onCoinsChanged();
        break;
      }
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
                colors: [Color(0xFF0D47A1), Color(0xFF041936), Color(0xFF010814)],
              ),
            ),
            child: Stack(
              children: [
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
                          Text('+${f.reward}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                      child: Text(statusMsg, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 35,
                  left: (size.width / 2) - 20,
                  child: Transform.rotate(
                    angle: cannonAngle,
                    alignment: Alignment.bottomCenter,
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.cyanAccent, size: 40),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
