import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum GiftCategory { hot, lucky, luxury, intimacy }

class GiftItem {
  final String id;
  final String name;
  final String icon;
  final int price;
  final String imageAsset;
  final GiftCategory category;

  const GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.imageAsset,
    required this.category,
  });

  double get diamondRate => category == GiftCategory.lucky ? 0.04 : 0.70;
  bool get isLucky => category == GiftCategory.lucky;
}

class GiftSendResult {
  final GiftItem gift;
  final List<int> targetSeatIndices;
  final bool isAll;
  final int multiplier;
  final int totalCost;
  final int wonCoins;
  final int rawGiftCostPerSeat; // Full gift value for seat display (100% value)

  GiftSendResult({
    required this.gift,
    required this.targetSeatIndices,
    required this.isAll,
    required this.multiplier,
    required this.totalCost,
    this.wonCoins = 0,
    required this.rawGiftCostPerSeat,
  });
}

class GiftDialog extends StatefulWidget {
  final String roomId;
  final dynamic activeUsers;
  final int userCoins;
  final Function(int newCoins)? onCoinsUpdated;

  const GiftDialog({
    super.key,
    required this.roomId,
    required this.activeUsers,
    required this.userCoins,
    this.onCoinsUpdated,
  });

  @override
  State<GiftDialog> createState() => _GiftDialogState();
}

