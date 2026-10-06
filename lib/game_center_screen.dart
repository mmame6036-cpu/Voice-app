import 'package:flutter/material.dart';
import 'main.dart'; // ለ AppData.userCoins

class GameCenterScreen extends StatefulWidget {
  final VoidCallback? onCoinsUpdated;
  const GameCenterScreen({Key? key, this.onCoinsUpdated}) : super(key: key);

  @override
  State<GameCenterScreen> createState() => _GameCenterScreenState();
}

class _GameCenterScreenState extends State<GameCenterScreen> {
  // የጌሞች ዝርዝር (ወደፊት አዲስ ጌም ሲኖር እዚህ ሊስት ውስጥ መጨመር ብቻ ነው)
  final List<Map<String, dynamic>> games = [
    {
      'id': 'chicken_road',
      'title': 'Chicken Road',
      'tag': 'Hot 🔥',
      'minBet': 100,
      'color': const Color(0xFFFF9500),
      'icon': Icons.directions_run_rounded,
      'desc': 'Cross the road & win multipliers!',
    },
    {
      'id': 'lucky_wheel',
      'title': 'Lucky Wheel',
      'tag': 'Bonus 🎁',
      'minBet': 50,
      'color': const Color(0xFF9C27B0),
      'icon': Icons.track_changes_rounded,
      'desc': 'Spin to win up to 500x coins!',
    },
    {
      'id': 'fruit_slots',
      'title': 'Fruit Slot',
      'tag': 'Classic 🍒',
      'minBet': 200,
      'color': const Color(0xFFE91E63),
      'icon': Icons.casino_rounded,
      'desc': 'Match fruits and hit the jackpot!',
    },
    {
      'id': 'greedy_dice',
      'title': 'Lucky Dice',
      'tag': 'Popular 🎲',
      'minBet': 50,
      'color': const Color(0xFF00C9A7),
      'icon': Icons.sports_esports_rounded,
      'desc': 'Guess high or low to win instantly!',
    },
  ];

  void _launchGame(Map<String, dynamic> game) {
    if (AppData.userCoins < (game['minBet'] as int)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E2430),
          title: const Text('ኮይን አልበቃዎትም', style: TextStyle(color: Colors.white)),
          content: Text(
            'ይህንን ጌም ለመጫወት ቢያንስ ${game['minBet']} ኮይን ያስፈልግዎታል። እባክዎ መጀመሪያ ኮይን ይግዙ።',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('እሺ', style: TextStyle(color: Color(0xFF00C9A7))),
            ),
          ],
        ),
      );
      return;
    }

    // ጌሙን ለመክፈት የሚደረግ አላርት/ስክሪን
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(game['icon'] as IconData, size: 60, color: game['color'] as Color),
            const SizedBox(height: 12),
            Text(
              game['title'],
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              game['desc'],
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: game['color'] as Color,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                // የሙከራ ጨዋታ፡ 100 ኮይን ቆርጦ ማጫወት
                setState(() {
                  AppData.userCoins -= (game['minBet'] as int);
                  widget.onCoinsUpdated?.call();
                });
                ScaffoldMessenger.of(context).showSnackBar(

SnackBar(
                    content: Text('${game['title']} ተጀምሯል! ${game['minBet']} ኮይን ተቀናሽ ሆኗል።'),
                    backgroundColor: game['color'] as Color,
                  ),
                );
              },
              child: Text(
                'ጀምር (${game['minBet']} Coins)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text(
          'Game Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // የተጠቃሚው ኮይን መጠን ከላይ
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 6),
                Text(
                  '${AppData.userCoins}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B11FF), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mini Games Arena',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Play & win huge coins right inside Nile Voice!',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.military_tech_rounded, size: 50, color: Color(0xFFFFD700)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'ታዋቂ ጌሞች (Popular Games)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Game Cards Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: games.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final g = games[index];
                return GestureDetector(
                  onTap: () => _launchGame(g),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (g['color'] as Color).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(g['icon'] as IconData, color: g['color'] as Color, size: 28),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (g['color'] as Color).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                g['tag'],
                                style: TextStyle(
                                  color: g['color'] as Color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          g['title'],
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Min: ${g['minBet']} coins',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
