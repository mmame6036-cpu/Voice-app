import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  int _selectedCategoryIndex = 0;
  late int _coins;
  bool _isPurchasing = false;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color emeraldColor = Color(0xFF00E676);
  static const Color darkBg = Color(0xFF0F0E17);
  static const Color cardBg = Color(0xFF1E1B2E);

  final List> _categories = const [
    {"name": "Avatar Frame", "type": "frame", "icon": Icons.account_circle_outlined},
    {"name": "Entry Effect", "type": "ride", "icon": Icons.auto_awesome},
    {"name": "Chat Bubble", "type": "bubble", "icon": Icons.chat_bubble_outline},
    {"name": "Profile Card", "type": "card", "icon": Icons.badge_outlined},
  ];

  final List> _allItems = const [
    {"id": "frame_dragon", "type": "frame", "name": "Gold Dragon", "icon": "🐉", "price": 1000, "days": 30},
    {"id": "frame_crown", "type": "frame", "name": "Neon Crown", "icon": "👑", "price": 800, "days": 30},
    {"id": "ride_wings", "type": "ride", "name": "Cyber Wings", "icon": "🪽", "price": 1500, "days": 30},
    {"id": "ride_supercar", "type": "ride", "name": "Supercar Red", "icon": "🏎️", "price": 3000, "days": 30},
    {"id": "ride_pegasus", "type": "ride", "name": "Golden Pegasus", "icon": "🦄", "price": 5000, "days": 30},
    {"id": "ride_yacht", "type": "ride", "name": "Cyber Yacht", "icon": "🛥️", "price": 4000, "days": 30},
    {"id": "bubble_fire", "type": "bubble", "name": "Flame Bubble", "icon": "🔥", "price": 1200, "days": 30},
    {"id": "bubble_gold", "type": "bubble", "name": "Royal Gold", "icon": "✨", "price": 1800, "days": 30},
    {"id": "card_nile", "type": "card", "name": "NILE Knight", "icon": "🛡️", "price": 2500, "days": 30},
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.userCoins;
  }

  List> get _filteredItems {
    final selectedType = _categories[_selectedCategoryIndex]["type"] as String;
    return _allItems.where((item) => item["type"] == selectedType).toList();
  }

  Future<void> _handlePurchase(Map<String, dynamic> item) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to make a purchase.")),
      );
      return;
    }

    final int price = item["price"] as int;
    final String itemId = item["id"] as String;
    final String itemName = item["name"] as String;
    final int validityDays = item["days"] as int;

    if (_coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins to purchase!")),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final backpackRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('backpack')
          .doc(itemId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final currentCoins = (userDoc.data() as Map<String, dynamic>)['coins'] ?? 0;

        if (currentCoins < price) {
          throw Exception("Insufficient coins.");
        }

        final now = DateTime.now();
        final expirationDate = now.add(Duration(days: validityDays));

        transaction.update(userRef, {'coins': FieldValue.increment(-price)});

transaction.set(backpackRef, {
          'itemId': itemId,
          'name': itemName,
          'type': item['type'],
          'icon': item['icon'],
          'isEquipped': false,
          'purchasedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expirationDate),
        });
      });

      setState(() => _coins -= price);
      widget.onCoinsDeducted?.call(_coins);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully purchased $itemName!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Purchase failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  void _showConfirmDialog(Map<String, dynamic> item) {
    final int price = item["price"] as int;
    final int days = item["days"] as int;
    final String name = item["name"] as String;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Buy $name?",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Cost: $price Coins for $days Days validity.",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: _isPurchasing ? null : () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isPurchasing ? null : () => _handlePurchase(item),
              child: _isPurchasing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text("Confirm", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF171524),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "VIP Mall & Store",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: uid.isNotEmpty
                ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
                : null,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                _coins = data['coins'] ?? _coins;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [

const Icon(Icons.monetization_on, color: goldColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "$_coins",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 56,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? emeraldColor.withOpacity(0.2) : cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? emeraldColor : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(cat["icon"] as IconData, color: isSelected ? emeraldColor : Colors.white54, size: 16),
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
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      "No items available in this category yet.",
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredItems.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, idx) {
                      final itm = _filteredItems[idx];
                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(itm["icon"] as String, style: const TextStyle(fontSize: 44)),
                            const SizedBox(height: 8),
                            Text(

itm["name"] as String,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${itm['days']} Days",
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: goldColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => _showConfirmDialog(itm),
                              child: Text(
                                "🪙 ${itm['price']}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
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
