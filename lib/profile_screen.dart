import 'package:flutter/material.dart';
import 'settings_screen.dart';

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
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // የፕሮፋይል ምስል እና ስም
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
          const SizedBox(height: 30),

          // ሪቻርጅ (Recharge)
          _buildMenuItem(
            icon: Icons.account_balance_wallet,
            iconColor: Colors.orangeAccent,
            title: 'ሪቻርጅ (Recharge)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('የሪቻርጅ ገጽ በቅርቡ ይከፈታል')));
            },
          ),
          const SizedBox(height: 12),

          // ኮይን ሻጭ (Coin Seller)
          _buildMenuItem(
            icon: Icons.storefront,
            iconColor: Colors.blueAccent,
            title: 'ኮይን ሻጭ (Coin Seller)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('የኮይን ሻጭ ገጽ በቅርቡ ይከፈታል')));
            },
          ),
          const SizedBox(height: 12),

          // ሲቲንግ (Settings)
          _buildMenuItem(
            icon: Icons.settings,
            iconColor: Colors.grey,
            title: 'ማስተካከያ (Settings)',
            onTap: () {
              // ወደሰራነው የሲቲንግ ገጽ ይወስደናል
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
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
