import 'package:flutter/material.dart';

class LuckyIslandDialog extends StatefulWidget {
  const LuckyIslandDialog({super.key});

  @override
  State<LuckyIslandDialog> createState() => _LuckyIslandDialogState();
}

class _LuckyIslandDialogState extends State<LuckyIslandDialog> {
  int _selectedBet = 100;
  final List<int> _betOptions = [100, 500, 2000, 5000];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // ጥቁር ሰማያዊ የደሴት ጀርባ
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // 1. መዝጊያ አሞሌ
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // 2. የርዕስ እና የባላንስ ቦታ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.sailing, color: Color(0xFF00C9A7), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "🏝️ Lucky Island",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // የሳንቲም ባላንስ ቦታ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Coins",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. የአሸናፊዎች ማስታወቂያ ባነር (Live Winners Ticker)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign, color: Colors.amber, size: 16),
                SizedBox(width: 6),
                Text(
                  "Recent Big Winner: ID 8888 won 100,000 Coins!",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. የደሴቱ ቦርድ ማስቀመጫ ባዶ ቦታ (Island Map Grid Placeholder)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),

itemCount: 16, // 16ቱ የደሴቱ ሳጥኖች
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, idx) {
                  return Container(
                    decoration: BoxDecoration(
                      color: idx == 0
                          ? const Color(0xFF00C9A7).withOpacity(0.3)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: idx == 0 ? const Color(0xFF00C9A7) : Colors.white10,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            idx == 0
                                ? Icons.flag
                                : (idx % 3 == 0 ? Icons.card_giftcard : Icons.monetization_on),
                            color: idx == 0
                                ? const Color(0xFF00C9A7)
                                : (idx % 3 == 0 ? Colors.pinkAccent : Colors.amber),
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            idx == 0 ? "START" : "Tile $idx",
                            style: const TextStyle(color: Colors.white60, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 5. የመወራረጃ መጠን መምረጫ (Bet Multipliers)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _betOptions.map((amount) {
              final isSel = _selectedBet == amount;
              return GestureDetector(
                onTap: () => setState(() => _selectedBet = amount),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF00C9A7) : Colors.white10,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSel ? Colors.white : Colors.white24,
                    ),
                  ),
                  child: Text(
                    "🪙 $amount",
                    style: TextStyle(
                      color: isSel ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // 6. ዳይስ መወርወሪያ ቁልፍ (Roll Dice Action Button)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino, color: Colors.black, size: 22),

SizedBox(width: 8),
                  Text(
                    "ROLL DICE",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
