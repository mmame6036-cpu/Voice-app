import 'package:flutter/material.dart';
import 'chairs_management_screen.dart';

class RoomChairsGrid extends StatelessWidget {
  final int userCoinsSpent;
  final Function(int chairIndex)? onChairTap;

  const RoomChairsGrid({
    Key? key,
    this.userCoinsSpent = 0,
    this.onChairTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // የወንበሮቹ መክፈቻ ሁኔታ
    final bool isTier2Unlocked = userCoinsSpent >= 200000;
    final bool isTier3Unlocked = userCoinsSpent >= 400000;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131722).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Live Stage (30 Chairs)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '1-10 Free | 11-20 VIP | 21-30 Premium',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 30ው ወንበሮች
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // በአንድ መስመር 5 ወንበር
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final int chairNum = index + 1;
              bool isUnlocked = true;
              Color tierColor = Colors.tealAccent;

              // ደረጃ 1፦ 1 - 10 (ክፍት)
              if (chairNum <= 10) {
                isUnlocked = true;
                tierColor = Colors.tealAccent;
              }
              // ደረጃ 2፦ 11 - 20 (VIP)
              else if (chairNum <= 20) {
                isUnlocked = isTier2Unlocked;
                tierColor = Colors.amber;
              }
              // ደረጃ 3፦ 21 - 30 (Premium)
              else {
                isUnlocked = isTier3Unlocked;
                tierColor = const Color(0xFFD946EF);
              }

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (isUnlocked) {
                    if (onChairTap != null) onChairTap!(chairNum);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Joined Chair #$chairNum'),
                        backgroundColor: Colors.teal,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chair #$chairNum is locked!'),
                        backgroundColor: Colors.redAccent,
                        action: SnackBarAction(
                          label: 'Upgrade',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChairsManagementScreen(

userCoins: userCoinsSpent,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? tierColor.withOpacity(0.12)
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUnlocked
                          ? tierColor.withOpacity(0.6)
                          : Colors.white12,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUnlocked ? Icons.chair : Icons.lock_outline,
                        size: 22,
                        color: isUnlocked ? tierColor : Colors.white24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$chairNum',
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white24,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
