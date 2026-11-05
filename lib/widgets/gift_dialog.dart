import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GiftItem {
  final String id;
  final String name;
  final String icon;
  final int price;

  const GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
  });
}

class GiftDialog extends StatefulWidget {
  final String roomId;
  final List> activeUsers; // e.g. [{'uid': '123', 'name': 'User 1', 'avatar': 'url'}]
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
    GiftItem(id: "rose", name: "Rose", icon: "🌹", price: 10),
    GiftItem(id: "heart", name: "Heart", icon: "💖", price: 50),
    GiftItem(id: "perfume", name: "Perfume", icon: "🧴", price: 100),
    GiftItem(id: "crown", name: "Crown", icon: "👑", price: 500),
    GiftItem(id: "diamond", name: "Diamond", icon: "💎", price: 1000),
    GiftItem(id: "supercar", name: "Supercar", icon: "🏎️", price: 5000),
    GiftItem(id: "rocket", name: "Rocket", icon: "🚀", price: 10000),
    GiftItem(id: "castle", name: "Castle", icon: "🏰", price: 20000),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.userCoins;
    // Default select the first active user if available
    if (widget.activeUsers.isNotEmpty) {
      _selectedUserIds.add(widget.activeUsers.first['uid'] as String);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedUserIds.clear();
        _isAllSelected = false;
      } else {
        _selectedUserIds.clear();
        for (final user in widget.activeUsers) {
          _selectedUserIds.add(user['uid'] as String);
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
        if (_selectedUserIds.length == widget.activeUsers.length) {
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
        const SnackBar(content: Text("Select at least one recipient.")),
      );
      return;
    }

    final totalCost = _calculateTotalPrice;
    if (_coins < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins to send gift!")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final selectedGift = _gifts[_selectedGiftIndex];
      final senderRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final senderDoc = await transaction.get(senderRef);
        final currentBalance = (senderDoc.data() as Map<String, dynamic>)['coins'] ?? 0;

if (currentBalance < totalCost) {
          throw Exception("Insufficient balance.");
        }

        // Deduct coins from sender
        transaction.update(senderRef, {'coins': FieldValue.increment(-totalCost)});

        // Distribute diamonds/points to selected recipients
        final pointsPerRecipient = selectedGift.price;
        for (final recipientId in _selectedUserIds) {
          final recipientRef = FirebaseFirestore.instance.collection('users').doc(recipientId);
          transaction.update(recipientRef, {
            'diamonds': FieldValue.increment(pointsPerRecipient),
          });
        }

        // Broadcast gift event to room
        final eventRef = roomRef.collection('events').doc();
        transaction.set(eventRef, {
          'type': 'gift',
          'senderId': _currentUser!.uid,
          'giftId': selectedGift.id,
          'giftName': selectedGift.name,
          'giftIcon': selectedGift.icon,
          'recipients': _selectedUserIds.toList(),
          'totalCost': totalCost,
          'createdAt': FieldValue.serverTimestamp(),
        });
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
          SnackBar(content: Text("Transaction failed: $e")),
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
    final selectedGift = _gifts[_selectedGiftIndex];
    final totalCost = _calculateTotalPrice;

    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header: Recipient Selector with "All"
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.activeUsers.length,
                      itemBuilder: (context, index) {
                        final user = widget.activeUsers[index];
                        final uid = user['uid'] as String;
                        final isSelected = _selectedUserIds.contains(uid);

return GestureDetector(
                          onTap: () => _toggleUser(uid),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                  backgroundImage: user['avatar'] != null
                                      ? NetworkImage(user['avatar'])
                                      : null,
                                  child: user['avatar'] == null
                                      ? const Icon(Icons.person, size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user['name'] ?? 'User',
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

          // Gift Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _gifts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
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

          // Bottom Bar: Balance, Total, Send Action
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
