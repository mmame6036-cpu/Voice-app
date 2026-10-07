import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class RoomGamesSheet {
  static void show(BuildContext context, {VoidCallback? onCoinsChanged}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoomGamesSheetContent(onCoinsChanged: onCoinsChanged),
    );
  }
}

class _RoomGamesSheetContent extends StatefulWidget {
  final VoidCallback? onCoinsChanged;
  const _RoomGamesSheetContent({Key? key, this.onCoinsChanged}) : super(key: key);

  @override
  State<_RoomGamesSheetContent> createState() => _RoomGamesSheetContentState();
}

class _RoomGamesSheetContentState extends State<_RoomGamesSheetContent> {
  String? activeGame;

  // Lucky Dice State
  int diceResult = 1;
  bool isRollingDice = false;

  // Chicken Road State
  int chickenStep = 0;
  bool chickenAlive = true;
  bool isPlayingChicken = false;
  int chickenBet = 0;

  // Winner Announcement
  final List<String> _marqueeMessages = [
    "🎉 User_8829 won 5,000 Coins in Lucky Dice!",
    "🔥 SuperHost reached 5x multiplier in Chicken Road!",
    "✨ Kadir won 10,000 Coins in Lucky Wheel!",
  ];
  int _currentMsgIndex = 0;
  Timer? _marqueeTimer;

  @override
  void initState() {
    super.initState();
    _marqueeTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentMsgIndex = (_currentMsgIndex + 1) % _marqueeMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _marqueeTimer?.cancel();
    super.dispose();
  }

  // --- Lucky Dice Game Logic ---
  void _playDiceGame(int betAmount) {
    if (AppData.userCoins < betAmount) {
      _showCoinAlert();
      return;
    }

    setState(() {
      AppData.userCoins -= betAmount;
      isRollingDice = true;
    });
    widget.onCoinsChanged?.call();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final outcome = Random().nextInt(6) + 1;
      final bool won = outcome >= 4;
      final winAmount = won ? (betAmount * 2) : 0;

      setState(() {
        diceResult = outcome;
        isRollingDice = false;
        if (won) {
          AppData.userCoins += winAmount;
        }
      });
      widget.onCoinsChanged?.call();

      _showSnackBar(
        won
            ? '🎉 እንኳን ደስ አለዎት! ዳይሱ $outcome ወጥቶ +$winAmount ኮይን አሸነፉ!'
            : 'ዳይሱ $outcome ወጥቷል። በሚቀጥለው ዙር ይሞክሩ!',
        won ? const Color(0xFF00C9A7) : Colors.redAccent,
      );
    });
  }

  // --- Chicken Road Logic ---
  void _startChickenRoad(int betAmount) {
    if (AppData.userCoins < betAmount) {
      _showCoinAlert();
      return;
    }

    setState(() {
      AppData.userCoins -= betAmount;
      chickenBet = betAmount;
      chickenStep = 0;
      chickenAlive = true;
      isPlayingChicken = true;
    });
    widget.onCoinsChanged?.call();
  }

  void _stepChickenForward() {
    if (!isPlayingChicken || !chickenAlive) return;

    final isTrap = Random().nextInt(100) < 30; // 30% chance to hit car/trap
    if (isTrap) {
      setState(() {
        chickenAlive = false;
        isPlayingChicken = false;
      });
      _showSnackBar('💥 አደጋ ደረሰ! ዶሮዋ መንገድ ላይ ተገጭታለች።', Colors.redAccent);
    } else {
      setState(() {
        chickenStep++;
      });
      if (chickenStep >= 4) {
        _cashOutChicken();
      }
    }
  }

  void _cashOutChicken() {
    if (!isPlayingChicken || !chickenAlive) return;

    final multiplier = [1.2, 1.6, 2.2, 3.5, 5.0][min(chickenStep, 4)];
    final winCoins = (chickenBet * multiplier).toInt();

    setState(() {
      AppData.userCoins += winCoins;
      isPlayingChicken = false;
    });
    widget.onCoinsChanged?.call();

    _showSnackBar(
      '🏆 እንኳን ደስ አለዎት! ዶሮዋን በሰላም አሻግረው +$winCoins ኮይን ወስደዋል!',
      const Color(0xFFFFD700),
    );
  }

  void _showCoinAlert() {
    _showSnackBar('ኮይን አልበቃዎትም! እባክዎ መጀመሪያ አካውንትዎን ይሙሉ (Recharge).', Colors.redAccent);
  }

