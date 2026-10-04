import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'recharge_screen.dart';
import 'coin_seller_screen.dart';
import 'host_center_screen.dart';
import 'agency_screen.dart';
import 'store_screen.dart';
import 'invite_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: const Text('የኔ ፕሮፋይል (Profile)', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1F2E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // የፕሮፋይል ራስጌ
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'ID: $userId',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // 1. ሆስት ሴንተር (Host Center)
          _buildMenuItem(
            icon: Icons.mic_external_on,
            iconColor: Colors.purpleAccent,
            title: 'ሆስት ሴንተር (Host Center)',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HostCenterScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 2. ሪቻርጅ (Recharge)
          _buildMenuItem(
            icon: Icons.account_balance_wallet,
            iconColor: Colors.orangeAccent,
            title: 'ኮይን ሪቻርጅ (Recharge)',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RechargeScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 3. ኮይን ሻጭ (Coin Seller)
          _buildMenuItem(
            icon: Icons.storefront,
            iconColor: Colors.greenAccent,
            title: 'ኮይን ሻጭ (Coin Seller)',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CoinSellerScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 4. ኤጀንሲ (Agency)
          _buildMenuItem(
            icon: Icons.business,
            iconColor: Colors.blueAccent,
            title: 'ኤጀንሲ ማዕከል (Agency)',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AgencyScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 5. ስቶር / ሱቅ (Store)
          _buildMenuItem(
            icon: Icons.shopping_bag,
            iconColor: Colors.amberAccent,
            title: 'የእቃዎች ሱቅ (Store)',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 6. ጋብዝ (Invite Friends)
          _buildMenuItem(
            icon: Icons.person_add_alt_1,
            iconColor: Colors.tealAccent,
            title: 'ጓደኞችን ጋብዝ (Invite)',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 7. ሲቲንግ (Settings)
          _buildMenuItem(

icon: Icons.settings,
            iconColor: Colors.grey,
            title: 'ማስተካከያ (Settings)',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      tileColor: const Color(0xFF222436),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
      onTap: onTap,
    );
  }
}