class _GiftDialogState extends State<GiftDialog>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final Random _random = Random();
  late TabController _tabController;

  late int _coins;
  bool _isSending = false;

  final Set<int> _selectedSeatIndices = {};
  bool _isAllSelected = false;
  int _selectedMultiplier = 1;
  final List<int> _multipliers = [1, 3, 7, 10, 30, 50, 77, 100];

  int _selectedGiftIndex = 0;
  int _comboCount = 0;
  Timer? _comboTimer;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkBg = Color(0xFF130F26);
  static const Color cardBg = Color(0xFF1E1738);

  final List<GiftCategory> _categories = [
    GiftCategory.hot,
    GiftCategory.lucky,
    GiftCategory.luxury,
    GiftCategory.intimacy,
  ];

  final List<GiftItem> _allGifts = const [
    // Hot (70% diamond)
    GiftItem(
      id: "flowers",
      name: "Fragrant Flowers",
      icon: "🌸",
      price: 100,
      imageAsset: "assets/images/wikimediaimages-candy-2201920.jpg",
      category: GiftCategory.hot,
    ),
    GiftItem(
      id: "icecream",
      name: "Ice Cream",
      icon: "🍦",
      price: 200,
      imageAsset: "assets/images/weekly_lovers_heart_value.webp",
      category: GiftCategory.hot,
    ),
    GiftItem(
      id: "perfume",
      name: "Perfume Bottle",
      icon: "🧴",
      price: 300,
      imageAsset: "assets/images/charm_07.webp",
      category: GiftCategory.hot,
    ),

    // Lucky (4% diamond + sender gamble explosion)
    GiftItem(
      id: "lucky_dice",
      name: "Lucky Dice",
      icon: "🎲",
      price: 10,
      imageAsset: "assets/images/wikimediaimages-candy-2201920.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "lucky_box",
      name: "Lucky Box",
      icon: "🎁",
      price: 100,
      imageAsset: "assets/images/weekly_lovers_heart_value.webp",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "lucky_wheel",
      name: "Lucky Wheel",
      icon: "🎡",
      price: 1000,
      imageAsset: "assets/images/charm_07.webp",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "lucky_island",
      name: "Lucky Island",
      icon: "🏝️",
      price: 10000,
      imageAsset: "assets/images/wealth_03.webp",
      category: GiftCategory.lucky,
    ),

// Luxury (70% diamond)
    GiftItem(
      id: "sportscar",
      name: "Pink Sports Car",
      icon: "🏎️",
      price: 500,
      imageAsset: "assets/images/wealth_03.webp",
      category: GiftCategory.luxury,
    ),
    GiftItem(
      id: "castle",
      name: "Magic Castle",
      icon: "🏰",
      price: 2500,
      imageAsset: "assets/images/charm_07.webp",
      category: GiftCategory.luxury,
    ),
    GiftItem(
      id: "rocket",
      name: "Super Rocket",
      icon: "🚀",
      price: 5000,
      imageAsset: "assets/images/wealth_03.webp",
      category: GiftCategory.luxury,
    ),

    // Intimacy (70% diamond)
    GiftItem(
      id: "crystal_blue_rose",
      name: "Crystal Rose",
      icon: "🌹",
      price: 999,
      imageAsset: "assets/images/wikimediaimages-candy-2201920.jpg",
      category: GiftCategory.intimacy,
    ),
    GiftItem(
      id: "diamond",
      name: "Royal Diamond",
      icon: "💎",
      price: 1500,
      imageAsset: "assets/images/weekly_lovers_heart_value.webp",
      category: GiftCategory.intimacy,
    ),
  ];

  List<GiftItem> get _currentCategoryGifts {
    final currentCat = _categories[_tabController.index];
    return _allGifts.where((g) => g.category == currentCat).toList();
  }

  List get _userList {
    if (widget.activeUsers is List) {
      return widget.activeUsers as List;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _coins = widget.userCoins;
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedGiftIndex = 0;
          _comboCount = 0;
        });
      }
    });

    if (_userList.isNotEmpty) {
      final firstUser = _userList.first;
      final sIdx = firstUser['seatIndex'] as int?;
      if (sIdx != null) {
        _selectedSeatIndices.add(sIdx);
      }
    }
  }

  @override
  void dispose() {
    _comboTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedSeatIndices.clear();
        _isAllSelected = false;
      } else {
        _selectedSeatIndices.clear();
        for (final user in _userList) {
          final sIdx = user['seatIndex'] as int?;
          if (sIdx != null) {
            _selectedSeatIndices.add(sIdx);
          }
        }
        _isAllSelected = true;
      }
    });
  }

  void _toggleSeat(int seatIndex) {
    setState(() {
      if (_selectedSeatIndices.contains(seatIndex)) {
        _selectedSeatIndices.remove(seatIndex);
        _isAllSelected = false;
      } else {
        _selectedSeatIndices.add(seatIndex);
        if (_selectedSeatIndices.length == _userList.length && _userList.isNotEmpty) {
          _isAllSelected = true;
        }
      }
    });
  }

  int get _calculateTotalPrice {
    final currentGifts = _currentCategoryGifts;
    if (_selectedSeatIndices.isEmpty || currentGifts.isEmpty) return 0;
    if (_selectedGiftIndex >= currentGifts.length) return 0;
    final unitPrice = currentGifts[_selectedGiftIndex].price;
    return unitPrice * _selectedMultiplier * _selectedSeatIndices.length;
  }

  int _calculateLuckyMultiplier() {
    int roll = _random.nextInt(1000) + 1;
    if (roll <= 2) return 500;
    if (roll <= 10) return 100;
    if (roll <= 30) return 50;
    if (roll <= 90) return 10;
    if (roll <= 210) return 5;
    return 0;
  }

  Future<void> _sendGift() async {
    if (_currentUser == null) return;
    if (_selectedSeatIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a seat or tap 'All'")),
      );
      return;
    }

    final currentGifts = _currentCategoryGifts;
    if (_selectedGiftIndex >= currentGifts.length) return;
    final selectedGift = currentGifts[_selectedGiftIndex];

