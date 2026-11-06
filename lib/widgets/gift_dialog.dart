import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GiftItem {
  final String id;
  final String name;
  final String icon;
  final int price;
  final String? imageAsset;

  const GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    this.imageAsset,
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

  final Set<String> _selectedUserIds = {};
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
    GiftItem(id: "rose", name: "Rose", icon: "🌹", price: 10),
    GiftItem(id: "perfume", name: "Perfume", icon: "🧴", price: 200),
    GiftItem(id: "diamond", name: "Diamond", icon: "💎", price: 1000),
    GiftItem(id: "rocket", name: "Rocket", icon: "🚀", price: 5000),
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
      final firstUid = firstUser['uid']?.toString();
      if (firstUid != null && firstUid.isNotEmpty) {
        _selectedUserIds.add(firstUid);
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedUserIds.clear();
        _isAllSelected = false;
      } else {
        _selectedUserIds.clear();
        for (final user in _userList) {
          final uid = user['uid']?.toString();
          if (uid != null && uid.isNotEmpty) {
            _selectedUserIds.add(uid);
          }
        }
        _isAllSelected = true;
      }
    });
  }

  void _toggleUser(String uid) {
    setState(() {
      if (_selectedUserIds.contains(uid)) {
        _selectedUserIds.remove(uid);
        _isAllSelected = false;
      } else {
        _selectedUserIds.add(uid);
        if (_selectedUserIds.length == _userList.length && _userList.isNotEmpty) {
          _isAllSelected = true;
        }
      }
    });
  }

  int get _calculateTotalPrice {
    if (_selectedUserIds.isEmpty) return 0;
    final unitPrice = _gifts[_selectedGiftIndex].price;
    return unitPrice * _selectedUserIds.length;
  }

  Future<void> _sendGift() async {
    if (_currentUser == null) return;
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one recipient.")),
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
      await senderRef.set({
        'coins': FieldValue.increment(-totalCost),
      }, SetOptions(merge: true));

      // Add diamonds to all selected recipients safely
      final pointsPerRecipient = selectedGift.price;
      for (final recipientId in _selectedUserIds) {
        if (recipientId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(recipientId).set({
            'diamonds': FieldValue.increment(pointsPerRecipient),
          }, SetOptions(merge: true));
        }
      }

      // Log gift event in room history
      await roomRef.collection('events').add({
        'type': 'gift',
        'senderId': _currentUser!.uid,
        'giftId': selectedGift.id,
        'giftName': selectedGift.name,
        'giftIcon': selectedGift.icon,
        'imageAsset': selectedGift.imageAsset,
        'recipients': _selectedUserIds.toList(),
        'totalCost': totalCost,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _coins -= totalCost);
      widget.onCoinsUpdated?.call(_coins);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sent ${selectedGift.name} to ${_selectedUserIds.length} users!")),
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
      height: 480,
      decoration: const BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleSelectAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isAllSelected ? goldColor : cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isAllSelected ? goldColor : Colors.white24),
                    ),
                    child: Text(
                      "All",
                      style: TextStyle(
                        color: _isAllSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,

itemCount: _userList.length,
                      itemBuilder: (context, index) {
                        final user = _userList[index];
                        final uid = (user['uid'] ?? "") as String;
                        final isSelected = _selectedUserIds.contains(uid);
                        final seatNumber = user['seatIndex'] != null ? "${user['seatIndex'] + 1}" : "${index + 1}";

                        return GestureDetector(
                          onTap: () => _toggleUser(uid),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? goldColor.withOpacity(0.2) : cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? goldColor : Colors.white12,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: user['avatar'] != null && user['avatar'] != ""
                                      ? NetworkImage(user['avatar'])
                                      : null,
                                  child: (user['avatar'] == null || user['avatar'] == "")
                                      ? Text(seatNumber, style: const TextStyle(fontSize: 10, color: Colors.white))
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user['name'] ?? 'Seat $seatNumber',
                                  style: TextStyle(
                                    color: isSelected ? goldColor : Colors.white70,
                                    fontSize: 11,
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
              ],
            ),
          ),
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
                        if (gift.imageAsset != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              gift.imageAsset!,
                              width: 34,
                              height: 34,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) =>
                                  Text(gift.icon, style: const TextStyle(fontSize: 28)),
                            ),
                          )
                        else
                          Text(gift.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          gift.name,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                      style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      "${_selectedUserIds.length} selected",
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
