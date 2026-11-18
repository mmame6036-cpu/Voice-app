import 'package:flutter/material.dart';

// --- STORE SCREEN ---
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
        content: Text(
          "Cost: 🪙$price for ${item['days']}.\nIt will be added to your Backpack.",
          style: const TextStyle(color: Colors.white70),
        ),
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

// --- BACKPACK SCREEN ---
class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> {
  int _selectedIdx = 0;
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
                        _selectedIdx = idx;
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

// --- HOST CENTER SCREEN ---
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
          // Settlement Card
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
