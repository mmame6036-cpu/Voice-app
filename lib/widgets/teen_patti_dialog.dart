import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class CardItem {
  final String value;
  final String suit;
  final Color suitColor;
  final int rank;

  const CardItem({
    required this.value,
    required this.suit,
    required this.suitColor,
    required this.rank,
  });
}

class HandResult {
  final List<CardItem> cards;
  final String resultName;
  final int score;

  const HandResult({
    required this.cards,
    required this.resultName,
    required this.score,
  });
}

class TeenPattiDialog extends StatefulWidget {
  final int currentCoins;
  final Function(int) onCoinsUpdated;

  const TeenPattiDialog({
    super.key,
    required this.currentCoins,
    required this.onCoinsUpdated,
  });

  @override
  State<TeenPattiDialog> createState() => _TeenPattiDialogState();
}

class _TeenPattiDialogState extends State<TeenPattiDialog> {
  late int _coins;
  int _selectedChip = 3000;
  int _betA = 0;
  int _betB = 0;
  int _betC = 0;

  int _potA = 6000;
  int _potB = 18000;
  int _potC = 480000;

  bool _isDealing = false;
  String? _winningSide;

  List<CardItem> _cardsA = [];
  List<CardItem> _cardsB = [];
  List<CardItem> _cardsC = [];

  String _resultA = "High card";
  String _resultB = "Pair";
  String _resultC = "High card";

