import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _roomSounds = true;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color emeraldColor = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171524),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. የመለያ እና ደህንነት ማስተካከያ (Account & Security)
            _buildSectionHeader("Account & Security"),
            _buildSettingsContainer([
              _buildListTile(
                icon: Icons.phone_android,
                iconColor: emeraldColor,
                title: "Bind Phone Number",
                subtitle: "Protect your account",
                trailingText: "Not Linked",
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52, color: Colors.white10),
              _buildListTile(
                icon: Icons.lock_outline,
                iconColor: goldColor,
                title: "Login Password",
                subtitle: "Set account password",
                trailingText: "",
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52, color: Colors.white10),
              _buildListTile(
                icon: Icons.security,
                iconColor: emeraldColor,
                title: "Payment Password",
                subtitle: "Protect coin transactions",
                trailingText: "Set",
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52, color: Colors.white10),
              _buildListTile(
                icon: Icons.block,
                iconColor: Colors.redAccent,
                title: "Blacklist",
                subtitle: "Manage blocked users",
                trailingText: "",
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 20),

            // 2. የማሳወቂያ እና ድምፅ ቅንብሮች (Notifications & Sounds)
            _buildSectionHeader("Notifications & Audio"),
            _buildSettingsContainer([
              SwitchListTile(
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none, color: goldColor, size: 20),
                ),
                title: const Text(
                  "Push Notifications",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  "Messages, room invites and gifts",
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                activeColor: emeraldColor,

value: _pushNotifications,
                onChanged: (val) => setState(() => _pushNotifications = val),
              ),
              const Divider(height: 1, indent: 52, color: Colors.white10),
              SwitchListTile(
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: emeraldColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_up_outlined, color: emeraldColor, size: 20),
                ),
                title: const Text(
                  "Room Sound Effects",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  "In-room gift and game sounds",
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                activeColor: emeraldColor,
                value: _roomSounds,
                onChanged: (val) => setState(() => _roomSounds = val),
              ),
            ]),

            const SizedBox(height: 20),

            // 3. አጠቃላይ የአፑ ሁኔታ (General)
            _buildSectionHeader("General"),
            _buildSettingsContainer([
              _buildListTile(
                icon: Icons.language,
                iconColor: emeraldColor,
                title: "Language",
                subtitle: "App display language",
                trailingText: "English",
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52, color: Colors.white10),
              _buildListTile(
                icon: Icons.cleaning_services_outlined,
                iconColor: goldColor,
                title: "Clear Cache",
                subtitle: "Free up storage space",
                trailingText: "0.0 MB",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cache cleared successfully"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 52, color: Colors.white10),
              _buildListTile(
                icon: Icons.info_outline,
                iconColor: emeraldColor,
                title: "About Us",
                subtitle: "Version info & updates",
                trailingText: "v1.0.0",
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52, color: Colors.white10),
              _buildListTile(
                icon: Icons.description_outlined,
                iconColor: goldColor,
                title: "Privacy Policy & Terms",
                subtitle: "Legal agreements",
                trailingText: "",
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 28),

            // 4. ከመለያ መውጫ (Log Out)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1B2E),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(

backgroundColor: const Color(0xFF1E1B2E),
                      title: const Text("Log Out", style: TextStyle(color: Colors.white)),
                      content: const Text(
                        "Are you sure you want to log out of your account?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Log Out", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  "Log Out",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // አካውንት ማጥፊያ (Delete Account)
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty)
            Text(trailingText, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
        ],
      ),
      onTap: onTap,
    );
  }
}
