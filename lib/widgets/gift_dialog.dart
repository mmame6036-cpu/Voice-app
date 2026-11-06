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
  final int totalCost;

  GiftSendResult({
    required this.gift,
    required this.targetSeatIndices,
    required this.isAll,
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

  int _selectedGiftIndex = 0;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkBg = Color(0xFF171524);
  static const Color cardBg = Color(0xFF1E1B2E);

  final List<GiftItem> _gifts = const [
    GiftItem(
      id: "lollipop",
      name: "Lollipop",
      icon: "🍭",
      price: 5,
      imageAsset: "assets/images/wikimediaimages-candy-2201920.jpg",
    ),
    GiftItem(
      id: "heart_badge",
      name: "Heart",
      icon: "💖",
      price: 20,
      imageAsset: "assets/images/weekly_lovers_heart_value.webp",
    ),
    GiftItem(
      id: "charm_badge",
      name: "Charm",
      icon: "✨",
      price: 50,
      imageAsset: "assets/images/charm_07.webp",
    ),
    GiftItem(
      id: "wealth_badge",
      name: "Wealth",
      icon: "👑",
      price: 100,
      imageAsset: "assets/images/wealth_03.webp",
    ),
    GiftItem(
      id: "rose",
      name: "Rose",
      icon: "🌹",
      price: 10,
      imageAsset: "assets/images/wikimediaimages-candy-2201920.jpg",
    ),
    GiftItem(
      id: "perfume",
      name: "Perfume",
      icon: "🧴",
      price: 200,
      imageAsset: "assets/images/charm_07.webp",
    ),
    GiftItem(
      id: "diamond",
      name: "Diamond",
      icon: "💎",
      price: 1000,
      imageAsset: "assets/images/wealth_03.webp",
    ),
    GiftItem(
      id: "rocket",
      name: "Rocket",
      icon: "🚀",
      price: 5000,
      imageAsset: "assets/images/weekly_lovers_heart_value.webp",
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
    for (final u in _userList) {
      final sIdx = u['seatIndex'] as int?;
      if (sIdx != null) {
        _selectedSeatIndices.add(sIdx);
        break;
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
    return unitPrice * _selectedSeatIndices.length;
  }

  Future<void> _sendGift() async {
    if (_currentUser == null) return;
    if (_selectedSeatIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one seat or All")),
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

      await senderRef.set({
        'coins': FieldValue.increment(-totalCost),
      }, SetOptions(merge: true));

      final pointsPerRecipient = selectedGift.price;
      for (final sIndex in _selectedSeatIndices) {
        final occupant = _userList.firstWhere(
          (u) => u['seatIndex'] == sIndex,
          orElse: () => null,
        );
        if (occupant != null) {
          final uid = occupant['uid']?.toString() ?? "";
          if (uid.isNotEmpty) {
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'diamonds': FieldValue.increment(pointsPerRecipient),
            }, SetOptions(merge: true));
          }
        }
      }

      await roomRef.collection('events').add({
        'type': 'gift',
        'senderId': _currentUser!.uid,
        'giftId': selectedGift.id,
        'giftName': selectedGift.name,
        'giftIcon': selectedGift.icon,
        'imageAsset': selectedGift.imageAsset,
        'seats': _selectedSeatIndices.toList(),
        'totalCost': totalCost,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _coins -= totalCost);
      widget.onCoinsUpdated?.call(_coins);

      if (mounted) {
        Navigator.pop(
          context,
          GiftSendResult(
            gift: selectedGift,
            targetSeatIndices: _selectedSeatIndices.toList(),
            isAll: _isAllSelected,
            totalCost: totalCost,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sending failed: $e")),
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
      height: 490,
      decoration: const BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 30 Seats horizontal ribbon with "All" button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleSelectAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 30, // 30 Seats ordered
                      itemBuilder: (context, index) {
                        final seatIndex = index;
                        final seatNum = seatIndex + 1;
                        final occupant = _userList.firstWhere(
                          (u) => u['seatIndex'] == seatIndex,
                          orElse: () => null,
                        );

                        final isOccupied = occupant != null;
                        final isSelected = _selectedSeatIndices.contains(seatIndex);

                        return GestureDetector(
                          onTap: isOccupied ? () => _toggleSeat(seatIndex) : null,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? goldColor.withOpacity(0.2)
                                  : (isOccupied ? cardBg : Colors.white.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? goldColor
                                    : (isOccupied ? Colors.white24 : Colors.transparent),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 14,
                                      color: isSelected
                                          ? goldColor
                                          : (isOccupied ? Colors.white : Colors.white24),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Seat $seatNum",
                                      style: TextStyle(
                                        color: isSelected ? goldColor : Colors.white70,
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isOccupied ? (occupant['name'] ?? "User") : "Empty",
                                  style: TextStyle(
                                    color: isOccupied ? Colors.white54 : Colors.white24,
                                    fontSize: 8.5,

),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
              padding: const EdgeInsets.all(12),
              itemCount: _gifts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                final isSelected = _selectedGiftIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedGiftIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? goldColor.withOpacity(0.15) : cardBg,
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
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) =>
                                Text(gift.icon, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gift.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "🪙 ${gift.price}",
                          style: const TextStyle(color: goldColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Send bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(

crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total: 🪙 $totalCost",
                      style: const TextStyle(
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "${_selectedSeatIndices.length} seats",
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _isSending ? null : _sendGift,
                  child: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text("Send", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