  final List<int> _chipOptions = [3000, 30000, 300000, 600000];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _initDefaultCards();
  }

  void _initDefaultCards() {
    _cardsA = const [
      CardItem(value: "6", suit: "♠", suitColor: Colors.black87, rank: 6),
      CardItem(value: "J", suit: "♠", suitColor: Colors.black87, rank: 11),
      CardItem(value: "4", suit: "♣", suitColor: Colors.black87, rank: 4),
    ];
    _cardsB = const [
      CardItem(value: "3", suit: "♥", suitColor: Colors.red, rank: 3),
      CardItem(value: "Q", suit: "♦", suitColor: Colors.red, rank: 12),
      CardItem(value: "3", suit: "♣", suitColor: Colors.black87, rank: 3),
    ];
    _cardsC = const [
      CardItem(value: "5", suit: "♠", suitColor: Colors.black87, rank: 5),
      CardItem(value: "8", suit: "♥", suitColor: Colors.red, rank: 8),
      CardItem(value: "4", suit: "♦", suitColor: Colors.red, rank: 4),
    ];
  }

  void _placeBet(String side) {
    if (_isDealing) return;
    if (_coins < _selectedChip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins to bet!")),
      );
      return;
    }

    setState(() {
      _coins -= _selectedChip;
      if (side == "A") {
        _betA += _selectedChip;
        _potA += _selectedChip;
      } else if (side == "B") {
        _betB += _selectedChip;
        _potB += _selectedChip;
      } else if (side == "C") {
        _betC += _selectedChip;
        _potC += _selectedChip;
      }
    });
    widget.onCoinsUpdated(_coins);
  }

  CardItem _generateRandomCard(Random r) {
    final suits = [
      {"symbol": "♠", "color": Colors.black87},
      {"symbol": "♥", "color": Colors.red},
      {"symbol": "♣", "color": Colors.black87},
      {"symbol": "♦", "color": Colors.red},
    ];
    final values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"];
    final valIdx = r.nextInt(values.length);
    final suitObj = suits[r.nextInt(suits.length)];

    return CardItem(
      value: values[valIdx],
      suit: suitObj["symbol"] as String,
      suitColor: suitObj["color"] as Color,
      rank: valIdx + 2,
    );
  }

  HandResult _evaluateHand(List<CardItem> cards) {
    final ranks = cards.map((c) => c.rank).toList()..sort();
    final suits = cards.map((c) => c.suit).toList();
    final isFlush = (suits[0] == suits[1] && suits[1] == suits[2]);
    final isStraight = (ranks[2] - ranks[1] == 1 && ranks[1] - ranks[0] == 1);
    final isTrail = (ranks[0] == ranks[1] && ranks[1] == ranks[2]);
    final isPair = (ranks[0] == ranks[1] || ranks[1] == ranks[2] || ranks[0] == ranks[2]);

if (isTrail) {
      return HandResult(cards: cards, resultName: "Trail / Set", score: 5000 + ranks[2]);
    } else if (isStraight && isFlush) {
      return HandResult(cards: cards, resultName: "Pure Sequence", score: 4000 + ranks[2]);
    } else if (isStraight) {
      return HandResult(cards: cards, resultName: "Sequence", score: 3000 + ranks[2]);
    } else if (isFlush) {
      return HandResult(cards: cards, resultName: "Color / Flush", score: 2000 + ranks[2]);
    } else if (isPair) {
      return HandResult(cards: cards, resultName: "Pair", score: 1000 + ranks[1]);
    } else {
      return HandResult(cards: cards, resultName: "High card", score: ranks[2]);
    }
  }

  void _startRound() {
    if (_betA == 0 && _betB == 0 && _betC == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please place a bet on A, B, or C first!")),
      );
      return;
    }

    setState(() {
      _isDealing = true;
      _winningSide = null;
    });

    final random = Random();

    Timer(const Duration(milliseconds: 1600), () {
      final handA = _evaluateHand(List.generate(3, (_) => _generateRandomCard(random)));
      final handB = _evaluateHand(List.generate(3, (_) => _generateRandomCard(random)));
      final handC = _evaluateHand(List.generate(3, (_) => _generateRandomCard(random)));

      String winner = "A";
      int maxScore = handA.score;

      if (handB.score > maxScore) {
        winner = "B";
        maxScore = handB.score;
      }
      if (handC.score > maxScore) {
        winner = "C";
      }

      int winnings = 0;
      if (winner == "A" && _betA > 0) winnings += (_betA * 2.8).toInt();
      if (winner == "B" && _betB > 0) winnings += (_betB * 2.8).toInt();
      if (winner == "C" && _betC > 0) winnings += (_betC * 2.8).toInt();

      setState(() {
        _cardsA = handA.cards;
        _resultA = handA.resultName;
        _cardsB = handB.cards;
        _resultB = handB.resultName;
        _cardsC = handC.cards;
        _resultC = handC.resultName;
        _winningSide = winner;
        _isDealing = false;
        _coins += winnings;
        _betA = 0;
        _betB = 0;
        _betC = 0;
      });

      widget.onCoinsUpdated(_coins);

      if (winnings > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Text("Winner is $winner! You won $winnings Coins!"),
          ),
        );
      }
    });
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return "${(num / 1000000).toStringAsFixed(2)}M";
    if (num >= 1000) return "${(num / 1000).toStringAsFixed(0)}K";
    return "$num";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 640,
      decoration: const BoxDecoration(
        color: Color(0xFFE8B270),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFD49955),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "TeenPatti",
                  style: TextStyle(
                    color: Color(0xFFFFF3DB),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,

shadows: [
                      Shadow(color: Color(0xFF7A4512), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _topSmallIcon(Icons.people),
                    const SizedBox(width: 8),
                    _topSmallIcon(Icons.volume_up),
                    const SizedBox(width: 8),
                    _topSmallIcon(Icons.help_outline),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _avatarWidget("xkecu...", "👦"),
                _avatarWidget("white...", "😎"),
                _avatarWidget("vân", "👮"),
                _avatarWidget("Tuan...", "🧢"),
                _avatarWidget("Tuan...", "⚪"),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _bettingBox(
                      label: "A",
                      color: const Color(0xFF00A859),
                      chairIcon: "🛋️",
                      pot: _potA,
                      userBet: _betA,
                      cards: _cardsA,
                      result: _resultA,
                      isWinner: _winningSide == "A",
                      onTap: () => _placeBet("A"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bettingBox(
                      label: "B",
                      color: const Color(0xFF0091DA),
                      chairIcon: "🛋️",
                      pot: _potB,
                      userBet: _betB,
                      cards: _cardsB,
                      result: _resultB,
                      isWinner: _winningSide == "B",
                      onTap: () => _placeBet("B"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bettingBox(
                      label: "C",
                      color: const Color(0xFFD63031),
                      chairIcon: "🛋️",
                      pot: _potC,
                      userBet: _betC,
                      cards: _cardsC,
                      result: _resultC,
                      isWinner: _winningSide == "C",
                      onTap: () => _placeBet("C"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFDCA15D),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4F1B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _chipOptions.map((chip) {
                        final isSelected = _selectedChip == chip;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedChip = chip),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getChipColor(chip),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.black26,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.transparent,
                              child: Text(
                                _formatNumber(chip),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5AB6D8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: _isDealing ? null : _startRound,
                  child: Text(
                    _isDealing ? "Dealing..." : "Deal",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getChipColor(int chip) {
    if (chip == 3000) return const Color(0xFF68D8D6);
    if (chip == 30000) return const Color(0xFF7AE582);
    if (chip == 300000) return const Color(0xFF00B4D8);
    return const Color(0xFFFFAA00);
  }

  Widget _topSmallIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Color(0xFF8B4F1B),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _avatarWidget(String name, String emoji) {
    return Column(
      children: [
        CircleAvatar(

radius: 16,
          backgroundColor: const Color(0xFFF7D08A),
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(height: 2),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _bettingBox({
    required String label,
    required Color color,
    required String chairIcon,
    required int pot,
    required int userBet,
    required List<CardItem> cards,
    required String result,
    required bool isWinner,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWinner ? const Color(0xFFFFD700) : Colors.white24,
            width: isWinner ? 3.5 : 1.2,
          ),
          boxShadow: isWinner
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.7),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                "POT: ${_formatNumber(pot)}",
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "You: $userBet",
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: cards.map((c) {
                  return Column(
                    children: [
                      Text(
                        c.value,
                        style: TextStyle(
                          color: c.suitColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        c.suit,
                        style: TextStyle(color: c.suitColor, fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                result,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withOpacity(0.25),

child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
