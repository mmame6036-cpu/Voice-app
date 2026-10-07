import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class ChickenRoadGameView extends StatefulWidget {
  final dynamic socket;
  final VoidCallback onCoinsChanged;

  const ChickenRoadGameView({Key? key, this.socket, required this.onCoinsChanged}) : super(key: key);

  @override
  State<ChickenRoadGameView> createState() => _ChickenRoadGameViewState();
}

class _Car {
  final int laneIndex;
  double y;
  final double speed;
  final String emoji;
  _Car({required this.laneIndex, required this.y, required this.speed, required this.emoji});
}

class _ChickenRoadGameViewState extends State<ChickenRoadGameView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _gameLoopTimer;
  final Random _rnd = Random();

  String selectedDifficulty = 'MEDIUM';
  int betAmount = 100;
  bool isPlaying = false;
  int currentLane = 0;
  String statusMsg = 'ውርርድ ይምረጡና PLAY ይጫኑ!';

  List<_Car> cars = [];

  final Map<String, List<double>> difficultyMultipliers = {
    'EASY': [
      1.03, 1.06, 1.10, 1.15, 1.21, 1.28, 1.36, 1.45, 1.56, 1.68,
      1.82, 1.98, 2.17, 2.39, 2.65, 2.96, 3.33, 3.77, 4.31, 4.97,
      5.79, 6.82, 8.14, 9.87, 12.18, 15.34, 19.82, 26.43, 36.85, 54.12
    ],
    'MEDIUM': [
      1.08, 1.21, 1.37, 1.56, 1.78, 2.05, 2.37, 2.77, 3.24, 3.85,
      4.62, 5.61, 6.91, 8.64, 10.99, 14.29, 18.96, 26.07, 37.24, 53.82,
      82.36, 137.59, 256.36, 638.82, 2457.0, 5800.0, 12000.0, 24000.0, 48000.0, 96000.0
    ],
    'HARD': [
      1.18, 1.46, 1.83, 2.31, 2.95, 3.82, 5.02, 6.66, 9.04, 12.52,
      17.74, 25.80, 38.71, 60.21, 97.40, 166.87, 305.94, 595.86, 1283.03, 3267.64,
      10891.94, 62182.19, 150000.0, 300000.0, 600000.0, 1200000.0, 2500000.0, 5000000.0, 10000000.0, 20000000.0
    ],
    'HELL': [
      1.44, 2.21, 3.45, 5.53, 9.09, 15.09, 26.78, 48.70, 92.54, 185.08,
      391.25, 894.28, 2235.72, 6096.15, 18600.32, 64232.79, 267920.8, 800000.0, 2400000.0, 7200000.0,
      21600000.0, 64800000.0, 194400000.0, 583200000.0, 1000000000.0, 2000000000.0, 4000000000.0, 8000000000.0, 16000000000.0, 32000000000.0
    ],
  };

  @override
  void initState() {
    super.initState();
    _spawnCars();

    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) return;
      setState(() {
        for (var c in cars) {
          c.y += c.speed;
          if (c.y > 1.2) {
            c.y = -0.3;
          }
        }
      });
    });
  }

  void _spawnCars() {
    cars.clear();
    final carIcons = ['🚒', '🚓', '🚕', '🚙', '🚑', '🚌'];
    for (int lane = 1; lane <= 30; lane++) {
      int carCount = selectedDifficulty == 'EASY'
          ? 1
          : selectedDifficulty == 'MEDIUM'
              ? 2
              : selectedDifficulty == 'HARD'
                  ? 2
                  : 3;

      for (int i = 0; i < carCount; i++) {
        cars.add(_Car(
          laneIndex: lane,
          y: -0.2 - (i * 0.5) - (_rnd.nextDouble() * 0.3),
          speed: 0.015 + (_rnd.nextDouble() * 0.02),
          emoji: carIcons[_rnd.nextInt(carIcons.length)],
        ));
      }
    }
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlayOrCashOut() {
    if (!isPlaying) {
      if (AppData.userCoins < betAmount) {
        _showInsufficientBalance();
        return;
      }

      setState(() {
        AppData.userCoins -= betAmount;
        isPlaying = true;
        currentLane = 0;
        statusMsg = 'ዶሮዋን ለማሻገር መስመሩን ይንኩ!';
      });
      widget.onCoinsChanged();
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      if (currentLane == 0) return;
      final mult = difficultyMultipliers[selectedDifficulty]![currentLane - 1];
      final win = (betAmount * mult).round();

      setState(() {
        AppData.userCoins += win;
        isPlaying = false;
        currentLane = 0;
        statusMsg = '🎉 አሸነፉ! +$win ሳንቲም ተሰብስቧል!';
      });
      widget.onCoinsChanged();

if (win >= 500 && widget.socket != null) {
        widget.socket.emit('game_win', {
          'winner': AppData.currentUserName,
          'game': 'Chicken Road',
          'amount': win,
        });
      }
    }
  }

  void _stepToLane(int targetLane) {
    if (!isPlaying || targetLane != currentLane + 1) return;

    double crashChance = selectedDifficulty == 'EASY'
        ? 0.08
        : selectedDifficulty == 'MEDIUM'
            ? 0.16
            : selectedDifficulty == 'HARD'
                ? 0.28
                : 0.42;

    if (_rnd.nextDouble() < crashChance) {
      setState(() {
        isPlaying = false;
        currentLane = 0;
        statusMsg = '💥 መኪና ገጨዎት! ውርርዱ ተበልቷል!';
      });
      return;
    }

    setState(() {
      currentLane = targetLane;
      final mult = difficultyMultipliers[selectedDifficulty]![currentLane - 1];
      final currentWin = (betAmount * mult).round();
      statusMsg = 'ደረጃ $currentLane ተሻገሩ! እጥፍ: ${mult}x (+$currentWin)';
    });

    final scrollTarget = (currentLane * 74.0) - 120.0;
    if (scrollTarget > 0) {
      _scrollController.animateTo(
        scrollTarget,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }

    if (currentLane == 30) {
      final mult = difficultyMultipliers[selectedDifficulty]![29];
      final jackpot = (betAmount * mult).round();
      setState(() {
        AppData.userCoins += jackpot;
        isPlaying = false;
        currentLane = 0;
        statusMsg = '🏆 ጃክፖት! 30ኛውን ደረጃ ጨርሰው +$jackpot አሸነፉ!';
      });
      widget.onCoinsChanged();
    }
  }

  void _showInsufficientBalance() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E143E),
        title: const Text('Insufficient Balance', style: TextStyle(color: Colors.white, fontSize: 15)),
        content: const Text('Insufficient account balance go to recharge?', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final multipliers = difficultyMultipliers[selectedDifficulty]!;
    final double currentMult = currentLane > 0 ? multipliers[currentLane - 1] : 0.0;
    final int currentWin = (betAmount * currentMult).round();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E2430),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    statusMsg,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPlaying && currentLane > 0)
                  Text('+$currentWin 🪙', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: 31 * 74.0 + 80.0,
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: double.infinity,
                      color: const Color(0xFF4CAF50),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (currentLane == 0)
                            const Text('🐔', style: TextStyle(fontSize: 36))
                          else
                            const Text('🏁', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          const Text('START', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                    ...List.generate(30, (idx) {
                      final laneNum = idx + 1;
                      final mult = multipliers[idx];
                      final isCurrent = currentLane == laneNum;

                      return GestureDetector(
                        onTap: () => _stepToLane(laneNum),
                        child: Container(
                          width: 74,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF37474F),
                            border: Border(
                              right: const BorderSide(color: Colors.white24, width: 1.5),
                              left: idx == 0 ? const BorderSide(color: Colors.white24, width: 1.5) : BorderSide.none,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 10,
                                bottom: 50,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(4, (_) => Container(width: 4, height: 16, color: Colors.white24)),
                                ),
                              ),
                              ...cars.where((c) => c.laneIndex == laneNum).map((c) {
                                return Positioned(
                                  top: c.y * 180,
                                  child: Text(c.emoji, style: const TextStyle(fontSize: 26)),
                                );
                              }).toList(),
                              if (isCurrent)
                                const Positioned(
                                  bottom: 48,
                                  child: Text('🐔', style: TextStyle(fontSize: 32)),
                                ),
                              Positioned(
                                bottom: 6,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCurrent ? const Color(0xFFFFD700) : Colors.black87,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isCurrent ? Colors.amber : Colors.white24),

),
                                      child: Text(
                                        '${mult}x',
                                        style: TextStyle(
                                          color: isCurrent ? Colors.black : Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$laneNum',
                                      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF10141D),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['EASY', 'MEDIUM', 'HARD', 'HELL'].map((diff) {
                    final isSel = selectedDifficulty == diff;
                    return GestureDetector(
                      onTap: isPlaying
                          ? null
                          : () {
                              setState(() {
                                selectedDifficulty = diff;
                                _spawnCars();
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFD700) : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          diff,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.blueAccent, size: 26),
                      onPressed: isPlaying || betAmount <= 50 ? null : () => setState(() => betAmount -= 50),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                      ),
                      child: Text('BET $betAmount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 26),

onPressed: isPlaying ? null : () => setState(() => betAmount += 50),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlaying ? Colors.amber : const Color(0xFF00E676),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _onPlayOrCashOut,
                      child: Text(
                        isPlaying ? (currentLane > 0 ? 'CASH OUT' : 'WAIT') : 'PLAY',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
