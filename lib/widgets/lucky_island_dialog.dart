import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LuckyIslandDialog extends StatefulWidget {
  const LuckyIslandDialog({super.key});

  @override
  State<LuckyIslandDialog> createState() => _LuckyIslandDialogState();
}

class _LuckyIslandDialogState extends State<LuckyIslandDialog>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late AnimationController _animController;
  late Animation<double> _animation;

  // የማባዣ ቦታዎች (Slots)
  final List> _slots = [
    {"label": "2x", "mult": 2.0, "icon": "🌴", "color": Color(0xFF00E676)},
    {"label": "0x", "mult": 0.0, "icon": "💣", "color": Color(0xFFFF5252)},
    {"label": "1.5x", "mult": 1.5, "icon": "🥥", "color": Color(0xFF40C4FF)},
    {"label": "5x", "mult": 5.0, "icon": "💎", "color": Color(0xFFFFD700)},
    {"label": "0x", "mult": 0.0, "icon": "🌊", "color": Color(0xFFFF5252)},
    {"label": "10x", "mult": 10.0, "icon": "👑", "color": Color(0xFFFF4081)},
    {"label": "0.5x", "mult": 0.5, "icon": "🐚", "color": Color(0xFFFFAB40)},
    {"label": "50x", "mult": 50.0, "icon": "🏴‍☠️", "color": Color(0xFFE040FB)},
  ];

  final List<int> _betOptions = [100, 500, 1000, 5000];
  int _selectedBet = 100;
  bool _isSpinning = false;
  double _currentRotation = 0.0;
  int _winningIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _playGame(int currentCoins) async {
    if (_isSpinning) return;

    if (currentCoins < _selectedBet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient coins! Please recharge."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSpinning = true);

    final uid = _currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // 1. መጀመሪያ ያስያዘውን ሳንቲም ከዳታቤዝ መቀነስ
    await userRef.update({
      'coins': FieldValue.increment(-_selectedBet),
    });

    // 2. በዘፈቀደ የደረሰውን ውጤት መምረጥ
    final random = Random();
    final pickedIndex = random.nextInt(_slots.length);
    _winningIndex = pickedIndex;

    // የማዞሪያ ስሌት (ቢያንስ 5 ሙሉ ዙር ዞሮ የተመረጠው ላይ ያርፋል)
    final double anglePerItem = (2 * pi) / _slots.length;
    final double targetRotation =
        _currentRotation + (10 * pi) + ((_slots.length - pickedIndex) * anglePerItem);

    _animation = Tween<double>(
      begin: _currentRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.reset();
    _animController.forward().then((_) async {
      _currentRotation = targetRotation % (2 * pi);

      final winningSlot = _slots[_winningIndex];
      final double mult = winningSlot['mult'];
      final int wonAmount = (_selectedBet * mult).toInt();

      // 3. ያሸነፈ ከሆነ ሳንቲሙን ገቢ ማድረግ
      if (wonAmount > 0) {
        await userRef.update({
          'coins': FieldValue.increment(wonAmount),
        });
      }

      setState(() => _isSpinning = false);

      if (mounted) {
        _showResultDialog(wonAmount, winningSlot);
      }
    });
  }

  void _showResultDialog(int wonAmount, Map<String, dynamic> slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: slot['color'], width: 1.5),

),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(slot['icon'], style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(
              wonAmount > 0 ? "BIG WIN!" : "TRY AGAIN",
              style: TextStyle(
                color: slot['color'],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wonAmount > 0 ? "+$wonAmount Coins" : "Better luck next spin!",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: slot['color'],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final int coins = (userData['coins'] as num?)?.toInt() ?? 0;

        return Container(
          height: 520,
          decoration: const BoxDecoration(
            color: Color(0xFF131120),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // ርዕስ እና ቀሪ ሳንቲም
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text("🏝️", style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        "Lucky Island",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // የማዞሪያ መንኮራኩር ቦታ

Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final angle = _isSpinning ? _animation.value : _currentRotation;
                          return Transform.rotate(
                            angle: angle,
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E1B2E),
                                border: Border.all(color: const Color(0xFF00E676), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E676).withOpacity(0.2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: List.generate(_slots.length, (idx) {
                                  final double itemAngle = (2 * pi / _slots.length) * idx;
                                  return Transform.rotate(
                                    angle: itemAngle,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Column(
                                          children: [
                                            Text(_slots[idx]['icon'], style: const TextStyle(fontSize: 20)),
                                            Text(
                                              _slots[idx]['label'],
                                              style: TextStyle(
                                                color: _slots[idx]['color'],
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                      // የመሃል ጠቋሚ አዶ
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFD700),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_upward, color: Colors.black, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // የመወራረጃ መጠን መምረጫ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _betOptions.map((amount) {
                  final isSelected = _selectedBet == amount;
                  return GestureDetector(
                    onTap: _isSpinning ? null : () => setState(() => _selectedBet = amount),

child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00E676) : const Color(0xFF1E1B2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00E676) : Colors.white12,
                        ),
                      ),
                      child: Text(
                        "🪙 $amount",
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Spin ቁልፍ
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                  ),
                  onPressed: _isSpinning ? null : () => _playGame(coins),
                  child: Text(
                    _isSpinning ? "Exploring Island..." : "Spin & Explore (🪙 $_selectedBet)",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
