import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart'; // AppData.userCoins ለመጠቀም

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
  String? activeGame; // የትኛው ጌም እየተጫወተ እንደሆነ ለመለየት
  int diceResult = 1;
  bool isRolling = false;

  void _playDiceGame(int betAmount) {
    if (AppData.userCoins < betAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ኮይን አልበቃዎትም! እባክዎ መጀመሪያ ይሙሉ (Recharge).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      AppData.userCoins -= betAmount;
      isRolling = true;
    });
    widget.onCoinsChanged?.call();

    // የዳይስ ማንከባለል ውጤት በሰከንዶች ውስጥ
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final outcome = Random().nextInt(6) + 1;
      final bool won = outcome >= 4; // 4, 5, 6 ከመጣ አሸነፈ
      final winAmount = won ? (betAmount * 2) : 0;

      setState(() {
        diceResult = outcome;
        isRolling = false;
        if (won) {
          AppData.userCoins += winAmount;
        }
      });
      widget.onCoinsChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            won
                ? '🎉 እንኳን ደስ አለዎት! ዳይሱ $outcome ወጥቶ +$winAmount ኮይን አሸነፉ!'
                : 'ዳይሱ $outcome ወጥቷል። በሚቀጥለው ይሞክሩ!',
          ),
          backgroundColor: won ? const Color(0xFF00C9A7) : Colors.black87,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        color: Color(0xFF161B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header: Coins & Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${AppData.userCoins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,

fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activeGame == null ? 'Mini Games' : activeGame!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

          // Running Winning Ticker (ልክ በቪዲዮው ላይ እንዳለው)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.15),
                  const Color(0xFFFF9500).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.campaign, color: Color(0xFFFFD700), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Asnu Kasa so lucky and won 300x in Game! 🔥',
                    style: TextStyle(
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

          // Main Area: Games Grid or Interactive Game
          Expanded(
            child: activeGame == null
                ? _buildGamesGrid()
                : _buildActiveGameView(),
          ),
        ],
      ),
    );
  }

  // የጌሞች ዝርዝር ማሳያ (Grid)
  Widget _buildGamesGrid() {
    final List<Map<String, dynamic>> games = [
      {
        'title': 'Lucky Dice',
        'tag': 'Popular 🎲',
        'color': const Color(0xFF00C9A7),
        'icon': Icons.casino,
      },
      {
        'title': 'Lucky Wheel',
        'tag': 'Bonus 🎁',
        'color': const Color(0xFF9C27B0),
        'icon': Icons.track_changes,
      },
      {
        'title': 'Fruit Slot',
        'tag': 'Jackpot 🍒',
        'color': const Color(0xFFE91E63),
        'icon': Icons.stars,
      },
      {
        'title': 'Chicken Road',
        'tag': 'Hot 🔥',
        'color': const Color(0xFFFF9500),
        'icon': Icons.directions_run,
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
              color: const Color(0xFF1E2432),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
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
                    color: color.withOpacity(0.15),
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

  // ጌሙ ሲከፈት የሚጫወቱበት ገጽ (Interactive Mini-game)
  Widget _buildActiveGameView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF00C9A7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00C9A7), width: 2),
            ),
            child: Center(
              child: isRolling
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
            isRolling ? 'እየተሽከረከረ ነው...' : 'ውጤት: $diceResult (4-6 ካሸነፈ 2x ያገኛሉ)',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isRolling ? null : () => _playDiceGame(100),
                child: const Text(
                  'በ 100 ኮይን ተጫወት',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

),
                onPressed: isRolling ? null : () => _playDiceGame(500),
                child: const Text(
                  'በ 500 ኮይን ተጫወት',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
