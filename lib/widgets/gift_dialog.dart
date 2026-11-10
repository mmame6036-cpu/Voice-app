import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
  final GiftCategory category;

  const GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.imageAsset,
    required this.category,
  });

  double get pointRate => category == GiftCategory.lucky ? 0.04 : 0.70;
  bool get isLucky => category == GiftCategory.lucky;
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

class _GiftDialogState extends State<GiftDialog> with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late int _coins;
  bool _isSending = false;

  final Set<int> _selectedSeatIndices = {};
  bool _isAllSelected = false;
  int _selectedMultiplier = 1;
  final List<int> _multipliers = [1, 3, 7, 10, 30, 50, 77, 100];

  int _selectedCategoryIndex = 1; // Lucky Tab
  int _selectedGiftIndex = 0;
  int _comboCount = 0;
  Timer? _comboTimer;

  // Win Explosion Animation
  bool _showWinExplosion = false;
  int _lastWonCoins = 0;
  int _lastWinMultiplier = 0;
  GiftItem? _explodingGift;
  late AnimationController _explosionController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

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
    // 1. Hot Category
    GiftItem(
      id: "flowers",
      name: "Fragrant Rose",
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

    // 2. Lucky Category (10 እስከ 1000)
    GiftItem(
      id: "ke1",
      name: "ke1",
      icon: "🔑",
      price: 10,
      imageAsset: "assets/images/ke1.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke2",
      name: "ke2",
      icon: "🔑",
      price: 20,
      imageAsset: "assets/images/ke2.jpg",

category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke3",
      name: "ke3",
      icon: "👑",
      price: 30,
      imageAsset: "assets/images/ke3.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke4",
      name: "ke4",
      icon: "💎",
      price: 50,
      imageAsset: "assets/images/ke4.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke5",
      name: "ke5",
      icon: "💠",
      price: 80,
      imageAsset: "assets/images/ke5.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke6",
      name: "ke6",
      icon: "🪔",
      price: 100,
      imageAsset: "assets/images/ke6.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke7",
      name: "ke7",
      icon: "💍",
      price: 150,
      imageAsset: "assets/images/ke7.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke8",
      name: "ke8",
      icon: "💎",
      price: 200,
      imageAsset: "assets/images/ke8.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke9",
      name: "ke9",
      icon: "👑",
      price: 250,
      imageAsset: "assets/images/ke9.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke10",
      name: "ke10",
      icon: "💠",
      price: 300,
      imageAsset: "assets/images/ke10.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke11",
      name: "ke11",
      icon: "💲",
      price: 380,
      imageAsset: "assets/images/ke11.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke12",
      name: "ke12",
      icon: "👑",
      price: 450,
      imageAsset: "assets/images/ke12.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke13",
      name: "ke13",
      icon: "🪔",
      price: 520,
      imageAsset: "assets/images/ke13.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke14",
      name: "ke14",
      icon: "🌹",
      price: 600,
      imageAsset: "assets/images/ke14.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke15",
      name: "ke15",
      icon: "💙",
      price: 700,
      imageAsset: "assets/images/ke15.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke16",
      name: "ke16",
      icon: "🐬",
      price: 800,
      imageAsset: "assets/images/ke16.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke17",
      name: "ke17",
      icon: "🌸",
      price: 880,
      imageAsset: "assets/images/ke17.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke18",
      name: "ke18",
      icon: "⏳",
      price: 920,
      imageAsset: "assets/images/ke18.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "ke19",
      name: "ke19",
      icon: "🦋",
      price: 960,
      imageAsset: "assets/images/ke19.jpg",
      category: GiftCategory.lucky,
    ),
    GiftItem(
      id: "prism_diamond",
      name: "Prism Diamond",
      icon: "💎",
      price: 1000,
      imageAsset: "assets/images/Prism Diamond.jpg",
      category: GiftCategory.lucky,
    ),

    // 3. Luxury Category
    GiftItem(
      id: "sportscar",
      name: "Supercar",
      icon: "🏎️",
      price: 2000,
      imageAsset: "assets/images/wealth_03.webp",
      category: GiftCategory.luxury,
    ),
    GiftItem(
      id: "rocket",
      name: "Space Rocket",
      icon: "🚀",
      price: 5000,
      imageAsset: "assets/images/wealth_08.webp",
      category: GiftCategory.luxury,
    ),

    // 4. Intimacy Category
    GiftItem(
      id: "lovers_heart",
      name: "Lovers Heart",
      icon: "💖",
      price: 520,
      imageAsset: "assets/images/weekly_lovers_heart_value.webp",
      category: GiftCategory.intimacy,
    ),
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
      final sIdx = firstUser['seatIndex'] as int?;
      if (sIdx != null) {
        _selectedSeatIndices.add(sIdx);
      }
    }

    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 1.45).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.85).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.85, end: 3.2).chain(CurveTween(curve: Curves.fastOutSlowIn)), weight: 25),
    ]).animate(_explosionController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_explosionController);
  }

  @override
  void dispose() {
    _comboTimer?.cancel();
    _audioPlayer.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  // Five_win.mp3 ድምፅ ማጫወቻ
  Future<void> _playFiveWinSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/Five_win.mp3'));
    } catch (_) {}
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

      // 1. Five_win.mp3 ድምፅ ማጫወት
      _playFiveWinSound();

      final senderRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      final netDeduction = -totalCost + wonCoins;

      // 2. ለላኪው Wealth EXP ማሳደግ
      senderRef.set({
        'coins': FieldValue.increment(netDeduction),
        'wealthExp': FieldValue.increment(totalCost),
      }, SetOptions(merge: true)).catchError((_) {});

      // Points calculation (4% for lucky, 70% for standard)
      final double hostRate = selectedGift.pointRate;
      final int pointsPerRecipient = max(
        1,
        (selectedGift.price * _selectedMultiplier * hostRate).round(),
      );

      // 3. ለተቀባዮቹ Points እና Charm EXP ብቻ መደመር (ዳይመንድ የለም)
      for (final sIndex in _selectedSeatIndices) {
        final occupant = _userList.firstWhere(
          (u) => u['seatIndex'] == sIndex,
          orElse: () => null,
        );
        if (occupant != null) {
          final uid = occupant['uid']?.toString() ?? "";
          if (uid.isNotEmpty) {
            FirebaseFirestore.instance.collection('users').doc(uid).set({
              'points': FieldValue.increment(pointsPerRecipient),
              'charmExp': FieldValue.increment(pointsPerRecipient),
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

      // 4. Lucky Win ሲሆን ራሱ ስጦታው በስክሪኑ ላይ እንዲፈነዳ ማድረግ
      if (wonCoins > 0) {
        setState(() {
          _showWinExplosion = true;
          _lastWonCoins = wonCoins;
          _lastWinMultiplier = maxMultiplier;
          _explodingGift = selectedGift;
        });
        _explosionController.forward(from: 0.0).then((_) {
          if (mounted) {
            setState(() => _showWinExplosion = false);
            final int fullSeatCost = selectedGift.price * _selectedMultiplier;
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
        });
        return;
      }

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

    return Stack(
      children: [
        Container(
          height: 480,
          decoration: const BoxDecoration(
            color: darkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Seat selector
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

              // Categories
              Container(
                height: 38,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                          _selectedGiftIndex = 0;
                          _comboCount = 0;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? goldColor : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? goldColor : Colors.white12,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getCategoryName(_categories[index]),
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Gifts Grid (ሳጥን የሌለው፣ ራሱን የቻለ ጎላ ያለ እይታ)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),

itemCount: currentGifts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
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
                        color: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: goldColor.withOpacity(0.45),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Image.asset(
                                gift.imageAsset,
                                width: 62,
                                height: 62,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) =>
                                    Text(gift.icon, style: const TextStyle(fontSize: 32)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              gift.name,
                              style: TextStyle(
                                color: isSelected ? goldColor : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "🪙 ${gift.price}",
                              style: const TextStyle(
                                color: goldColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom control bar (Points ብቻ የሚታይበት)
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

style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    if (selectedGift != null)
                      Text(
                        "Pts ${(selectedGift.price * _selectedMultiplier * selectedGift.pointRate).round()} (${selectedGift.isLucky ? '4%' : '70%'})",
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_up, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _comboCount > 0 ? Colors.deepOrangeAccent : goldColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                              _comboCount > 0
                                  ? "COMBO x$_comboCount"
                                  : "Send (🪙$totalCost)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: _comboCount > 0 ? Colors.white : Colors.black,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

// 5. ራሱ ስጦታው ስክሪኑን ሞልቶ ፈንድቶ የሚጠፋበት አኒሜሽን
        if (_showWinExplosion && _explodingGift != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _explosionController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    color: Colors.black.withOpacity(0.70),
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: goldColor.withOpacity(0.85),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              _explodingGift!.imageAsset,
                              width: 190,
                              height: 190,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: goldColor, width: 2),
                            ),
                            child: Text(
                              "WIN x$_lastWinMultiplier! +$_lastWonCoins COINS",
                              style: const TextStyle(
                                color: goldColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
