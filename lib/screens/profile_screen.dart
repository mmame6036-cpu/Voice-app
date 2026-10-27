import 'package:flutter/material.dart';

class MeProfileScreen extends StatelessWidget {
  final int coins;

  const MeProfileScreen({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // የፕሮፋይል ፎቶ እና ስም
            const CircleAvatar(
              radius: 46,
              backgroundColor: Color(0xFFFFD700),
              child: Icon(Icons.person, size: 54, color: Colors.black),
            ),
            const SizedBox(height: 12),
            const Text(
              "Kedir Umer",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("ID: 9845210", style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Color(0xFFFFD700)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ID ተቀድቷል")),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // የኮይኖች፣ ሌቭል እና ፎሎወሮች ካርድ
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B38),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol("Coins", "$coins 🪙"),
                  _statCol("Level", "Lv. 15"),
                  _statCol("Followers", "340"),
                  _statCol("Following", "128"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // አገልግሎቶች እና ዝርዝሮች (Wallet, Bag, Settings)
            _profileMenuItem(
              icon: Icons.account_balance_wallet,
              title: "My Wallet (ኮይን መሙያ)",
              trailingText: "$coins Coins",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Wallet section opening...")),
                );
              },
            ),
            _profileMenuItem(
              icon: Icons.backpack,
              title: "Backpack (የስጦታ ቦርሳ)",
              trailingText: "12 Items",
              onTap: () {},
            ),
            _profileMenuItem(
              icon: Icons.military_tech,
              title: "VIP Privileges",
              trailingText: "VIP 1",
              onTap: () {},
            ),
            _profileMenuItem(
              icon: Icons.settings,
              title: "Settings (ቅንብሮች)",
              trailingText: "",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String title, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _profileMenuItem({
    required IconData icon,

required String title,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF23233E),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 22),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText.isNotEmpty)
              Text(trailingText, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
