import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'wallet_screen.dart';
import 'backpack_screen.dart';

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
  int _selectedCategoryIndex = 3; // Defaults to Special ID matching video
  late int _coins;
  bool _isBusy = false;
  StreamSubscription? _userSubscription;

  static const Color kTealHeader = Color(0xFF00C4B4);
  static const Color kPageBg = Color(0xFFF3F6F8);
  static const Color kCardWhite = Color(0xFFFFFFFF);
  static const Color kSlotTint = Color(0xFFEAF7F6);
  static const Color kTextDark = Color(0xFF1F2937);
  static const Color kTextMuted = Color(0xFF6B7280);
  static const Color kGoldCoin = Color(0xFFF59E0B);
  static const Color kHotRed = Color(0xFFFF5A5F);
  static const Color kPurpleBadgeStart = Color(0xFF7C3AED);
  static const Color kPurpleBadgeEnd = Color(0xFFEC4899);
  static const Color kBlueBadgeStart = Color(0xFF0284C7);
  static const Color kBlueBadgeEnd = Color(0xFF3B82F6);

  static const List<Map<String, dynamic>> _categories = [
    {"id": "popular", "name": "Popular", "icon": Icons.local_fire_department_rounded, "color": Color(0xFFFF5A5F)},
    {"id": "frame", "name": "Frame", "icon": Icons.account_circle_rounded, "color": Color(0xFF10B981)},
    {"id": "entry", "name": "Entry", "icon": Icons.rocket_launch_rounded, "color": Color(0xFFEF4444)},
    {"id": "special_id", "name": "Special ID", "icon": Icons.badge_rounded, "color": Color(0xFFF59E0B)},
    {"id": "theme", "name": "Theme", "icon": Icons.image_rounded, "color": Color(0xFFA855F7)},
    {"id": "room_card", "name": "Room Card", "icon": Icons.assignment_ind_rounded, "color": Color(0xFFD946EF)},
    {"id": "room_frame", "name": "Room Frame", "icon": Icons.palette_rounded, "color": Color(0xFF3B82F6)},
    {"id": "profile_card", "name": "Profile Card", "icon": Icons.checkroom_rounded, "color": Color(0xFF06B6D4)},
  ];

  // Exact Special IDs & prices from 1000015183.mp4 in sequence
  static const List<Map<String, dynamic>> _specialIdCatalog = [
    {"id": "sid_1133", "code": "1133", "price": 800000, "days": 30, "hot": true, "style": "purple"},
    {"id": "sid_1144", "code": "1144", "price": 800000, "days": 30, "hot": true, "style": "purple"},
    {"id": "sid_1166", "code": "1166", "price": 800000, "days": 30, "hot": true, "style": "purple"},
    {"id": "sid_1177", "code": "1177", "price": 800000, "days": 30, "hot": true, "style": "purple"},
    {"id": "sid_1188", "code": "1188", "price": 800000, "days": 30, "hot": true, "style": "purple"},
    {"id": "sid_1149", "code": "1149", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1138", "code": "1138", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1139", "code": "1139", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1140", "code": "1140", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1141", "code": "1141", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1142", "code": "1142", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1143", "code": "1143", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1145", "code": "1145", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1146", "code": "1146", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1147", "code": "1147", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1148", "code": "1148", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1137", "code": "1137", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1150", "code": "1150", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1151", "code": "1151", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1152", "code": "1152", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1153", "code": "1153", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1154", "code": "1154", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1156", "code": "1156", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1157", "code": "1157", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1158", "code": "1158", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1159", "code": "1159", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1160", "code": "1160", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1125", "code": "1125", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1100", "code": "1100", "price": 800000, "days": 30, "hot": true, "style": "purple"},
    {"id": "sid_1126", "code": "1126", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1130", "code": "1130", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1131", "code": "1131", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1132", "code": "1132", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1134", "code": "1134", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1135", "code": "1135", "price": 800000, "days": 30, "hot": false, "style": "blue"},
    {"id": "sid_1136", "code": "1136", "price": 800000, "days": 30, "hot": false, "style": "blue"},
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
    final user = _currentUser;
    if (user == null) return;
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
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

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : kTextDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isItemOwned(String itemId) {
    return _ownedItems.containsKey(itemId);
  }

  bool _isItemEquipped(String category, String itemId) {
    return _equippedItems[category] == itemId;
  }

  Future<void> _handleBuyOrEquip({
    required String categoryId,
    required String itemId,
    required String codeLabel,
    required int price,
    required int days,
  }) async {
    final user = _currentUser;
    if (user == null) {
      _showSnack("Please sign in first.", isError: true);
      return;
    }

    final bool owned = _isItemOwned(itemId);
    final bool equipped = _isItemEquipped(categoryId, itemId);

    if (owned) {
      setState(() => _isBusy = true);
      try {
        final Map<String, dynamic> updates = {
          'equipped.$categoryId': equipped ? "" : itemId,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (categoryId == 'special_id') {
          updates['specialId'] = equipped ? "" : codeLabel;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updates, SetOptions(merge: true));
        _showSnack(equipped
            ? "Unequipped ID $codeLabel"
            : "Equipped ID $codeLabel");
      } catch (e) {
        _showSnack("Failed: $e", isError: true);
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
      return;
    }

    if (_coins < price) {
      _showSnack("Insufficient coins ($price needed). Opening Wallet...",
          isError: true);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletScreen(
            currentCoins: _coins,
            userNumericId: widget.userNumericId,
            userUid: user.uid,
            onCoinsRecharged: (newC) {
              setState(() => _coins = newC);
              widget.onCoinsDeducted?.call(newC);
            },
          ),
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Confirm Purchase",
          style: TextStyle(fontWeight: FontWeight.w800, color: kTextDark),
        ),
        content: Text(
          "Buy Special ID $codeLabel ($days Days) for $price Coins?",
          style: const TextStyle(color: kTextMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kTealHeader,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Buy Now",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final DateTime expiresAt = DateTime.now().add(Duration(days: days));

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final int curCoins = ((snap.data()?['coins']) as num?)?.toInt() ?? 0;
        if (curCoins < price) {
          throw Exception("Insufficient coins");
        }
        tx.set(
          userRef,
          {
            'coins': FieldValue.increment(-price),
            'wealthExp': FieldValue.increment(price),
            'inventory': {
              itemId: {
                'id': itemId,
                'name': codeLabel,
                'category': categoryId,
                'days': days,
                'expiresAt': Timestamp.fromDate(expiresAt),
              }
            },
            'equipped': {
              categoryId: itemId,
            },
            if (categoryId == 'special_id') 'specialId': codeLabel,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      _showSnack("Purchased & equipped Special ID $codeLabel!");
    } catch (e) {
      _showSnack("Purchase failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String activeCatId =
        _categories[_selectedCategoryIndex]["id"] as String;
    final String uid = _currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: kTealHeader,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Store",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.backpack_rounded,
                color: Colors.white, size: 22),
            tooltip: "Backpack",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackpackScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Top Category Grid (4x2 matching video)
              Container(
                color: kCardWhite,
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final bool isSel = _selectedCategoryIndex == idx;
                    final Color iconCol = cat["color"] as Color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategoryIndex = idx),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSel
                              ? kTealHeader.withOpacity(0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat["icon"] as IconData,
                              color: iconCol,
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat["name"] as String,
                              style: TextStyle(
                                color: isSel ? kTealHeader : kTextDark,
                                fontSize: 11.5,
                                fontWeight:
                                    isSel ? FontWeight.w800 : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isSel)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 18,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: kTealHeader,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Items Grid
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('store_items')
                      .where('category', isEqualTo: activeCatId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final List<Map<String, dynamic>> items = [];
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      for (final doc in snapshot.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        items.add({
                          "id": (d['id'] ?? doc.id).toString(),
                          "code": (d['code'] ?? d['name'] ?? doc.id)
                              .toString(),
                          "price": (d['price'] as num?)?.toInt() ?? 800000,
                          "days": (d['days'] as num?)?.toInt() ?? 30,
                          "hot": d['hot'] == true,
                          "style":
                              (d['style'] ?? (d['hot'] == true ? 'purple' : 'blue'))
                                  .toString(),
                        });
                      }
                    } else if (activeCatId == "special_id" ||
                        activeCatId == "popular") {
                      for (final entry in _specialIdCatalog) {
                        items.add(Map<String, dynamic>.from(entry));
                      }
                    } else {
                      for (int i = 0; i < 6; i++) {
                        final codeNum = "${1100 + i}";
                        items.add({
                          "id": "${activeCatId}_$codeNum",
                          "code": codeNum,
                          "price": 800000,
                          "days": 30,
                          "hot": i < 2,
                          "style": i < 2 ? "purple" : "blue",
                        });
                      }
                    }

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      itemBuilder: (context, idx) {
                        final item = items[idx];
                        final String itemId = item["id"].toString();
                        final String code = item["code"].toString();
                        final int price = (item["price"] as num).toInt();
                        final int days = (item["days"] as num).toInt();
                        final bool isHot = item["hot"] == true;
                        final bool isPurple = item["style"] == "purple";

                        final bool owned = _isItemOwned(itemId);
                        final bool equipped =
                            _isItemEquipped(activeCatId, itemId);

                        return GestureDetector(
                          onTap: () => _handleBuyOrEquip(
                            categoryId: activeCatId,
                            itemId: itemId,
                            codeLabel: code,
                            price: price,
                            days: days,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: kCardWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: equipped
                                    ? kTealHeader
                                    : Colors.black.withOpacity(0.05),
                                width: equipped ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        height: 92,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: kSlotTint,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isPurple
                                                    ? const [
                                                        kPurpleBadgeStart,
                                                        kPurpleBadgeEnd,
                                                      ]
                                                    : const [
                                                        kBlueBadgeStart,
                                                        kBlueBadgeEnd,
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isPurple
                                                          ? kPurpleBadgeStart
                                                          : kBlueBadgeStart)
                                                      .withOpacity(0.35),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons.diamond_rounded,
                                                    color: Color(0xFFFEF08A),
                                                    size: 16),
                                                const SizedBox(width: 5),
                                                Text(
                                                  code,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15,
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                code,
                                                style: const TextStyle(
                                                  color: kTextDark,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              if (owned)
                                                Text(
                                                  equipped
                                                      ? "Equipped"
                                                      : "Owned",
                                                  style: const TextStyle(
                                                    color: kTealHeader,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.monetization_on_rounded,
                                                  color: kGoldCoin,
                                                  size: 15),
                                              const SizedBox(width: 4),
                                              Text(
                                                "$price",
                                                style: const TextStyle(
                                                  color: kGoldCoin,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isHot)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: const BoxDecoration(
                                        color: kHotRed,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(14),
                                          bottomRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        "HOT",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isBusy && uid.isNotEmpty)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: kTealHeader),
              ),
            ),
        ],
      ),
    );
  }
}
