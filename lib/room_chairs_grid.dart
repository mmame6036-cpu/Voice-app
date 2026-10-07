import 'package:flutter/material.dart';
import 'chairs_management_screen.dart';
import 'main.dart';

// የተቀመጡ ሰዎችን መረጃ የሚይዝ
Map<int, String> occupiedChairs = {};

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

              isUnlocked = true; // ሁሉም 30 ወንበሮች ክፍት እንዲሆኑ
              if (chairNum <= 10) {
                tierColor = Colors.tealAccent;
              } else if (chairNum <= 20) {
                tierColor = Colors.amber;
              } else {
                tierColor = const Color(0xFFD946EF);
              }

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
  if (isUnlocked) {
    occupiedChairs[chairNum] = AppData.currentUserName;
    if (onChairTap != null) onChairTap!(chairNum);
    (context as Element).markNeedsBuild();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined Chair #$chairNum as ${AppData.currentUserName}'),
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
              ? tierColor.withOpacity(occupiedChairs.containsKey(chairNum) ? 0.35 : 0.12)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: occupiedChairs.containsKey(chairNum)
                ? Colors.greenAccent
                : (isUnlocked ? tierColor.withOpacity(0.4) : Colors.white10),
            width: occupiedChairs.containsKey(chairNum) ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (occupiedChairs.containsKey(chairNum)) ...[
              // ሰው ሲቀመጥ የሚታይ ፕሮፋይል እና ስም
              const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                occupiedChairs[chairNum] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              // ወንበሩ ክፍት ሲሆን የሚታየው የወንበር አይኮን
              Icon(
                isUnlocked ? Icons.weekend : Icons.lock,
                size: 20,
                color: isUnlocked ? tierColor : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                '$chairNum',
                style: TextStyle(
                  color: isUnlocked ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
