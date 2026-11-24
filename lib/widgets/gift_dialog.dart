import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

enum GiftCategory { hot, lucky, luxury, intimacy }

class GiftItem {
  final String id;
  final String name;
  final String icon;
  final int price;
  final String imageAsset;
  final String animationAsset;
  final GiftCategory category;

  const GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.imageAsset,
    this.animationAsset = "",
    required this.category,
  });

  double get pointRate => category == GiftCategory.lucky ? 0.04 : 0.70;
  bool get isLucky => category == GiftCategory.lucky;
  String get playAsset => animationAsset.isNotEmpty ? animationAsset : imageAsset;
}

class GiftSendResult {
  final GiftItem gift;
  final List<int> targetSeatIndices;
  final bool isAll;
  final int multiplier;
  final int totalCost;
  final int wonCoins;
  final int rawGiftCostPerSeat;

  GiftSendResult({
    required this.gift,
    required this.targetSeatIndices,
    required this.isAll,
    required this.multiplier,
    required this.totalCost,
    this.wonCoins = 0,
    int? rawGiftCostPerSeat,
  }) : rawGiftCostPerSeat = rawGiftCostPerSeat ?? (gift.price * multiplier);
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
  final Random _random = Random();

  late int _coins;
  bool _isSending = false;

  final Set<int> _selectedSeatIndices = {};
  bool _isAllSelected = false;
  int _selectedMultiplier = 1;
  final List<int> _multipliers = const [1, 3, 7, 10, 30, 50, 77, 100];

  int _selectedCategoryIndex = 0;
  int _selectedGiftIndex = 0;

  static const Color kMintSelect = Color(0xFF26E6C8);
  static const Color kSendTeal = Color(0xFF1ED7B5);
  static const Color kGoldCoin = Color(0xFFFFD700);
  static const int kMinWinSoundThreshold = 2000;

  final List<GiftCategory> _categories = const [
    GiftCategory.hot,
    GiftCategory.lucky,
    GiftCategory.luxury,
    GiftCategory.intimacy,
  ];

