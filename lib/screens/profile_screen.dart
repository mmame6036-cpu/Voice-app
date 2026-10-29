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
  String _userName = "User Name";
  late String _userId;
  late int _coins;
  double _points = 0.00;

  int _wealthLevel = 0;
  int _charmLevel = 0;
  int _hostLevel = 0;
  bool _isAgency = false;

  int _followed = 0;
  int _following = 0;
  int _friends = 0;

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
            child: Text(_isAgency ? "Open Dashboard" : "Join Agency", style: const TextStyle(color: Colors.white)),
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

  void _openStore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreScreen(
          userCoins: _coins,
          onCoinsDeducted: (newCoins) {
            setState(() => _coins = newCoins);
            widget.onCoinsUpdated(newCoins);
          },
        ),
      ),
    );
  }

  void _openBackpack() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackpackScreen()),
    );
  }

  void _openHostCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HostCenterScreen(currentPoints: _points)),
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
            _buildHeader(),
            const SizedBox(height: 14),
            _buildSocialCounters(),
            const SizedBox(height: 14),
            _buildVipClubBanner(),
            const SizedBox(height: 14),
            _buildBalanceBar(),
            const SizedBox(height: 16),
            _buildFirstGrid(),
            const SizedBox(height: 16),
            _buildPromoBanner(),
            const SizedBox(height: 16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
                GestureDetector(
                  onTap: _copyId,
                  child: Row(
                    children: [
                      Text("ID: $_userId", style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
        gradient: const LinearGradient(colors: [Color(0xFF2C241D), Color(0xFF1B1611)]),
      ),
      child: Row(
        children: [
          const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("VIP Club", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Upgrade to VIP and get free coins daily", style: TextStyle(color: Colors.white70, fontSize: 11)),
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
            onPressed: () => _showFeatureDetail("VIP Club", "VIP tiers provide exclusive entrance banners and bonuses."),
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
                      Text("$_coins", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF00C9A7)),
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
      {"icon": "🏪", "name": "Store", "action": _openStore},
      {"icon": "💌", "name": "Invitation", "action": () => _showFeatureDetail("Invitation", "Invite friends to get coins.")},
      {"icon": "🎒", "name": "Backpack", "action": _openBackpack},
      {"icon": "🏝️", "name": "Lucky Island", "action": () => _showFeatureDetail("Lucky Island", "Mini games & lucky draw.")},
      {"icon": "⭐", "name": "Level", "action": () => _showFeatureDetail("Level", "Your wealth, charm, and broadcaster levels.")},
      {"icon": "📋", "name": "Task", "action": () => _showFeatureDetail("Task", "Complete missions for coin rewards.")},
      {"icon": "🏅", "name": "Badge", "action": () => _showFeatureDetail("Badge", "Honorary achievement badges.")},
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
                Text(item["name"] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
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
        gradient: const LinearGradient(colors: [Color(0xFFFF3366), Color(0xFFFF5E36)]),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("COIN RECHARGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              Text("Up to 60% OFF on first USDT top-up", style: TextStyle(color: Colors.white70, fontSize: 11)),
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
      {"icon": "🎙️", "name": "Host Center", "action": _openHostCenter},
      {"icon": "💼", "name": "Agency", "action": _openAgencyDialog},
      {"icon": "💵", "name": "Coin Seller", "action": () => _showFeatureDetail("Coin Seller", "Official distributor portal.")},

{"icon": "🎧", "name": "Support", "action": () => _showFeatureDetail("Support", "24/7 Live support center.")},
      {"icon": "ℹ️", "name": "About", "action": () => _showFeatureDetail("About", "Voice App Version 1.0.0.")},
      {"icon": "⚙️", "name": "Setting", "action": () => _showFeatureDetail("Setting", "Account privacy & security.")},
      {"icon": "🌐", "name": "Network Line", "action": () => _showFeatureDetail("Network", "Server Line 1 (Ping: 42ms).")},
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
                Text(item["name"] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== SUB-SCREENS IN THE SAME FILE ====================

class StoreScreen extends StatefulWidget {
  final int userCoins;
  final Function(int) onCoinsDeducted;

  const StoreScreen({
    super.key,
    required this.userCoins,
    required this.onCoinsDeducted,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _coins;

  final List<Map<String, dynamic>> _frames = [
    {"name": "Gold Dragon", "icon": "🐉", "price": 1000, "days": "30 Days"},
    {"name": "Neon Crown", "icon": "👑", "price": 800, "days": "30 Days"},
    {"name": "Cyber Wings", "icon": "🪽", "price": 1500, "days": "30 Days"},
    {"name": "Rose Romance", "icon": "🌹", "price": 500, "days": "7 Days"},
  ];

  final List<Map<String, dynamic>> _mounts = [
    {"name": "Supercar Red", "icon": "🏎️", "price": 3000, "days": "30 Days"},
    {"name": "Golden Pegasus", "icon": "🦄", "price": 5000, "days": "30 Days"},
    {"name": "Cyber Yacht", "icon": "🛥️", "price": 4000, "days": "30 Days"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _coins = widget.userCoins;
  }

  void _buyItem(Map<String, dynamic> item) {
    final price = item["price"] as int;
    if (_coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins to purchase!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        title: Text("Buy ${item['name']}?", style: const TextStyle(color: Colors.white)),
        content: Text("Cost: 🪙$price for ${item['days']}.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),

),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () {
              setState(() => _coins -= price);
              widget.onCoinsDeducted(_coins);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Successfully bought ${item['name']}!")),
              );
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141226),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B38),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("VIP Mall & Store", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 4),
                Text("$_coins", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          tabs: const [
            Tab(text: "Avatar Frames"),
            Tab(text: "Entry Mounts"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemGrid(_frames),
          _buildItemGrid(_mounts),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, idx) {
        final itm = items[idx];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(itm["icon"], style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(itm["name"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(itm["days"], style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _buyItem(itm),
                child: Text("🪙 ${itm['price']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> {
  final List<Map<String, dynamic>> _myItems = [
    {"name": "Standard Mic Ring", "icon": "🎙️", "active": true},
    {"name": "VIP Badge Frame", "icon": "👑", "active": false},
    {"name": "Rocket Car Entry", "icon": "🏎️", "active": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141226),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B38),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Backpack", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Equipped & Stored Items", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _myItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, idx) {
                  final itm = _myItems[idx];
                  final isEquipped = itm["active"] as bool;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        for (var el in _myItems) {
                          el["active"] = false;
                        }
                        itm["active"] = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Equipped ${itm['name']}!")),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B38),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isEquipped ? const Color(0xFFFFD700) : Colors.white12,
                          width: isEquipped ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(itm["icon"], style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 6),
                          Text(
                            itm["name"],
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isEquipped ? const Color(0xFFFFD700) : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isEquipped ? "In Use" : "Equip",
                              style: TextStyle(
                                color: isEquipped ? Colors.black : Colors.white70,

fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HostCenterScreen extends StatelessWidget {
  final double currentPoints;

  const HostCenterScreen({super.key, required this.currentPoints});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Host Center", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF008B74)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Earnings (Points)", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  "💎 ${currentPoints.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Broadcast Duration: 0h 00m", style: TextStyle(color: Colors.white, fontSize: 12)),
                    Text("Valid Days: 0 / 22", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Monthly Targets & Policies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _policyTile("Level 1 Host", "10,000 Points Target", "Commission: 20%"),
          _policyTile("Level 2 Host", "50,000 Points Target", "Commission: 25%"),
          _policyTile("Level 3 Host", "150,000 Points Target", "Commission: 30%"),
          _policyTile("VIP Star Host", "500,000 Points Target", "Commission: 35%"),
        ],
      ),
    );
  }

  Widget _policyTile(String level, String target, String comm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(level, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(target, style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ],
          ),
          Text(comm, style: const TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
