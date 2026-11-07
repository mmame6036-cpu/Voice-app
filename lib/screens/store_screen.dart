import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreItem {
  final String id;
  final String name;
  final String icon;
  final String category;
  final int price;
  final int days;
  final Color effectColor;

  const StoreItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.price,
    required this.days,
    required this.effectColor,
  });
}

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

  static const Color goldColor = Color(0xFFFFD700);
  static const Color emeraldColor = Color(0xFF00E676);
  static const Color cardBg = Color(0xFF1E1B2E);
  static const Color darkBg = Color(0xFF0F0E17);

  static const _categories = const [
    {"id": "frame", "name": "Avatar Frame", "icon": Icons.account_circle_outlined},
    {"id": "entry", "name": "Entry Effect", "icon": Icons.auto_awesome},
    {"id": "bubble", "name": "Chat Bubble", "icon": Icons.chat_bubble_outline},
    {"id": "badge", "name": "Profile Badge", "icon": Icons.military_tech_outlined},
  ];

  final List<StoreItem> _allStoreItems = const [
    // Frames
    StoreItem(id: "frame_dragon", name: "Gold Dragon", icon: "🐉", category: "frame", price: 1000, days: 30, effectColor: Color(0xFFFFD700)),
    StoreItem(id: "frame_crown", name: "Neon Crown", icon: "👑", category: "frame", price: 800, days: 30, effectColor: Color(0xFF00E5FF)),
    StoreItem(id: "frame_wings", name: "Cyber Wings", icon: "🪽", category: "frame", price: 1500, days: 30, effectColor: Color(0xFFE040FB)),
    StoreItem(id: "frame_fire", name: "Flame Aura", icon: "🔥", category: "frame", price: 1200, days: 30, effectColor: Color(0xFFFF5722)),

    // Entry Effects
    StoreItem(id: "entry_car", name: "Supercar Red", icon: "🏎️", category: "entry", price: 3000, days: 30, effectColor: Color(0xFFFF1744)),
    StoreItem(id: "entry_pegasus", name: "Golden Pegasus", icon: "🦄", category: "entry", price: 5000, days: 30, effectColor: Color(0xFFFFD700)),
    StoreItem(id: "entry_yacht", name: "Cyber Yacht", icon: "🛥️", category: "entry", price: 4000, days: 30, effectColor: Color(0xFF00E5FF)),
    StoreItem(id: "entry_rocket", name: "Falcon Rocket", icon: "🚀", category: "entry", price: 6000, days: 30, effectColor: Color(0xFFFF9100)),

    // Chat Bubbles
    StoreItem(id: "bubble_gold", name: "Imperial Gold", icon: "💬", category: "bubble", price: 600, days: 30, effectColor: Color(0xFFFFD700)),
    StoreItem(id: "bubble_neon", name: "Cyber Neon", icon: "🗨️", category: "bubble", price: 750, days: 30, effectColor: Color(0xFF00E676)),
    StoreItem(id: "bubble_pink", name: "Sweet Sakura", icon: "🌸", category: "bubble", price: 500, days: 30, effectColor: Color(0xFFFF4081)),

    // Profile Badges
    StoreItem(id: "badge_diamond", name: "Blue Diamond", icon: "💎", category: "badge", price: 2000, days: 30, effectColor: Color(0xFF00B0FF)),
    StoreItem(id: "badge_star", name: "Galaxy Star", icon: "⭐", category: "badge", price: 1800, days: 30, effectColor: Color(0xFFFFD700)),
    StoreItem(id: "badge_shield", name: "VIP Sentinel", icon: "🛡️", category: "badge", price: 2500, days: 30, effectColor: Color(0xFF7C4DFF)),
  ];

  Map<String, dynamic> _ownedItems = {};
  Map<String, dynamic> _equippedItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _coins = widget.userCoins;
    _fetchUserInventory();
  }

  Future<void> _fetchUserInventory() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _coins = (data['coins'] as num?)?.toInt() ?? _coins;
          _ownedItems = Map<String, dynamic>.from(data['inventory'] ?? {});
          _equippedItems = Map<String, dynamic>.from(data['equipped'] ?? {});
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List get _filteredItems {
    final activeCatId = _categories[_selectedCategoryIndex]["id"];
    return _allStoreItems.where((item) => item.category == activeCatId).toList();
  }

  bool _isItemOwned(String itemId) {
    if (!_ownedItems.containsKey(itemId)) return false;
    final expiresAt = (_ownedItems[itemId] as Timestamp?)?.toDate();
    if (expiresAt == null) return false;
    return expiresAt.isAfter(DateTime.now());
  }

  bool _isItemEquipped(String category, String itemId) {
    return _equippedItems[category] == itemId;
  }

  Future<void> _toggleEquip(StoreItem item) async {
    if (_currentUser == null) return;
    final cat = item.category;
    final currentlyEquipped = _equippedItems[cat] == item.id;
    final newId = currentlyEquipped ? null : item.id;

    setState(() {
      if (newId == null) {
        _equippedItems.remove(cat);
      } else {
        _equippedItems[cat] = newId;
      }
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'equipped': {
          cat: newId,
        }
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlyEquipped ? "Unequipped ${item.name}" : "Equipped ${item.name}!"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _buyItem(StoreItem item) async {
    if (_coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins to purchase!")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Expanded(child: Text("Buy ${item.name}", style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Validity: ${item.days} Days", style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text("Price: 🪙 ${item.price} Coins", style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final expirationDate = DateTime.now().add(Duration(days: item.days));

    setState(() {
      _coins -= item.price;
      _ownedItems[item.id] = Timestamp.fromDate(expirationDate);
      _equippedItems[item.category] = item.id;
    });

widget.onCoinsDeducted?.call(_coins);

    if (_currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
          'coins': FieldValue.increment(-item.price),
          'inventory': {
            item.id: Timestamp.fromDate(expirationDate),
          },
          'equipped': {
            item.category: item.id,
          }
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unlocked and Equipped ${item.name} for ${item.days} days!")),
      );
    }
  }

  void _showItemPreview(StoreItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final owned = _isItemOwned(item.id);
        final equipped = _isItemEquipped(item.category, item.id);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: darkBg,
                  border: Border.all(color: item.effectColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: item.effectColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 12),
              Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text("${item.days} Days VIP Access • ${item.category.toUpperCase()}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: owned
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: equipped ? Colors.redAccent : emeraldColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _toggleEquip(item);
                        },
                        child: Text(
                          equipped ? "Unequip" : "Wear / Equip",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _buyItem(item);
                        },
                        child: Text(
                          "Buy for 🪙 ${item.price}",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF171524),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("VIP Mall & Store", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: goldColor, size: 20),
                const SizedBox(width: 4),
                Text("$_coins", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldColor))
          : Column(
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
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredItems.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.80,
                    ),
                    itemBuilder: (context, idx) {
                      final itm = _filteredItems[idx];
                      final owned = _isItemOwned(itm.id);
                      final equipped = _isItemEquipped(itm.category, itm.id);

return GestureDetector(
                        onTap: () => _showItemPreview(itm),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: equipped ? emeraldColor : (owned ? goldColor.withOpacity(0.4) : Colors.white12),
                              width: equipped ? 1.8 : 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: darkBg,
                                      boxShadow: [
                                        BoxShadow(
                                          color: itm.effectColor.withOpacity(0.25),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(itm.icon, style: const TextStyle(fontSize: 34)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    itm.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "${itm.days} Days",
                                    style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 32,
                                      child: owned
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: equipped ? Colors.redAccent : emeraldColor,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                              onPressed: () => _toggleEquip(itm),
                                              child: Text(
                                                equipped ? "In Use" : "Equip",
                                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            )
                                          : ElevatedButton(

style: ElevatedButton.styleFrom(
                                                backgroundColor: goldColor,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                              onPressed: () => _buyItem(itm),
                                              child: Text(
                                                "🪙 ${itm.price}",
                                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              if (equipped)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: emeraldColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text("EQUIPPED", style: TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.bold)),
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
    );
  }
}
