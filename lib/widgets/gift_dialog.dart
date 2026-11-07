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
  static const Color darkBg = Color(0xFF130F26);
  static const Color cardBg = Color(0xFF1E1738);

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
      id: "crystal_blue_rose",
      name: "Crystal Rose",
      icon: "🌹",
      price: 999,
      imageAsset: "assets/images/wikimediaimages-candy-2201920.jpg",
    ),
    GiftItem(
      id: "diamond",
      name: "Royal Diamond",
      icon: "💎",
      price: 1500,
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

      senderRef.set({
        'coins': FieldValue.increment(-totalCost),
      }, SetOptions(merge: true)).catchError((_) {});

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
      height: 440,
      decoration: const BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // እጅግ በጣም የጠበበና እስከ 20+ ሰው የሚያስተናግድ የወንበር መምረጫ
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
                      itemCount: 30, // 30 ወንበሮች በጠባብ ዲዛይን
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

          // Gift Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _gifts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,

mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                final isSelected = _selectedGiftIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedGiftIndex = index),
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
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) =>
                                Text(gift.icon, style: const TextStyle(fontSize: 26)),
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
                const Spacer(),
                PopupMenuButton<int>(
                  color: const Color(0xFF281E48),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "x$_selectedMultiplier",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        const Icon(Icons.arrow_drop_up, color: Colors.white70, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSending ? null : _sendGift,
                  child: _isSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          "Send (🪙$totalCost)",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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
