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
    // ጌም ሲመረጥ ልክ እንደ ቪዲዮው የስክሪኑን ግማሽ ያህል (0.55) ይይዛል
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
          // የላይኛው መጎተቻ ባር
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // ራስጌ (Header)
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

          // እያንዳንዱ ጌም በራሱ የተለየ ስክሪን ይከፍታል
          Expanded(
            child: activeGameTitle == null
                ? _buildGameCards()
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

// የጌሞች መምረጫ ካርዶች
  Widget _buildGameCards() {
    final games = [
      {'title': 'Treasures', 'subtitle': 'ባለ 5-ሪል ስፒን', 'icon': Icons.casino_rounded, 'color': Colors.amber},
      {'title': 'Ocean Hunt', 'subtitle': 'የአሳ አደን እና መድፍ', 'icon': Icons.water_drop_rounded, 'color': Colors.blueAccent},
      {'title': 'Fruit Party', 'subtitle': 'የፍራፍሬ ስፒን', 'icon': Icons.fastfood_rounded, 'color': Colors.orangeAccent},
      {'title': 'GaroGems', 'subtitle': 'የዕንቁ ሳጥን', 'icon': Icons.diamond_rounded, 'color': Colors.purpleAccent},
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

// =========================================================================
// 1. በቪዲዮው ላይ የታየው ትክክለኛው TREASURES / SLOT MACHINE ጨዋታ
// =========================================================================
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
    // 5 ሪሎች፣ እያንዳንዳቸው 3 ረድፎች አሏቸው
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

void _showBettingPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final betOptions = [10, 40, 75, 150, 250, 500, 1000, 2000, 3000, 4000, 5000];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E143E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please select your bet amount',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: betOptions.map((b) {
                      final sel = singleLineBet == b;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() => singleLineBet = b);
                          setState(() => singleLineBet = b);
                        },
                        child: Container(
                          width: 58,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF2979FF) : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? Colors.cyanAccent : Colors.transparent),
                          ),
                          child: Center(
                            child: Text(
                              '$b',
                              style: TextStyle(
                                color: sel ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Single line bet: $singleLineBet', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('Winning lines: $winningLines', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('Bet Amount: $totalBet', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF76FF03),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Confirm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

void _spin() {
    if (isSpinning) return;

    // ሳንቲም ካነሰ በቪዲዮው ላይ የታየው ማስጠንቀቂያ ይመጣል
    if (AppData.userCoins < totalBet) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E143E),
          title: const Text('Insufficient Balance', style: TextStyle(color: Colors.white, fontSize: 15)),
          content: const Text(
            'Insufficient account balance go to recharge?',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Yes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

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

      if (ticks >= 15) {
        timer.cancel();
        final won = rnd.nextBool();
        int calculatedWin = 0;
        if (won) {
          calculatedWin = (totalBet * (2 + rnd.nextInt(5)));
        }

        setState(() {
          isSpinning = false;
          winAmount = calculatedWin;
          if (calculatedWin > 0) {
            AppData.userCoins += calculatedWin;
          }
        });
        widget.onCoinsChanged();

        if (calculatedWin > 0 && widget.socket != null) {
          widget.socket.emit('game_win', {
            'winner': AppData.currentUserName,
            'game': widget.gameName,
            'amount': calculatedWin,
          });
        }
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
          // የጨዋታው ራስጌ ባነር
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple, Colors.deepPurpleAccent]),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.gameName.toUpperCase(), style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                Text('WIN: $winAmount', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),

          // 5-Reel Slot ቦርድ
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
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
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Center(
                          child: Text(
                            reels[colIdx][rowIdx],
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),

          // የታችኛው ውርርድ መምረጫ እና SPIN ቁልፍ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black54,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showBettingPanel,
                  child: Container(
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

// =========================================================================
// 2. እውነተኛው OCEAN HUNT (የአሳ አደን እና መረብ) ጨዋታ (ሳይጠፋ በራሱ ይከፈታል)
// =========================================================================
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
                Positioned(top: 20, left: 20, child: _buildBubble(14)),
                Positioned(top: 70, right: 30, child: _buildBubble(22)),

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

                ...bursts.map((b) {
                  final burstColor = b.reward > 0 ? const Color(0xFFFFD700) : Colors.redAccent;
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
                                border: Border.all(color: burstColor, width: 3),
                                gradient: RadialGradient(
                                  colors: [burstColor.withOpacity(0.4), Colors.transparent],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  b.reward > 0 ? Icons.auto_awesome : Icons.close,
                                  color: burstColor,
                                  size: 30,
                                ),

),
                            ),
                            Text(
                              b.text,
                              style: TextStyle(
                                color: burstColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                              ),
                            ),
                          ],
                        ),
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
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
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

                Positioned(
                  bottom: 45,
                  left: (size.width / 2) - 26,
                  child: Transform.rotate(
                    angle: cannonAngle,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.cyanAccent, Color(0xFF007799)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2A47),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.cyanAccent),
                          ),
                          child: const Icon(Icons.bolt, color: Colors.cyanAccent, size: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 6,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061126).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('⚡ CANNON', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                        Row(
                          children: [10, 50, 100, 500].map((b) {

final sel = selectedBet == b;
                            return GestureDetector(
                              onTap: () => setState(() => selectedBet = b),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
}