  final List<GiftItem> _allGifts = const [
    // 1. HOT CATEGORY (1,000 - 15,000 Coins)
    GiftItem(id: "svga2", name: "Golden Rose", icon: "🌹", price: 1000, imageAsset: "assets/images/svga2.jpg", animationAsset: "assets/svga/svga2.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga3", name: "Royal Crown", icon: "👑", price: 1500, imageAsset: "assets/images/svga3.jpg", animationAsset: "assets/svga/svga3.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga4", name: "Magic Perfume", icon: "🧴", price: 2000, imageAsset: "assets/images/svga4.jpg", animationAsset: "assets/svga/svga4.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga6", name: "Crystal Ring", icon: "💍", price: 3000, imageAsset: "assets/images/svga6.jpg", animationAsset: "assets/svga/svga6.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga7", name: "Starlight Harp", icon: "🎵", price: 4000, imageAsset: "assets/images/svga7.jpg", animationAsset: "assets/svga/svga7.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga9", name: "Fire Phoenix", icon: "🔥", price: 5000, imageAsset: "assets/images/svga9.jpg", animationAsset: "assets/svga/svga9.mp4", category: GiftCategory.hot),

GiftItem(id: "svga10", name: "Diamond Chest", icon: "💎", price: 6500, imageAsset: "assets/images/svga10.jpg", animationAsset: "assets/svga/svga10.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga11", name: "Golden Eagle", icon: "🦅", price: 8000, imageAsset: "assets/images/svga11.jpg", animationAsset: "assets/svga/svga11.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga12", name: "Royal Carriage", icon: "🎠", price: 10000, imageAsset: "assets/images/svga12.jpg", animationAsset: "assets/svga/svga12.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga13", name: "Blue Dragon", icon: "🐉", price: 12000, imageAsset: "assets/images/svga13.jpg", animationAsset: "assets/svga/svga13.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga14", name: "Victory Trophy", icon: "🏆", price: 13500, imageAsset: "assets/images/svga14.jpg", animationAsset: "assets/svga/svga14.mp4", category: GiftCategory.hot),
    GiftItem(id: "svga15", name: "Magic Lamp", icon: "🪔", price: 15000, imageAsset: "assets/images/svga15.jpg", animationAsset: "assets/svga/svga15.mp4", category: GiftCategory.hot),

    // 2. LUCKY CATEGORY
    GiftItem(id: "ke1", name: "ke1", icon: "🔑", price: 10, imageAsset: "assets/images/ke1.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke2", name: "ke2", icon: "🔑", price: 20, imageAsset: "assets/images/ke2.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke3", name: "ke3", icon: "👑", price: 30, imageAsset: "assets/images/ke3.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke4", name: "ke4", icon: "💎", price: 50, imageAsset: "assets/images/ke4.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke5", name: "ke5", icon: "💠", price: 80, imageAsset: "assets/images/ke5.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke6", name: "ke6", icon: "🪔", price: 100, imageAsset: "assets/images/ke6.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke7", name: "ke7", icon: "💍", price: 150, imageAsset: "assets/images/ke7.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke8", name: "ke8", icon: "💎", price: 200, imageAsset: "assets/images/ke8.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke9", name: "ke9", icon: "👑", price: 250, imageAsset: "assets/images/ke9.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke10", name: "ke10", icon: "💠", price: 300, imageAsset: "assets/images/ke10.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke11", name: "ke11", icon: "💲", price: 380, imageAsset: "assets/images/ke11.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke12", name: "ke12", icon: "👑", price: 450, imageAsset: "assets/images/ke12.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke13", name: "ke13", icon: "🪔", price: 520, imageAsset: "assets/images/ke13.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke14", name: "ke14", icon: "🌹", price: 600, imageAsset: "assets/images/ke14.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke15", name: "ke15", icon: "💙", price: 700, imageAsset: "assets/images/ke15.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke16", name: "ke16", icon: "🐬", price: 800, imageAsset: "assets/images/ke16.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke17", name: "ke17", icon: "🌸", price: 880, imageAsset: "assets/images/ke17.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke18", name: "ke18", icon: "⏳", price: 920, imageAsset: "assets/images/ke18.jpg", category: GiftCategory.lucky),
    GiftItem(id: "ke19", name: "ke19", icon: "🦋", price: 960, imageAsset: "assets/images/ke19.jpg", category: GiftCategory.lucky),
    GiftItem(id: "prism_diamond", name: "Prism Diamond", icon: "💎", price: 1000, imageAsset: "assets/images/Prism Diamond.jpg", category: GiftCategory.lucky),

    // 3. LUXURY CATEGORY (20,000 - 500,000 Coins)

GiftItem(id: "svga27", name: "Gold Supercar", icon: "🏎️", price: 20000, imageAsset: "assets/images/svga27.jpg", animationAsset: "assets/svga/svga27.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga29", name: "VIP Helicopter", icon: "🚁", price: 35000, imageAsset: "assets/images/svga29.jpg", animationAsset: "assets/svga/svga29.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga30", name: "Luxury Yacht", icon: "🛥️", price: 50000, imageAsset: "assets/images/svga30.jpg", animationAsset: "assets/svga/svga30.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga31", name: "Golden Lion", icon: "🦁", price: 75000, imageAsset: "assets/images/svga31.jpg", animationAsset: "assets/svga/svga31.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga32", name: "Private Jet", icon: "✈️", price: 100000, imageAsset: "assets/images/svga32.jpg", animationAsset: "assets/svga/svga32.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga33", name: "Space Rocket", icon: "🚀", price: 150000, imageAsset: "assets/images/svga33.jpg", animationAsset: "assets/svga/svga33.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga34", name: "Imperial Throne", icon: "👑", price: 200000, imageAsset: "assets/images/svga34.jpg", animationAsset: "assets/svga/svga34.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga35", name: "Nile Palace", icon: "🏛️", price: 250000, imageAsset: "assets/images/svga35.jpg", animationAsset: "assets/svga/svga35.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga36", name: "Celestial Dragon", icon: "🐲", price: 300000, imageAsset: "assets/images/svga36.jpg", animationAsset: "assets/svga/svga36.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga37", name: "Golden Phoenix", icon: "🦅", price: 380000, imageAsset: "assets/images/svga37.jpg", animationAsset: "assets/svga/svga37.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga39", name: "Universe Crown", icon: "💫", price: 450000, imageAsset: "assets/images/svga39.jpg", animationAsset: "assets/svga/svga39.mp4", category: GiftCategory.luxury),
    GiftItem(id: "svga40", name: "NILE Legend", icon: "🌟", price: 500000, imageAsset: "assets/images/svga40.jpg", animationAsset: "assets/svga/svga40.mp4", category: GiftCategory.luxury),

    // 4. INTIMACY CATEGORY (2,000 - 80,000 Coins)
    GiftItem(id: "svga16", name: "Sweet Heart", icon: "💖", price: 2000, imageAsset: "assets/images/svga16.jpg", animationAsset: "assets/svga/svga16.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svga17", name: "Love Bear", icon: "🧸", price: 3500, imageAsset: "assets/images/svga17.jpg", animationAsset: "assets/svga/svga17.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svga18", name: "Cupid Arrow", icon: "💘", price: 5000, imageAsset: "assets/images/svga18.jpg", animationAsset: "assets/svga/svga18.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svga19", name: "Twin Swans", icon: "🦢", price: 8000, imageAsset: "assets/images/svga19.jpg", animationAsset: "assets/svga/svga19.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svga20", name: "Romantic Boat", icon: "⛵", price: 12000, imageAsset: "assets/images/svga20.jpg", animationAsset: "assets/svga/svga20.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svga21", name: "Love Balloon", icon: "🎈", price: 18000, imageAsset: "assets/images/svga21.jpg", animationAsset: "assets/svga/svga21.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svga22", name: "Diamond Chain", icon: "📿", price: 25000, imageAsset: "assets/images/svga22.jpg", animationAsset: "assets/svga/svga22.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svga23", name: "Eternal Kiss", icon: "💋", price: 35000, imageAsset: "assets/images/svga23.jpg", animationAsset: "assets/svga/svga23.mp4", category: GiftCategory.intimacy),

GiftItem(id: "svga24", name: "Crystal Castle", icon: "🏰", price: 50000, imageAsset: "assets/images/svga24.jpg", animationAsset: "assets/svga/svga24.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svga25", name: "Starry Proposal", icon: "🌠", price: 65000, imageAsset: "assets/images/svga25.jpg", animationAsset: "assets/svga/svga25.mp4", category: GiftCategory.intimacy),
    GiftItem(id: "svfa26", name: "Royal Wedding", icon: "👰", price: 80000, imageAsset: "assets/images/svfa26.jpg", animationAsset: "assets/svga/svfa26.mp4", category: GiftCategory.intimacy),
  ];

