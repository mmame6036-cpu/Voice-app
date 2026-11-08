import 'dart:async';
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
    with TickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _selectedBet = 100;
  final List<int> _betOptions = [100, 500, 2000, 5000];

  int _currentTileIndex = 0;
  bool _isRolling = false;
  int _lastDiceResult = 1;

  late AnimationController _diceAnimController;
  late Animation<double> _diceRotation;

  // Board layout configuration (16 Tiles)
  final List> _boardTiles = [
    {"label": "START", "mult": 1.0, "type": "start", "icon": Icons.flag},
    {"label": "1.2x", "mult": 1.2, "type": "win", "icon": Icons.monetization_on},
    {"label": "0x", "mult": 0.0, "type": "empty", "icon": Icons.close},
    {"label": "2x", "mult": 2.0, "type": "win", "icon": Icons.card_giftcard},
    {"label": "1.5x", "mult": 1.5, "type": "win", "icon": Icons.monetization_on},
    {"label": "TRAP", "mult": 0.0, "type": "trap", "icon": Icons.dangerous},
    {"label": "3x", "mult": 3.0, "type": "win", "icon": Icons.card_giftcard},
    {"label": "0.5x", "mult": 0.5, "type": "win", "icon": Icons.monetization_on},
    {"label": "CHEST", "mult": 5.0, "type": "chest", "icon": Icons.archive},
    {"label": "1.2x", "mult": 1.2, "type": "win", "icon": Icons.monetization_on},
    {"label": "0x", "mult": 0.0, "type": "empty", "icon": Icons.close},
    {"label": "2.5x", "mult": 2.5, "type": "win", "icon": Icons.card_giftcard},
    {"label": "0.8x", "mult": 0.8, "type": "win", "icon": Icons.monetization_on},
    {"label": "LUCKY", "mult": 10.0, "type": "lucky", "icon": Icons.stars},
    {"label": "1.5x", "mult": 1.5, "type": "win", "icon": Icons.monetization_on},
    {"label": "JACKPOT", "mult": 20.0, "type": "jackpot", "icon": Icons.diamond},
  ];

  @override
  void initState() {
    super.initState();
    _diceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _diceRotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _diceAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _diceAnimController.dispose();
    super.dispose();
  }

  Future<void> _rollDice(int availableCoins) async {
    if (_isRolling) return;

    if (availableCoins < _selectedBet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient coins! Please recharge."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isRolling = true);

    final String uid = _currentUser!.uid;
    final DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      // 1. Deduct bet amount atomically
      await userRef.update({
        'coins': FieldValue.increment(-_selectedBet),
      });

      // 2. Animate dice rotation
      _diceAnimController.repeat();
      await Future.delayed(const Duration(milliseconds: 700));
      final int diceRoll = Random().nextInt(6) + 1; // 1 to 6
      _lastDiceResult = diceRoll;
      _diceAnimController.stop();
      _diceAnimController.reset();

      // 3. Step-by-step movement animation
      for (int step = 1; step <= diceRoll; step++) {
        await Future.delayed(const Duration(milliseconds: 220));
        if (mounted) {
          setState(() {
            _currentTileIndex = (_currentTileIndex + 1) % _boardTiles.length;
          });
        }
      }

      // 4. Calculate payout
      final Map<String, dynamic> landTile = _boardTiles[_currentTileIndex];
      final double multiplier = (landTile['mult'] as num).toDouble();
      final int winAmount = (_selectedBet * multiplier).round();

if (winAmount > 0) {
        await userRef.update({
          'coins': FieldValue.increment(winAmount),
        });
      }

      // 5. Present result to user
      if (mounted) {
        _showResultDialog(winAmount, landTile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Action failed: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRolling = false);
      }
    }
  }

  void _showResultDialog(int winAmount, Map<String, dynamic> tile) {
    final bool isWin = winAmount > 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isWin ? const Color(0xFFFFD700) : Colors.white24,
            width: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tile['icon'] as IconData,
              color: isWin ? const Color(0xFFFFD700) : Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              isWin ? "REWARD UNLOCKED!" : "EMPTY TILE",
              style: TextStyle(
                color: isWin ? const Color(0xFFFFD700) : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Landed on: ${tile['label']}",
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              isWin ? "+$winAmount Coins" : "Better luck next roll!",
              style: TextStyle(
                color: isWin ? const Color(0xFF00E676) : Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: uid.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : null,
      builder: (context, snapshot) {
        final userData = (snapshot.hasData && snapshot.data!.exists)
            ? snapshot.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        final int liveCoins = (userData['coins'] as num?)?.toInt() ?? 0;

        return Container(
          height: 620,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Top drag bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

// Title and Live Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sailing, color: Color(0xFF00C9A7), size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Lucky Island",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "$liveCoins",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Winner Ticker Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.campaign, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _isRolling
                          ? "Rolling the dice..."
                          : "Last Rolled: $_lastDiceResult Step${_lastDiceResult > 1 ? 's' : ''}",
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4x4 Island Map Board (16 Tiles)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _boardTiles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, idx) {
                      final tile = _boardTiles[idx];
                      final bool isCurrent = _currentTileIndex == idx;
                      final String type = tile['type'];

                      Color tileBg = Colors.white.withOpacity(0.06);
                      Color borderColor = Colors.white10;
                      Color iconColor = Colors.amber;

if (type == "start") {
                        iconColor = const Color(0xFF00C9A7);
                      } else if (type == "trap" || type == "empty") {
                        iconColor = Colors.redAccent.withOpacity(0.8);
                      } else if (type == "jackpot" || type == "lucky") {
                        iconColor = const Color(0xFFFFD700);
                      }

                      if (isCurrent) {
                        tileBg = const Color(0xFF00C9A7).withOpacity(0.35);
                        borderColor = const Color(0xFF00C9A7);
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: borderColor,
                            width: isCurrent ? 2.0 : 1.0,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00C9A7).withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isCurrent)
                                const Icon(Icons.navigation, color: Colors.white, size: 14)
                              else
                                Icon(tile['icon'] as IconData, color: iconColor, size: 18),
                              const SizedBox(height: 2),
                              Text(
                                tile['label'] as String,
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : Colors.white60,
                                  fontSize: 9,
                                  fontWeight:
                                      isCurrent ? FontWeight.bold : FontWeight.normal,
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
              const SizedBox(height: 12),

              // Bet Selector Options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _betOptions.map((amount) {
                  final isSel = _selectedBet == amount;
                  return GestureDetector(
                    onTap: _isRolling ? null : () => setState(() => _selectedBet = amount),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF00C9A7) : Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? Colors.white : Colors.white24,
                        ),
                      ),
                      child: Text(
                        "🪙 $amount",
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

// Roll Dice Execution Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isRolling ? null : () => _rollDice(liveCoins),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RotationTransition(
                        turns: _diceRotation,
                        child: const Icon(Icons.casino, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRolling ? "ROLLING..." : "ROLL DICE (🪙 $_selectedBet)",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}