void _showSnackBar(String text, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF130E24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Coin Balance Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${AppData.userCoins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activeGame == null ? 'Mini Game Center' : activeGame!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    activeGame == null ? Icons.close : Icons.arrow_back,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    if (activeGame != null) {
                      setState(() => activeGame = null);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // Marquee Winner Announcement
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _marqueeMessages[_currentMsgIndex],

style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Game Body
          Expanded(
            child: activeGame == null
                ? _buildGamesGrid()
                : (activeGame == 'Lucky Dice'
                    ? _buildDiceView()
                    : _buildChickenRoadView()),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesGrid() {
    final List<Map<String, dynamic>> games = [
      {'title': 'Chicken Road', 'tag': 'HOT 🔥', 'color': const Color(0xFFFF9500), 'icon': Icons.directions_run},
      {'title': 'Lucky Dice', 'tag': 'Popular 🎲', 'color': const Color(0xFF00C9A7), 'icon': Icons.casino},
      {'title': 'Lucky Wheel', 'tag': 'Bonus 🎁', 'color': const Color(0xFF9C27B0), 'icon': Icons.track_changes},
      {'title': 'Fruit Slot', 'tag': 'Jackpot 🍒', 'color': const Color(0xFFE91E63), 'icon': Icons.stars},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final g = games[index];
        final color = g['color'] as Color;
        return GestureDetector(
          onTap: () {
            setState(() {
              activeGame = g['title'] as String;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1C1635),
                  color.withOpacity(0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  radius: 26,
                  child: Icon(g['icon'] as IconData, color: color, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  g['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    g['tag'] as String,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiceView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF00C9A7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),

border: Border.all(color: const Color(0xFF00C9A7), width: 2),
            ),
            child: Center(
              child: isRollingDice
                  ? const CircularProgressIndicator(color: Color(0xFF00C9A7))
                  : Text(
                      '$diceResult',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRollingDice ? 'ዳይሱ እየተሽከረከረ ነው...' : 'ውጤት: $diceResult (4-6 ካሸነፈ 2x ያገኛሉ)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isRollingDice ? null : () => _playDiceGame(100),
                child: const Text('በ 100 ኮይን', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              const SizedBox(width: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isRollingDice ? null : () => _playDiceGame(500),
                child: const Text('በ 500 ኮይን', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChickenRoadView() {
    final multipliers = [1.2, 1.6, 2.2, 3.5, 5.0];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isReached = index <= chickenStep && isPlayingChicken;
              final isCurrent = index == chickenStep && isPlayingChicken;
              return Column(
                children: [
                  Text('${multipliers[index]}x', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Colors.orange.withOpacity(0.3)
                          : (isReached ? Colors.green.withOpacity(0.2) : Colors.white10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? Colors.orange : (isReached ? Colors.green : Colors.white24),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isCurrent
                          ? const Text('🐔', style: TextStyle(fontSize: 26))
                          : (isReached
                              ? const Icon(Icons.check, color: Colors.greenAccent, size: 24)
                              : Text('${index + 1}', style: const TextStyle(color: Colors.white54))),

),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 32),
          if (!isPlayingChicken) ...[
            const Text(
              'ዶሮዋን መንገድ ሳታስገጭ አሻግረህ ከፍተኛ ኮይን ውሰድ!',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9500),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _startChickenRoad(100),
                  child: const Text('በ 100 ጀምር', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _startChickenRoad(500),
                  child: const Text('በ 500 ጀምር', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9500),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _stepChickenForward,
                  icon: const Icon(Icons.arrow_forward, color: Colors.black),
                  label: const Text('ወደፊት ተሻገር 🐾', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9A7),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _cashOutChicken,
                  icon: const Icon(Icons.download_done, color: Colors.black),
                  label: const Text('ገንዘብ ውሰድ (Cash Out)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