  List<GiftItem> get _currentCategoryGifts {
    final currentCat = _categories[_selectedCategoryIndex];
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
    if (_userList.isNotEmpty) {
      final firstUser = _userList.first;
      if (firstUser is Map) {
        final sIdx = (firstUser['seatIndex'] as num?)?.toInt();
        if (sIdx != null) {
          _selectedSeatIndices.add(sIdx);
        }
      }
    }
  }

  ImageProvider? _resolveUserAvatar(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final idx = url.indexOf(',');
        if (idx != -1) {
          final Uint8List bytes = base64Decode(url.substring(idx + 1));
          return MemoryImage(bytes);
        }
      } catch (_) {
        return null;
      }
    }
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return null;
  }

  Future<void> _playLuckyCoinSound() async {
    try {
      final AudioPlayer player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setVolume(1.0);
      try {
        await player.play(AssetSource('sounds/Five_win.mp3'));
      } catch (_) {
        await player.play(AssetSource('sounds/five_win.mp3'));
      }
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {}
  }

  void _toggleSelectAll() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isAllSelected) {
        _selectedSeatIndices.clear();
        _isAllSelected = false;
      } else {
        _selectedSeatIndices.clear();
        for (final user in _userList) {
          if (user is Map) {
            final sIdx = (user['seatIndex'] as num?)?.toInt();
            if (sIdx != null) {
              _selectedSeatIndices.add(sIdx);
            }
          }
        }
        _isAllSelected = true;
      }
    });
  }

  void _toggleSeat(int seatIndex) {
    HapticFeedback.selectionClick();
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

  int get _effectiveMultiplier {
    final currentGifts = _currentCategoryGifts;
    if (currentGifts.isEmpty) return 1;
    if (_selectedGiftIndex >= currentGifts.length) return 1;
    if (currentGifts[_selectedGiftIndex].isLucky) {
      return _selectedMultiplier;
    }
    return 1;
  }

  int get _calculateTotalPrice {
    final currentGifts = _currentCategoryGifts;
    if (_selectedSeatIndices.isEmpty) return 0;
    if (currentGifts.isEmpty) return 0;
    if (_selectedGiftIndex >= currentGifts.length) return 0;
    final unitPrice = currentGifts[_selectedGiftIndex].price;
    return unitPrice * _effectiveMultiplier * _selectedSeatIndices.length;
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
    final int sendMult = _effectiveMultiplier;

    final totalCost = _calculateTotalPrice;
    if (_coins < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins balance!")),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSending = true);

    try {
      int wonCoins = 0;
      int maxMultiplier = 0;

      if (selectedGift.isLucky) {
        int totalUnits = sendMult * _selectedSeatIndices.length;
        for (int i = 0; i < totalUnits; i++) {
          int mult = _calculateLuckyMultiplier();
          if (mult > 0) {
            maxMultiplier = max(maxMultiplier, mult);
            wonCoins += selectedGift.price * mult;
          }
        }
        if (wonCoins >= kMinWinSoundThreshold) {
          _playLuckyCoinSound();
        }
      }

      final senderRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      final netDeduction = -totalCost + wonCoins;

      senderRef.set({
        'coins': FieldValue.increment(netDeduction),
        'wealthExp': FieldValue.increment(totalCost),
      }, SetOptions(merge: true)).catchError((_) {});

      final double hostRate = selectedGift.pointRate;
      final int fullSeatCost = selectedGift.price * sendMult;
      final int pointsPerRecipient = max(
        1,
        (fullSeatCost * hostRate).round(),
      );

      final Map<String, dynamic> seatGiftIncrements = {};

      for (final sIndex in _selectedSeatIndices) {
        String recipientUid = "";
        seatGiftIncrements['$sIndex'] = FieldValue.increment(fullSeatCost);

        for (final user in _userList) {
          if (user is Map) {
            final sIdx = (user['seatIndex'] as num?)?.toInt();
            if (sIdx == sIndex) {
              recipientUid = (user['uid'] ?? user['userId'] ?? user['id'] ?? "").toString();
              break;
            }
          }
        }

        if (recipientUid.isEmpty && _selectedSeatIndices.contains(sIndex)) {
          recipientUid = _currentUser!.uid;
        }

        if (recipientUid.isNotEmpty) {
          FirebaseFirestore.instance.collection('users').doc(recipientUid).set({
            'points': FieldValue.increment(pointsPerRecipient),
            'receivedGiftPoints': FieldValue.increment(pointsPerRecipient),
            'giftIncomeLast7Days': FieldValue.increment(pointsPerRecipient),
            'charmExp': FieldValue.increment(pointsPerRecipient),
            'todayTaskPoints': FieldValue.increment(pointsPerRecipient),
            'weekTaskPoints': FieldValue.increment(pointsPerRecipient),
          }, SetOptions(merge: true)).catchError((_) {});
        }
      }

      if (seatGiftIncrements.isNotEmpty) {
        roomRef.set({
          'seatGifts': seatGiftIncrements,
        }, SetOptions(merge: true)).catchError((_) {});
      }

      roomRef.collection('events').add({
        'type': 'gift',
        'senderId': _currentUser!.uid,
        'giftId': selectedGift.id,
        'giftName': selectedGift.name,
        'giftIcon': selectedGift.icon,
        'imageAsset': selectedGift.playAsset,
        'thumbAsset': selectedGift.imageAsset,
        'multiplier': sendMult,
        'seats': _selectedSeatIndices.toList(),
        'totalCost': totalCost,
        'pointsAwarded': pointsPerRecipient,
        'isLucky': selectedGift.isLucky,
        'wonCoins': wonCoins,
        'luckyMultiplier': maxMultiplier,
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

final updatedBalance = _coins + netDeduction;
      setState(() => _coins = updatedBalance);
      widget.onCoinsUpdated?.call(_coins);

      if (mounted) {
        Navigator.pop(
          context,
          GiftSendResult(
            gift: selectedGift,
            targetSeatIndices: _selectedSeatIndices.toList(),
            isAll: _isAllSelected,
            multiplier: sendMult,
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

  Widget _buildCrispGiftImage(GiftItem gift, bool isSelected) {
    return AnimatedScale(
      scale: isSelected ? 1.07 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          gift.imageAsset,
          width: 58,
          height: 58,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (ctx, err, stack) => Center(
            child: Text(
              gift.icon,
              style: const TextStyle(fontSize: 38),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = _calculateTotalPrice;
    final currentGifts = _currentCategoryGifts;
    final selectedGift = currentGifts.isNotEmpty && _selectedGiftIndex < currentGifts.length
        ? currentGifts[_selectedGiftIndex]
        : null;
    final int activeMult = _effectiveMultiplier;

    return Container(
      height: 455,
      decoration: BoxDecoration(
        color: const Color(0xFF14151A).withOpacity(0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.14), width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: _userList.isEmpty
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Select recipient on mic",
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _userList.length,
                            itemBuilder: (context, idx) {
                              final rawUser = _userList[idx];
                              if (rawUser is! Map) return const SizedBox.shrink();
                              final int seatIdx =
                                  (rawUser['seatIndex'] as num?)?.toInt() ?? 0;
                              final String avatarUrl =

(rawUser['avatar'] ?? '').toString();
                              final ImageProvider? avatarImg =
                                  _resolveUserAvatar(avatarUrl);
                              final bool isSelected =
                                  _selectedSeatIndices.contains(seatIdx);

                              return GestureDetector(
                                onTap: () => _toggleSeat(seatIdx),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? kMintSelect
                                                : Colors.white24,
                                            width: isSelected ? 2.0 : 1.0,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          backgroundColor: const Color(0xFF252830),
                                          backgroundImage: avatarImg,
                                          child: avatarImg == null
                                              ? const Icon(Icons.person,
                                                  color: Colors.white70, size: 18)
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 0.5),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? kMintSelect
                                                : const Color(0xFF2C303A),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "${seatIdx + 1}",
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontSize: 9,
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
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleSelectAll,

child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isAllSelected
                          ? kMintSelect.withOpacity(0.22)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isAllSelected ? kMintSelect : Colors.white24,
                        width: 1.3,
                      ),
                    ),
                    child: Text(
                      "All",
                      style: TextStyle(
                        color: _isAllSelected ? kMintSelect : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_categories.length, (index) {
                final bool isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategoryIndex = index;
                      _selectedGiftIndex = 0;
                    });
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getCategoryName(_categories[index]),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              itemCount: currentGifts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final gift = currentGifts[index];
                final isSelected = _selectedGiftIndex == index;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedGiftIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),

border: Border.all(
                        color: isSelected ? kMintSelect : Colors.transparent,
                        width: 1.6,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: kMintSelect.withOpacity(0.22),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCrispGiftImage(gift, isSelected),
                        const SizedBox(height: 5),
                        Text(
                          gift.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                color: kGoldCoin, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              "${gift.price}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: kGoldCoin, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    "$_coins",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selectedGift != null)
                    Text(
                      "Pts ${(selectedGift.price * activeMult * selectedGift.pointRate).round()}",
                      style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                    ),
                  const Spacer(),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF262A34),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: kSendTeal.withOpacity(0.6),

width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedGift != null && selectedGift.isLucky)
                          PopupMenuButton<int>(
                            color: const Color(0xFF1F232C),
                            initialValue: _selectedMultiplier,
                            onSelected: (val) =>
                                setState(() => _selectedMultiplier = val),
                            itemBuilder: (context) => _multipliers
                                .map((m) => PopupMenuItem<int>(
                                      value: m,
                                      child: Text(
                                        "x$m",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
                                  Text(
                                    "$_selectedMultiplier",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down,
                                      color: Colors.white70, size: 18),
                                ],
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: _isSending ? null : _sendGift,
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: kSendTeal,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: _isSending
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      totalCost > 0 ? "Send ($totalCost)" : "Send",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
