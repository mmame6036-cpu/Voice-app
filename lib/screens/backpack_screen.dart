import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  static const Color primaryTeal = Color(0xFF00C9A7);

  final List> _categories = [
    {"label": "Frame", "key": "frame"},
    {"label": "Entry", "key": "entry"},
    {"label": "Theme", "key": "bubble"},
    {"label": "Special ID", "key": "special_id"},
    {"label": "Props", "key": "badge"},
  ];

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

  Future<void> _toggleEquipItem({
    required String categoryKey,
    required String itemId,
    required bool isCurrentlyEquipped,
  }) async {
    if (_currentUser == null) return;

    final DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

    try {
      if (isCurrentlyEquipped) {
        // Unequip item
        await userRef.update({
          'equipped.$categoryKey': FieldValue.delete(),
        });
      } else {
        // Equip item
        await userRef.update({
          'equipped.$categoryKey': itemId,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Action failed: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  int _calculateRemainingDays(dynamic expiresAt) {
    if (expiresAt == null) return 30;
    if (expiresAt is Timestamp) {
      final difference = expiresAt.toDate().difference(DateTime.now()).inDays;
      return difference > 0 ? difference : 0;
    }
    return 30;
  }

  IconData _getCategoryDefaultIcon(String categoryKey) {
    switch (categoryKey) {
      case "frame":
        return Icons.account_circle_outlined;
      case "entry":
        return Icons.auto_awesome;
      case "bubble":
        return Icons.chat_bubble_outline;
      case "special_id":
        return Icons.badge_outlined;
      case "badge":
        return Icons.military_tech_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: Text(
            "Please sign in to access Backpack",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Backpack",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryTeal,
          unselectedLabelColor: Colors.black45,
          indicatorColor: primaryTeal,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),

tabs: _categories.map((cat) => Tab(text: cat["label"])).toList(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final userData = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final Map<String, dynamic> inventory =
              Map<String, dynamic>.from(userData['inventory'] ?? {});
          final Map<String, dynamic> equipped =
              Map<String, dynamic>.from(userData['equipped'] ?? {});

          return TabBarView(
            controller: _tabController,
            children: _categories.map((cat) {
              final String categoryKey = cat["key"]!;
              final String categoryLabel = cat["label"]!;

              // Filter items belonging to current category
              final List<MapEntry<String, dynamic>> items = inventory.entries
                  .where((entry) =>
                      entry.value is Map &&
                      entry.value['category'] == categoryKey)
                  .toList();

              if (items.isEmpty) {
                return _buildEmptyState(categoryLabel);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final String itemId = items[index].key;
                  final Map<String, dynamic> itemData =
                      Map<String, dynamic>.from(items[index].value as Map);

                  final String name = itemData['name'] ?? "$categoryLabel Item";
                  final int daysRemaining =
                      _calculateRemainingDays(itemData['expiresAt']);
                  final bool isEquipped = equipped[categoryKey] == itemId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isEquipped ? primaryTeal : Colors.black12,
                        width: isEquipped ? 1.6 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: itemData['icon'] != null &&
                                    itemData['icon'].toString().length <= 2
                                ? Text(
                                    itemData['icon'].toString(),
                                    style: const TextStyle(fontSize: 26),
                                  )
                                : Icon(
                                    _getCategoryDefaultIcon(categoryKey),
                                    color: primaryTeal,
                                    size: 28,

),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: Color(0xFF1D2129),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      size: 13, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Validity: $daysRemaining Days",
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _toggleEquipItem(
                            categoryKey: categoryKey,
                            itemId: itemId,
                            isCurrentlyEquipped: isEquipped,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isEquipped
                                  ? Colors.redAccent.withOpacity(0.9)
                                  : primaryTeal,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isEquipped ? "Unequip" : "Wear",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String categoryName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.backpack_outlined,
            size: 64,
            color: Colors.black.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            "No $categoryName items available",
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
