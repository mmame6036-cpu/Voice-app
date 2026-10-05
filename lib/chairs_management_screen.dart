import 'package:flutter/material.dart';

class ChairsManagementScreen extends StatefulWidget {
  const ChairsManagementScreen({Key? key}) : super(key: key);

  @override
  State<ChairsManagementScreen> createState() => _ChairsManagementScreenState();
}

class _ChairsManagementScreenState extends State<ChairsManagementScreen> {
  // ዩዘሩ በጌም ያንቀሳቀሰው ጠቅላላ ኮይን (ከሰርቨር ወይም ከAppData የሚመጣ)
  int gameCoinsSpent = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      appBar: AppBar(
        title: const Text('የወንበሮች ደረጃ እና መብት (30 Chairs)'),
        backgroundColor: const Color(0xFF161B26),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // የስታተስ ካርድ
            _buildStatusHeader(),
            const SizedBox(height: 20),

            // ደረጃ 1፦ ወንበር 1 - 10 (ነፃ)
            _buildTierSection(
              title: 'ደረጃ 1፦ መደበኛ ወንበሮች (1 - 10)',
              subtitle: 'ለሁሉም አዲስ ተጠቃሚ ክፍት',
              startChair: 1,
              endChair: 10,
              isUnlocked: true,
              badgeColor: Colors.greenAccent,
            ),
            const SizedBox(height: 24),

            // ደረጃ 2፦ ወንበር 11 - 20 (200k ኮይን)
            _buildTierSection(
              title: 'ደረጃ 2፦ ቪአይፒ ወንበሮች (11 - 20)',
              subtitle: 'በጌም 200,000 ኮይን ሲንቀሳቀስ የሚከፈት (+20,000 Points ስጦታ)',
              startChair: 11,
              endChair: 20,
              isUnlocked: gameCoinsSpent >= 200000,
              badgeColor: Colors.amber,
              requiredCoins: 200000,
              rewardPoints: 20000,
            ),
            const SizedBox(height: 24),

            // ደረጃ 3፦ ወንበር 21 - 30 (ተጨማሪ 200k ኮይን)
            _buildTierSection(
              title: 'ደረጃ 3፦ ፕሪሚየም ወንበሮች (21 - 30)',
              subtitle: 'በጌም 400,000 ኮይን ሲንቀሳቀስ የሚከፈት (+20,000 Points ስጦታ)',
              startChair: 21,
              endChair: 30,
              isUnlocked: gameCoinsSpent >= 400000,
              badgeColor: Colors.purpleAccent,
              requiredCoins: 400000,
              rewardPoints: 20000,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2232),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('በጌም ያንቀሳቀሱት ኮይን', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '$gameCoinsSpent Coins',
                style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Icon(Icons.sports_esports, color: Colors.amber, size: 36),
        ],
      ),
    );
  }

  Widget _buildTierSection({
    required String title,
    required String subtitle,
    required int startChair,
    required int endChair,
    required bool isUnlocked,
    required Color badgeColor,
    int? requiredCoins,
    int? rewardPoints,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnlocked ? badgeColor.withOpacity(0.5) : Colors.white10),
      ),

child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 15)),
              Icon(isUnlocked ? Icons.lock_open : Icons.lock, color: isUnlocked ? Colors.greenAccent : Colors.redAccent, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 14),

          // 10ሩን ወንበሮች በ Grid ማሳያ
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final chairNumber = startChair + index;
              return Container(
                decoration: BoxDecoration(
                  color: isUnlocked ? badgeColor.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUnlocked ? badgeColor : Colors.white12,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chair,
                      color: isUnlocked ? badgeColor : Colors.white30,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$chairNumber',
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