final totalCost = _calculateTotalPrice;
    if (_coins < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins balance!")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      int wonCoins = 0;
      int maxMultiplier = 0;

      if (selectedGift.isLucky) {
        int totalUnits = _selectedMultiplier * _selectedSeatIndices.length;
        for (int i = 0; i < totalUnits; i++) {
          int mult = _calculateLuckyMultiplier();
          if (mult > 0) {
            maxMultiplier = max(maxMultiplier, mult);
            wonCoins += selectedGift.price * mult;
          }
        }
      }

      final senderRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      final netDeduction = -totalCost + wonCoins;
      senderRef.set({
        'coins': FieldValue.increment(netDeduction),
      }, SetOptions(merge: true)).catchError((_) {});

      // Point calculation: 4% for lucky, 70% for standard
      final double hostRate = selectedGift.diamondRate;
      final int diamondsPerRecipient = (selectedGift.price * _selectedMultiplier * hostRate).round();

      for (final sIndex in _selectedSeatIndices) {
        final occupant = _userList.firstWhere(
          (u) => u['seatIndex'] == sIndex,
          orElse: () => null,
        );
        if (occupant != null) {
          final uid = occupant['uid']?.toString() ?? "";
          if (uid.isNotEmpty) {
            FirebaseFirestore.instance.collection('users').doc(uid).set({
              'diamonds': FieldValue.increment(diamondsPerRecipient),
            }, SetOptions(merge: true)).catchError((_) {});
          }
        }
      }

      roomRef.collection('events').add({
        'type': 'gift',
        'senderId': _currentUser!.uid,
        'giftId': selectedGift.id,
        'giftName': selectedGift.name,
        'giftIcon': selectedGift.icon,
        'imageAsset': selectedGift.imageAsset,
        'multiplier': _selectedMultiplier,
        'seats': _selectedSeatIndices.toList(),
        'totalCost': totalCost,
        'isLucky': selectedGift.isLucky,
        'wonCoins': wonCoins,
        'luckyMultiplier': maxMultiplier,
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      final updatedBalance = _coins + netDeduction;
      setState(() => _coins = updatedBalance);
      widget.onCoinsUpdated?.call(_coins);

      _comboTimer?.cancel();
      setState(() => _comboCount++);
      _comboTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _comboCount = 0);
        }
      });

      if (wonCoins > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: goldColor,
            content: Text(
              "BOOM! Lucky x$maxMultiplier! Won +$wonCoins Coins!",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      // 100% full gift value goes to seat display
      final int fullSeatCost = selectedGift.price * _selectedMultiplier;

      if (mounted) {
        Navigator.pop(
          context,
          GiftSendResult(
            gift: selectedGift,
            targetSeatIndices: _selectedSeatIndices.toList(),
            isAll: _isAllSelected,
            multiplier: _selectedMultiplier,
            totalCost: totalCost,
            wonCoins: wonCoins,
            rawGiftCostPerSeat: fullSeatCost,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

String _getCategoryName(GiftCategory cat) {
    switch (cat) {
      case GiftCategory.hot:
        return "Hot";
      case GiftCategory.lucky:
        return "Lucky";
      case GiftCategory.luxury:
        return "Luxury";
      case GiftCategory.intimacy:
        return "Intimacy";
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = _calculateTotalPrice;
    final currentGifts = _currentCategoryGifts;
    final selectedGift = currentGifts.isNotEmpty && _selectedGiftIndex < currentGifts.length
        ? currentGifts[_selectedGiftIndex]
        : null;

    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Seat selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleSelectAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isAllSelected ? goldColor : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isAllSelected ? goldColor : Colors.white24),
                    ),
                    child: Text(
                      "All",
                      style: TextStyle(
                        color: _isAllSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 30,
                      itemBuilder: (context, index) {
                        final seatIdx = index;
                        final seatNum = seatIdx + 1;
                        final occupant = _userList.firstWhere(
                          (u) => u['seatIndex'] == seatIdx,
                          orElse: () => null,
                        );

                        final isOccupied = occupant != null;
                        final isSelected = _selectedSeatIndices.contains(seatIdx);

                        return GestureDetector(
                          onTap: isOccupied ? () => _toggleSeat(seatIdx) : null,
                          child: Container(
                            width: 32,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? goldColor.withOpacity(0.25)
                                  : (isOccupied ? cardBg : Colors.white.withOpacity(0.04)),
                              border: Border.all(
                                color: isSelected
                                    ? goldColor
                                    : (isOccupied ? Colors.white24 : Colors.transparent),
                                width: isSelected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Center(
                              child: Text(

"$seatNum",
                                style: TextStyle(
                                  color: isSelected
                                      ? goldColor
                                      : (isOccupied ? Colors.white : Colors.white24),
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Categories Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: goldColor,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: _categories.map((c) => Tab(text: _getCategoryName(c))).toList(),
          ),

          // Gifts Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: currentGifts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final gift = currentGifts[index];
                final isSelected = _selectedGiftIndex == index;

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedGiftIndex = index;
                    _comboCount = 0;
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? goldColor.withOpacity(0.16) : cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? goldColor : Colors.transparent,
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            gift.imageAsset,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) =>
                                Text(gift.icon, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gift.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "🪙 ${gift.price}",
                          style: const TextStyle(color: goldColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

// Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: goldColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "$_coins",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                if (selectedGift != null)
                  Text(
                    "💎 ${(selectedGift.
