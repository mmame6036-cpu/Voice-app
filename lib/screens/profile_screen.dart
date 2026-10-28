import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int currentCoins;
  final Function(int) onCoinsUpdated;

  const ProfileScreen({
    super.key,
    required this.currentCoins,
    required this.onCoinsUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Dynamic User State (Can be edited by user)
  String _userName = "User Name";
  late String _userId;
  late int _coins;
  double _points = 23946.56;

  // Levels & Badges
  int _wealthLevel = 17;
  int _charmLevel = 14;
  int _hostLevel = 1;
  bool _isAgency = true;

  // Social Stats
  int _followed = 3117;
  int _following = 519;
  int _friends = 103;

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _userId = "${Random().nextInt(899999) + 1000000}";
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: _userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ID Copied to clipboard")),
    );
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: "Nickname",
            hintText: "Enter your nickname",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7)),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() => _userName = nameCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAgencyDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.business_center, color: Color(0xFF00C9A7)),
            SizedBox(width: 8),
            Text("Agency Portal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isAgency ? "You are currently an Agency Manager." : "Become an Agency Partner",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              _isAgency
                  ? "Manage your agency hosts, track daily targets, and view settlement commissions."
                  : "Enter your Agency Referral Code or Invitation ID to upgrade your account role.",
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            if (!_isAgency) ...[
              const SizedBox(height: 14),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: "Agency Invitation Code",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),

),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAgency ? Colors.blueAccent : const Color(0xFF00C9A7),
            ),
            onPressed: () {
              if (!_isAgency && codeCtrl.text.trim().isNotEmpty) {
                setState(() => _isAgency = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Upgraded to Agency Successfully!")),
                );
              } else if (_isAgency) {
                _showFeatureDetail("Agency Dashboard", "Agency Host list, earnings and analytics active.");
              }
              Navigator.pop(ctx);
            },
            child: Text(_isAgency ? "Open Agency Dashboard" : "Join Agency", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFeatureDetail(String title, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7)),
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecharge() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Header: Profile, Name, ID, Badges
            _buildHeader(),

            const SizedBox(height: 14),

            // Social Counters (Followed, Following, Friends)
            _buildSocialCounters(),

            const SizedBox(height: 14),

            // VIP Club Banner
            _buildVipClubBanner(),

            const SizedBox(height: 14),

            // Coins & Points Bar
            _buildBalanceBar(),

            const SizedBox(height: 16),

            // 8 Main Action Icons (Recharge, Store, Invitation, Backpack, Lucky Island, Level, Task, Badge)
            _buildFirstGrid(),

            const SizedBox(height: 16),

            // Promo Banner
            _buildPromoBanner(),

            const SizedBox(height: 16),

            // Second Grid (Host Center, Agency, Coin Seller, Support, About, Setting, Network Line)
            _buildSecondGrid(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(

padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          GestureDetector(
            onTap: _editProfileDialog,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
                image: const DecorationImage(
                  image: NetworkImage(
                    "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // User Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16, color: Colors.black45),
                      onPressed: _editProfileDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Badges Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _levelBadge("💎 $_wealthLevel", Colors.teal),
                    _levelBadge("💖 $_charmLevel", Colors.pinkAccent),
                    _levelBadge("🎙️ $_hostLevel", Colors.purpleAccent),
                    if (_isAgency)
                      GestureDetector(
                        onTap: _openAgencyDialog,
                        child: _levelBadge("💼 AGENCY", Colors.lightBlue),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // ID Row
                GestureDetector(
                  onTap: _copyId,
                  child: Row(
                    children: [
                      Text(
                        "ID: $_userId",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 13, color: Colors.black38),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: Color(0xFF00C9A7), size: 26),
            onPressed: () => _showFeatureDetail("Voice Status", "Microphone is connected and active."),
          ),
        ],
      ),
    );
  }

  Widget _levelBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSocialCounters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statColumn("$_followed", "Followed"),
        _divider(),
        _statColumn("$_following", "Following"),
        _divider(),
        _statColumn("$_friends", "Friends"),
      ],
    );
  }

Widget _statColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 20, color: Colors.black12);
  }

  Widget _buildVipClubBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C241D), Color(0xFF1B1611)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "VIP Club",
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Upgrade to VIP and get free coins daily",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD49E35),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            onPressed: () => _showFeatureDetail(
              "VIP Club",
              "VIP tiers give exclusive entry effects, luxury frames, and daily coin gifts.",
            ),
            child: const Text("Get VIP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Coins
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  const Text("🪙", style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Coins", style: TextStyle(color: Colors.black54, fontSize: 11)),
                      Text(
                        "$_coins",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Points
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),

boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  const Text("💎", style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Points", style: TextStyle(color: Colors.black54, fontSize: 11)),
                      Text(
                        "$_points",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF00C9A7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstGrid() {
    final items = [
      {"icon": "💳", "name": "Recharge", "action": _openRecharge},
      {"icon": "🏪", "name": "Store", "action": () => _showFeatureDetail("Store", "Purchase luxury avatar frames, mounts, and speech bubbles.")},
      {"icon": "💌", "name": "Invitation", "action": () => _showFeatureDetail("Invitation", "Invite friends to get referral bonus coins.")},
      {"icon": "🎒", "name": "Backpack", "action": () => _showFeatureDetail("Backpack", "Your active avatar items and inventory.")},
      {"icon": "🏝️", "name": "Lucky Island", "action": () => _showFeatureDetail("Lucky Island", "Mini games, lucky draw, and treasure hunt.")},
      {"icon": "⭐", "name": "Level", "action": () => _showFeatureDetail("Level", "Your wealth, charm, and broadcaster levels.")},
      {"icon": "📋", "name": "Task", "action": () => _showFeatureDetail("Task", "Complete daily active missions for coin rewards.")},
      {"icon": "🏅", "name": "Badge", "action": () => _showFeatureDetail("Badge", "Honorary badges from events and achievements.")},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: item["action"] as VoidCallback,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item["icon"] as String, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  item["name"] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3366), Color(0xFFFF5E36)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "COIN RECHARGE",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                "Up to 60% OFF on first USDT top-up",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _openRecharge,
            child: const Text("Top Up", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondGrid() {
    final items = [
      {"icon": "🎙️", "name": "Host Center", "action": () => _showFeatureDetail("Host Center", "Broadcast duration, target diamond settlements, and stats.")},
      {"icon": "💼", "name": "Agency", "action": _openAgencyDialog},
      {"icon": "💵", "name": "Coin Seller", "action": () => _showFeatureDetail("Coin Seller", "Official reseller portal and distributor coins.")},
      {"icon": "🎧", "name": "Support", "action": () => _showFeatureDetail("Customer Support", "24/7 Live support and ticket center.")},
      {"icon": "ℹ️", "name": "About", "action": () => _showFeatureDetail("About Us", "Voice App Version 1.0.0 (Global Edition).")},
      {"icon": "⚙️", "name": "Setting", "action": () => _showFeatureDetail("Settings", "Account privacy, notifications, and security.")},
      {"icon": "🌐", "name": "Network Line", "action": () => _showFeatureDetail("Network Line", "Current line: High Speed Server 1 (Ping: 42ms).")},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: item["action"] as VoidCallback,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item["icon"] as String, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  item["name"] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
