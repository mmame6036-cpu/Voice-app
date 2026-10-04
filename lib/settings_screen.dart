import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: const Text('ማስተካከያ (Settings)', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1F2E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _buildSectionTitle('አካውንት እና ደህንነት'),
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'የአካውንት አስተዳደር',
            onTap: () => _showComingSoon(context, 'የአካውንት አስተዳደር'),
          ),
          _buildSettingsItem(
            icon: Icons.language,
            title: 'ቋንቋ (Language)',
            subtitle: 'አማርኛ',
            onTap: () => _showComingSoon(context, 'ቋንቋ መምረጫ'),
          ),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: 'ግላዊነት (Privacy)',
            onTap: () => _showComingSoon(context, 'የካሜራ እና ማይክሮፎን ፈቃዶች'),
          ),
          _buildSettingsItem(
            icon: Icons.block,
            title: 'የታገዱ ተጠቃሚዎች (Blocklist)',
            onTap: () => _showComingSoon(context, 'ማንም አልታገደም'),
          ),
          
          const SizedBox(height: 10),
          Divider(color: Colors.grey[850], thickness: 1),
          const SizedBox(height: 10),
          
          _buildSectionTitle('አጠቃላይ መረጃ'),
          _buildSettingsItem(
            icon: Icons.cleaning_services_outlined,
            title: 'ካሼ ማጽጃ (Clear cache)',
            trailingText: '12.4 MB',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ካሼ ጸድቷል!')),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'ስለ አፕሊኬሽኑ (About)',
            onTap: () => _showComingSoon(context, 'ስለ እኛ'),
          ),
          
          const SizedBox(height: 20),
          
          // መውጫ (Sign out)
          ListTile(
            title: const Center(
              child: Text(
                'ውጣ (Sign out)',
                style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () {
              // ወደ መግቢያ ገጽ ለመመለስ
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  // የርዕስ መጻፊያ ንድፍ
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  // የእያንዳንዱ ዝርዝር ንድፍ
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) 
            Text(trailingText, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          if (trailingText != null) const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }

  // ገና ላልተሰሩ ገጾች ማሳወቂያ
  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title በቅርቡ ይጨመራል!')),
    );
  }
}
