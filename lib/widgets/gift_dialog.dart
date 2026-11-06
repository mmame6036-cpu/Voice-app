import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GiftItem {
  final String id;
  final String name;
  final String icon;
  final int price;
  final String imageAsset;

  const GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.imageAsset,
  });
}

class GiftSendResult {
  final GiftItem gift;
  final List<int> targetSeatIndices;
  final bool isAll;
  final int multiplier;
  final int totalCost;

  GiftSendResult({
    required this.gift,
    required this.targetSeatIndices,
    required this.isAll,
    required this.multiplier,
    required this.totalCost,
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

class _GiftDialogState extends State<GiftDialog> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late int _coins;
  bool _isSending = false;

  final Set<int> _selectedSeatIndices = {};
  bool _isAllSelected = false;
  int _selectedMultiplier = 1;
  final List<int> _multipliers = [1, 3, 7, 10, 30, 50, 77, 100];

  int _selectedGiftIndex = 0;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkBg = Color(0xFF140F2D);
  static const Color cardBg = Color(0xFF221A45);

  final List<GiftItem> _gifts = const [
    GiftItem(
      id: "flowers",
      name: "Fragrant Flowers",
      icon: "🌸",
      price: 100,
      imageAsset: "assets/images/wikimediaimages-candy-2201920.jpg",
    ),
    GiftItem(
      id: "icecream",
      name: "Ice Cream",
      icon: "🍦",
      price: 200,
      imageAsset: "assets/images/weekly_lovers_heart_value.webp",
    ),
    GiftItem(
      id: "perfume",
      name: "Perfume Bottle",
      icon: "🧴",
      price: 300,
      imageAsset: "assets/images/charm_07.webp",
    ),
    GiftItem(
      id: "sportscar",
      name: "Pink Sports Car",
      icon: "🏎️",
      price: 500,
      imageAsset: "assets/images/wealth_03.webp",
    ),
    GiftItem(
      id: "lollipop",
      name: "Lollipop",
      icon: "🍭",
      price: 10,
      imageAsset: "assets/images/wikimediaimages-candy-2201920.jpg",
    ),
    GiftItem(
      id: "diamond",
      name: "Diamond Ring",
      icon: "💎",
      price: 1000,
      imageAsset: "assets/images/weekly_lovers_heart_value.webp",
    ),
    GiftItem(
      id: "castle",
      name: "Magic Castle",
      icon: "🏰",
      price: 2500,
      imageAsset: "assets/images/charm_07.webp",
    ),
    GiftItem(
      id: "rocket",
      name: "Super Rocket",
      icon: "🚀",
      price: 5000,
      imageAsset: "assets/images/wealth_03.webp",
    ),
  ];

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
    if (_userList.isNotEmpty) {
      final firstUser = _userList.first;
      final sIdx = firstUser['seatIndex'] as int?;
      if (sIdx != null) {
        _selectedSeatIndices.add(sIdx);
      }
    }
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
    if (_selectedSeatIndices.isEmpty) return 0;
    final unitPrice = _gifts[_selectedGiftIndex].price;
    return unitPrice * _selectedMultiplier * _selectedSeatIndices.length;
  }

  Future<void> _sendGift() async {
    if (_currentUser == null) return;
    if (_selectedSeatIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a seat or tap 'All'")),
      );
      return;
    }

    final totalCost = _calculateTotalPrice;
    if (_coins < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins balance!")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final selectedGift = _gifts[_selectedGiftIndex];
      final senderRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      // Deduct coins from sender safely
      senderRef.set({
        'coins': FieldValue.increment(-totalCost),
      }, SetOptions(merge: true)).catchError((_) {});

      // Add diamonds to occupants in background
      final pointsPerRecipient = selectedGift.price * _selectedMultiplier;
      for (final sIndex in _selectedSeatIndices) {
        final occupant = _userList.firstWhere(
          (u) => u['seatIndex'] == sIndex,
          orElse: () => null,
        );
        if (occupant != null) {
          final uid = occupant['uid']?.toString() ?? "";
          if (uid.isNotEmpty) {
            FirebaseFirestore.instance.collection('users').doc(uid).set({
              'diamonds': FieldValue.increment(pointsPerRecipient),
            }, SetOptions(merge: true)).catchError((_) {});
          }
        }
      }

      // Log room event in background
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
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      setState(() => _coins -= totalCost);
      widget.onCoinsUpdated?.call(_coins);

      if (mounted) {
        Navigator.pop(
          context,
          GiftSendResult(
            gift: selectedGift,
            targetSeatIndices: _selectedSeatIndices.toList(),
            isAll: _isAllSelected,
            multiplier: _selectedMultiplier,
            totalCost: totalCost,
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

  @override
  Widget build(BuildContext context) {
    final totalCost = _calculateTotalPrice;

    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Top seated users & All selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _userList.isEmpty
                      ? const Center(
                          child: Text(
                            "No users seated",
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        )
                      : SizedBox(
                          height: 52,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _userList.length,
                            itemBuilder: (context, index) {
                              final user = _userList[index];
                              final seatIdx = user['seatIndex'] as int? ?? index;
                              final seatNum = seatIdx + 1;
                              final name = (user['name'] ?? "User") as String;
                              final isSelected = _selectedSeatIndices.contains(seatIdx);
                              final initial = name.isNotEmpty ? name[0].toUpperCase() : "U";

                              return GestureDetector(
                                onTap: () => _toggleSeat(seatIdx),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                                          ),
                                          border: Border.all(
                                            color: isSelected ? goldColor : Colors.transparent,
                                            width: 2.2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "No.$seatNum",
                                        style: TextStyle(
                                          color: isSelected ? goldColor : Colors.white60,
                                          fontSize: 9.5,
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
                ),
                GestureDetector(
                  onTap: _toggleSelectAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isAllSelected ? goldColor : cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isAllSelected ? goldColor : Colors.white24),
                    ),
                    child: Text(
                      "All Mics",
                      style: TextStyle(
                        color: _isAllSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Gift Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _gifts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.84,
              ),
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                final isSelected = _selectedGiftIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedGiftIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? goldColor.withOpacity(0.18) : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? goldColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            gift.imageAsset,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) =>
                                Text(gift.icon, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          gift.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "🪙 ${gift.price}",
                          style: const TextStyle(color: goldColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: cardBg,

border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: goldColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "$_coins",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                // Multiplier dropdown
                PopupMenuButton<int>(
                  color: const Color(0xFF2E2458),
                  initialValue: _selectedMultiplier,
                  onSelected: (val) => setState(() => _selectedMultiplier = val),
                  itemBuilder: (context) => _multipliers
                      .map((m) => PopupMenuItem<int>(
                            value: m,
                            child: Text(
                              "x$m",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "x$_selectedMultiplier",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const Icon(Icons.arrow_drop_up, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _isSending ? null : _sendGift,
                  child: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          "Send (🪙$totalCost)",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
