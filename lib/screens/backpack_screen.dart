import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  static const Color emeraldColor = Color(0xFF00E676);
  static const Color darkBg = Color(0xFF0F0E17);
  static const Color cardBg = Color(0xFF1E1B2E);

  final List<String> _categories = ["Frames", "Rides", "Bubbles", "Badges"];
  final List<String> _categoryKeys = ["frame", "entry", "bubble", "badge"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: darkBg,
        body: Center(child: Text("Please sign in", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF171524),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Backpack",
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: emeraldColor,
          labelColor: emeraldColor,
          unselectedLabelColor: Colors.white54,
          indicatorWeight: 2.5,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final inventory = Map<String, dynamic>.from(data['inventory'] ?? {});
          final equipped = Map<String, dynamic>.from(data['equipped'] ?? {});

          return TabBarView(
            controller: _tabController,
            children: _categoryKeys.map((key) {
              return _buildCategoryGrid(categoryKey: key, inventory: inventory, equipped: equipped);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid({
    required String categoryKey,
    required Map<String, dynamic> inventory,
    required Map<String, dynamic> equipped,
  }) {
    // ተጠቃሚው በዚህ ዘርፍ ስር የገዛቸው እቃዎች መለያዎች
    final userItems = inventory.entries
        .where((e) => (e.value is Map && e.value['category'] == categoryKey))
        .toList();

    // እስካሁን ምንም ያልገዛ ከሆነ ንጹህ ባዶ የቦታ ናሙናዎችን (Slots) ያሳያል
    final int displayCount = userItems.isNotEmpty ? userItems.length : 6;

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: displayCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, idx) {
        final hasItem = userItems.isNotEmpty && idx < userItems.length;
        final itemId = hasItem ? userItems[idx].key : "slot_$idx";
        final itemData = hasItem ? (userItems[idx].value as Map<String, dynamic>) : null;

        final isEquipped = equipped[categoryKey] == itemId;
        final iconDisplay = itemData?['icon'] ?? "🎒";
        final nameDisplay = itemData?['name'] ?? "Slot ${idx + 1}";

return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEquipped ? emeraldColor : Colors.white12,
              width: isEquipped ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SLOT 1: የምስል/አዶ ቦታ
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(color: Colors.white10),
                ),
                child: Center(
                  child: Text(iconDisplay, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 8),

              // SLOT 2: የስም ቦታ
              Text(
                nameDisplay,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // SLOT 3: የሁኔታ መለያ (Active / Stored)
              Text(
                isEquipped ? "In Use" : (hasItem ? "Owned" : "Empty Slot"),
                style: TextStyle(
                  color: isEquipped ? emeraldColor : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              // SLOT 4: የማጥለቂያ/የማውለቂያ ቁልፍ ቦታ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEquipped ? Colors.redAccent.withOpacity(0.8) : (hasItem ? emeraldColor : Colors.white12),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: hasItem
                        ? () {
                            final targetEquip = isEquipped ? null : itemId;
                            FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
                              'equipped.$categoryKey': targetEquip,
                            });
                          }
                        : null,
                    child: Text(
                      isEquipped ? "Unequip" : (hasItem ? "Equip" : "Slot"),
                      style: TextStyle(
                        color: hasItem ? Colors.black : Colors.white24,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
