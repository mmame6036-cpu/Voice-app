import 'package:flutter/material.dart';

class ChairsManagementScreen extends StatefulWidget {
  final int userCoins;
  final int userPoints;

  const ChairsManagementScreen({
    Key? key,
    this.userCoins = 0,
    this.userPoints = 0,
  }) : super(key: key);

  @override
  State<ChairsManagementScreen> createState() => _ChairsManagementScreenState();
}

class _ChairsManagementScreenState extends State<ChairsManagementScreen> {
  late int currentPoints;
  late int gameCoinsSpent;

  bool tier2Claimed = false;
  bool tier3Claimed = false;

  @override
  void initState() {
    super.initState();
    currentPoints = widget.userPoints;
    gameCoinsSpent = widget.userCoins;
  }

  void _claimReward(int tier, int pointsReward) {
    setState(() {
      if (tier == 2) {
        tier2Claimed = true;
      } else if (tier == 3) {
        tier3Claimed = true;
      }
      currentPoints += pointsReward;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('እንኳን ደስ አለዎት! $pointsReward Points ተጨምሯል!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTier2Unlocked = gameCoinsSpent >= 200000;
    final bool isTier3Unlocked = gameCoinsSpent >= 400000;

    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      appBar: AppBar(
        title: const Text('የወንበሮች ደረጃ (30 Chairs)'),
        backgroundColor: const Color(0xFF161B26),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserSummaryCard(),
            const SizedBox(height: 18),

            // ደረጃ 1 (1 - 10)
            _buildTierCard(
              title: 'ደረጃ 1፦ መደበኛ ወንበሮች (1 - 10)',
              description: 'ለሁሉም አዲስ ተጠቃሚዎች ክፍት የሆነ',
              startChair: 1,
              endChair: 10,
              isUnlocked: true,
              themeColor: Colors.tealAccent,
              child: const SizedBox.shrink(),
            ),
            const SizedBox(height: 18),

            // ደረጃ 2 (11 - 20)
            _buildTierCard(
              title: 'ደረጃ 2፦ ቪአይፒ ወንበሮች (11 - 20)',
              description: 'በጌም 200,000 ኮይን ሲንቀሳቀስ ይከፈታል (+20,000 Points ስጦታ)',
              startChair: 11,
              endChair: 20,
              isUnlocked: isTier2Unlocked,
              themeColor: Colors.amber,
              child: _buildRewardSection(
                targetCoins: 200000,
                currentCoins: gameCoinsSpent,
                rewardPoints: 20000,
                isUnlocked: isTier2Unlocked,
                isClaimed: tier2Claimed,
                onClaim: () => _claimReward(2, 20000),
              ),
            ),
            const SizedBox(height: 18),

            // ደረጃ 3 (21 - 30)
            _buildTierCard(
              title: 'ደረጃ 3፦ ፕሪሚየም ወንበሮች (21 - 30)',
              description: 'በጌም 400,000 ኮይን ሲንቀሳቀስ ይከፈታል (+20,000 Points ስጦታ)',
              startChair: 21,
              endChair: 30,
              isUnlocked: isTier3Unlocked,
              themeColor: const Color(0xFFD946EF),
              child: _buildRewardSection(
                targetCoins: 400000,
                currentCoins: gameCoinsSpent,
                rewardPoints: 20000,
                isUnlocked: isTier3Unlocked,
                isClaimed: tier3Claimed,
                onClaim: () => _claimReward(3, 20000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2232),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),

),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('ያንቀሳቀሱት ኮይን', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 4),
              Text('$gameCoinsSpent', style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(height: 30, width: 1, color: Colors.white12),
          Column(
            children: [
              const Text('ያለዎት Points', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 4),
              Text('$currentPoints', style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String title,
    required String description,
    required int startChair,
    required int endChair,
    required bool isUnlocked,
    required Color themeColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnlocked ? themeColor.withOpacity(0.5) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(isUnlocked ? Icons.lock_open : Icons.lock, size: 14, color: isUnlocked ? Colors.greenAccent : Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      isUnlocked ? 'ክፍት ነው' : 'ዝግ ነው',
                      style: TextStyle(color: isUnlocked ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final chairNum = startChair + index;
              return Container(
                decoration: BoxDecoration(
                  color: isUnlocked ? themeColor.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUnlocked ? themeColor.withOpacity(0.7) : Colors.white12,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chair, color: isUnlocked ? themeColor : Colors.white24, size: 22),

const SizedBox(height: 2),
                    Text(
                      '$chairNum',
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildRewardSection({
    required int targetCoins,
    required int currentCoins,
    required int rewardPoints,
    required bool isUnlocked,
    required bool isClaimed,
    required VoidCallback onClaim,
  }) {
    final double progress = (currentCoins / targetCoins).clamp(0.0, 1.0);
    final int percent = (progress * 100).toInt();

    return Column(
      children: [
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(isUnlocked ? Colors.greenAccent : Colors.amber),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ሂደት፡ $percent%', style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Text('$currentCoins / $targetCoins ኮይን', style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: ElevatedButton(
            onPressed: (isUnlocked && !isClaimed) ? onClaim : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              disabledBackgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isClaimed
                  ? 'ተወስዷል (Claimed)'
                  : isUnlocked
                      ? 'ስጦታውን ውሰድ (+$rewardPoints Points)'
                      : 'ለመክፈት $targetCoins ኮይን ያስፈልጋል',
              style: TextStyle(
                color: (isUnlocked && !isClaimed) ? Colors.black : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
