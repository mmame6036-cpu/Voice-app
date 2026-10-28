import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int currentCoins;
  final int currentDiamonds;
  final Function(int) onCoinsUpdated;

  const ProfileScreen({
    super.key,
    required this.currentCoins,
    this.currentDiamonds = 120,
    required this.onCoinsUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _coins;
  late int _diamonds;
  final String userId = "1753925";
  final String userName = "Kedir VIP";

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _diamonds = widget.currentDiamonds;
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User ID copied to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Golden Gradient Profile Header
            _buildProfileHeader(),

            // Golden Wallet Banner
            _buildWalletBanner(),

            const SizedBox(height: 12),

            // VIP & Wealth Level Cards
            _buildVipAndWealthCards(),

            const SizedBox(height: 16),

            // Golden Icons Grid (Medal of Honor, Family, Shop, CP Nest, etc.)
            _buildGoldenToolsGrid(),

            const SizedBox(height: 16),

            // General Settings List
            _buildSettingsList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF201B3A), Color(0xFF131024)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Golden Avatar Frame
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          Color(0xFFFFDF7A),
                          Color(0xFFD49E35),
                          Color(0xFFFFF1BD),
                          Color(0xFFFFDF7A),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 34,
                    backgroundImage: NetworkImage(
                      "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop",
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(

userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "VIP 6",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _copyId,
                      child: Row(
                        children: [
                          Text(
                            "ID: $userId",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy, size: 14, color: Color(0xFFFFD700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("14", "Following"),
              _verticalDivider(),
              _statItem("1.2K", "Followers"),
              _verticalDivider(),
              _statItem("38", "Friends"),
              _verticalDivider(),
              _statItem("342", "Visitors"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Color(0xFFFFDF7A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white12,
    );
  }

  Widget _buildWalletBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFF9DC76), Color(0xFFD49E35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD49E35).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF996B1F),
                ),
                child: const Text("🪙", style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Wallet Balance",
                    style: TextStyle(
                      color: Color(0xFF53380B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$_coins Coins",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1B38),
              foregroundColor: const Color(0xFFFFDF7A),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalletScreen(
                    currentCoins: _coins,
                    onCoinsRecharged: (newCoins) {
                      setState(() => _coins = newCoins);
                      widget.onCoinsUpdated(newCoins);
                    },
                  ),
                ),
              );
            },
            child: const Text("Recharge", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVipAndWealthCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // VIP Card
          Expanded(
            child: Container(
              height: 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D2345), Color(0xFF1B152B)],
                ),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "VIP Privilege",
                          style: TextStyle(
                            color: Color(0xFFFFDF7A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Active (Level 6)",
                          style: TextStyle(color: Colors.white70, fontSize: 11),

),
                      ],
                    ),
                  ),
                  const Text("👑", style: TextStyle(fontSize: 32)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Wealth Level Card
          Expanded(
            child: Container(
              height: 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3E3D), Color(0xFF092525)],
                ),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Wealth level",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "LV. 17",
                          style: TextStyle(
                            color: Color(0xFFFFDF7A),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text("💎", style: TextStyle(fontSize: 32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenToolsGrid() {
    final List<Map<String, dynamic>> tools = [
      {"icon": "🏅", "label": "Medal of\nHonor"},
      {"icon": "🏰", "label": "Family"},
      {"icon": "🛍️", "label": "Shop"},
      {"icon": "💚", "label": "CP Nest"},
      {"icon": "📜", "label": "Data Center"},
      {"icon": "🎁", "label": "Task center"},
      {"icon": "🎒", "label": "Backpack"},
      {"icon": "👑", "label": "Aristocracy"},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tools.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final item = tools[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFF4D0), Color(0xFFFFDE8A)],
                  ),
                  border: Border.all(color: const Color(0xFFD49E35), width: 1.5),
                  boxShadow: [

BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    item["icon"] as String,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item["label"] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _settingsTile(Icons.headset_mic_outlined, "Customer Service & Help"),
          const Divider(height: 1, indent: 50),
          _settingsTile(Icons.security_outlined, "Account & Security"),
          const Divider(height: 1, indent: 50),
          _settingsTile(Icons.language_outlined, "Language Setting"),
          const Divider(height: 1, indent: 50),
          _settingsTile(Icons.info_outline, "About Habesha VIP"),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD49E35), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
      onTap: () {},
    );
  }
}
