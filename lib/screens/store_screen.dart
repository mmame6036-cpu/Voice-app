import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'wallet_screen.dart';

class StoreScreen extends StatefulWidget {
  final int userCoins;
  final int userNumericId;
  final Function(int)? onCoinsDeducted;

  const StoreScreen({
    super.key,
    required this.userCoins,
    this.userNumericId = 0,
    this.onCoinsDeducted,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  int _selectedCategoryIndex = 0;
  late int _coins;
  StreamSubscription? _userSubscription;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color emeraldColor = Color(0xFF00E676);
  static const Color cardBg = Color(0xFF1E1B2E);
  static const Color darkBg = Color(0xFF0F0E17);

  // 4ቱ ዋና ዋና የቦታ ክፍሎች (Categories)
  static const _categories = [
    {"id": "frame", "name": "Avatar Frame", "icon": Icons.account_circle_outlined},
    {"id": "entry", "name": "Entry Effect", "icon": Icons.auto_awesome},
    {"id": "bubble", "name": "Chat Bubble", "icon": Icons.chat_bubble_outline},
    {"id": "badge", "name": "Profile Badge", "icon": Icons.military_tech_outlined},
  ];

  Map<String, dynamic> _ownedItems = {};
  Map<String, dynamic> _equippedItems = {};

  @override
  void initState() {
    super.initState();
    _coins = widget.userCoins;
    _listenToUserData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenToUserData() {
    if (_currentUser == null) return;
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null && mounted) {
        final data = snapshot.data()!;
        setState(() {
          _coins = (data['coins'] as num?)?.toInt() ?? _coins;
          _ownedItems = Map<String, dynamic>.from(data['inventory'] ?? {});
          _equippedItems = Map<String, dynamic>.from(data['equipped'] ?? {});
        });
        widget.onCoinsDeducted?.call(_coins);
      }
    });
  }

  bool _isItemOwned(String itemId) {
    return _ownedItems.containsKey(itemId);
  }

  bool _isItemEquipped(String category, String itemId) {
    return _equippedItems[category] == itemId;
  }

  @override
  Widget build(BuildContext context) {
    final activeCatId = _categories[_selectedCategoryIndex]["id"] as String;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF171524),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Store", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        actions: [
          // Coins Balance Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: goldColor, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: goldColor, size: 16),
                const SizedBox(width: 4),
                Text("$_coins", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),

],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. የክፍል መምረጫ አሞሌ (Category Tabs)
          Container(
            height: 54,
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

          // 2. የእቃዎች መደርደሪያ ቦታዎች (Grid Layout Slots)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('store_items')
                  .where('category', isEqualTo: activeCatId)
                  .snapshots(),
              builder: (context, snapshot) {
                // ዳታቤዝ ላይ እስካሁን ባይጫኑም ባዶ 6 የቦታ ናሙናዎች (Empty Slots) ያሳያል
                final docs = snapshot.data?.docs ?? [];
                final int displayCount = docs.isNotEmpty ? docs.length : 6;

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: displayCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, idx) {
                    final itemData = docs.isNotEmpty ? (docs[idx].data() as Map<String, dynamic>) : null;

                    final String itemId = itemData?['id'] ?? "slot_$idx";
                    final String itemName = itemData?['name'] ?? "Item Slot ${idx + 1}";
                    final String itemIcon = itemData?['icon'] ?? "✨";
                    final int price = (itemData?['price'] as num?)?.toInt() ?? 0;
                    final int days = (itemData?['days'] as num?)?.toInt() ?? 30;

                    final owned = _isItemOwned(itemId);
                    final equipped = _isItemEquipped(activeCatId, itemId);

                    return Container(
                      decoration: BoxDecoration(
                        color: cardBg,

borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: equipped ? emeraldColor : Colors.white12,
                          width: equipped ? 1.8 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // SLOT 1: የእቃው ምስል/አዶ ቦታ
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: darkBg,
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Center(
                              child: Text(itemIcon, style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // SLOT 2: የስም ቦታ
                          Text(
                            itemName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // SLOT 3: የቀን መለያ ቦታ
                          Text(
                            "$days Days",
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(height: 10),

                          // SLOT 4 & 5: የዋጋ እና የመግዣ/ማጥለቂያ ቁልፍ ቦታ
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: owned ? (equipped ? Colors.redAccent : emeraldColor) : goldColor,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () {
                                  // ለጊዜው የቦታው መሞከሪያ
                                },
                                child: Text(
                                  owned
                                      ? (equipped ? "Unequip" : "Equip")
                                      : (price > 0 ? "🪙 $price" : "View"),
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
