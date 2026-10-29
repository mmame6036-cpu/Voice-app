import 'package:flutter/material.dart';

class StoreScreen extends StatefulWidget {
  final int userCoins;
  final Function(int)? onCoinsDeducted;

  const StoreScreen({
    super.key,
    required this.userCoins,
    this.onCoinsDeducted,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _selectedCategoryIndex = 0;
  late int _coins;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color emeraldColor = Color(0xFF00E676);

  // ትክክለኛው የዳታ አይነት (Type) እዚህ ተስተካክሏል
  final List> _categories = [
    {"name": "Avatar Frame", "icon": Icons.account_circle_outlined, "color": Colors.amber},
    {"name": "Entry Effect", "icon": Icons.auto_awesome, "color": Colors.purpleAccent},
    {"name": "Chat Bubble", "icon": Icons.chat_bubble_outline, "color": Colors.blueAccent},
    {"name": "Profile Card", "icon": Icons.badge_outlined, "color": Colors.teal},
  ];

  final List> _items = [
    {"name": "Gold Dragon", "icon": "🐉", "price": 1000, "days": "30 Days"},
    {"name": "Neon Crown", "icon": "👑", "price": 800, "days": "30 Days"},
    {"name": "Cyber Wings", "icon": "🪽", "price": 1500, "days": "30 Days"},
    {"name": "Supercar Red", "icon": "🏎️", "price": 3000, "days": "30 Days"},
    {"name": "Golden Pegasus", "icon": "🦄", "price": 5000, "days": "30 Days"},
    {"name": "Cyber Yacht", "icon": "🛥️", "price": 4000, "days": "30 Days"},
  ];

  @override
  void initState() {
    super.initState();
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
        backgroundColor: const Color(0xFF1E1B2E),
        title: Text("Buy ${item['name']}?", style: const TextStyle(color: Colors.white)),
        content: Text("Cost: 🪙$price for ${item['days']}.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: goldColor),
            onPressed: () {
              setState(() => _coins -= price);
              widget.onCoinsDeducted?.call(_coins);
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
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171524),
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
                const Icon(Icons.monetization_on, color: goldColor, size: 18),
                const SizedBox(width: 4),
                Text("$_coins", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // የምድብ ዝርዝር መምረጫ
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? emeraldColor.withOpacity(0.2) : const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? emeraldColor : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(cat["icon"] as IconData, color: isSelected ? emeraldColor : Colors.white54, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          cat["name"] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // የዕቃዎች ዝርዝር (Grid)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, idx) {
                final itm = _items[idx];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(itm["icon"] as String, style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        itm["name"] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        itm["days"] as String,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
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
            ),
          ),
        ],
      ),
    );
  }
}
