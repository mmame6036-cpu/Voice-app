import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class CardItem {
  final String suit; // ♠, ♥, ♦, ♣
  final String rank; // 2..10, J, Q, K, A
  final int value;   // 2..14

  CardItem({required this.suit, required this.rank, required this.value});
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
  int _selectedChip = 100;
  final List<int> _chipValues = [50, 100, 500, 1000];

  int _betOnA = 0;
  int _betOnB = 0;

  Timer? _gameTimer;
  int _countdown = 15;
  bool _isDealing = false;
  String _gameResultText = "Place your bets on Player A or Player B!";

  List<CardItem> _handA = [];
  List<CardItem> _handB = [];

  final List<String> _suits = ["♠", "♥", "♦", "♣"];
  final List<String> _ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _startRound();
  }

  void _startRound() {
    _countdown = 15;
    _isDealing = false;
    _betOnA = 0;
    _betOnB = 0;
    _handA = [];
    _handB = [];
    _gameResultText = "Place your bets (15s)!";

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _gameTimer?.cancel();
        _resolveRound();
      }
    });
  }

  void _placeBet(String side) {
    if (_isDealing || _countdown == 0) return;
    if (_coins < _selectedChip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins to place bet!")),
      );
      return;
    }

    setState(() {
      _coins -= _selectedChip;
      if (side == "A") {
        _betOnA += _selectedChip;
      } else {
        _betOnB += _selectedChip;
      }
    });
    widget.onCoinsUpdated(_coins);
  }

  List<CardItem> _drawHand(Random rng) {
    List<CardItem> hand = [];
    for (int i = 0; i < 3; i++) {
      int valIndex = rng.nextInt(_ranks.length);
      int suitIndex = rng.nextInt(_suits.length);
      hand.add(CardItem(
        suit: _suits[suitIndex],
        rank: _ranks[valIndex],
        value: valIndex + 2,
      ));
    }
    hand.sort((a, b) => b.value.compareTo(a.value));
    return hand;
  }

  // Calculate hand score (Trio > Straight Flush > Flush > Straight > Pair > High Card)
  int _evaluateHand(List<CardItem> hand) {
    bool isFlush = hand[0].suit == hand[1].suit && hand[1].suit == hand[2].suit;
    bool isTrio = hand[0].value == hand[1].value && hand[1].value == hand[2].value;
    bool isStraight = (hand[0].value - hand[1].value == 1) && (hand[1].value - hand[2].value == 1);
    bool isPair = hand[0].value == hand[1].value || hand[1].value == hand[2].value || hand[0].value == hand[2].value;

    if (isTrio) return 60000 + hand[0].value;
    if (isFlush && isStraight) return 50000 + hand[0].value;
    if (isStraight) return 40000 + hand[0].value;
    if (isFlush) return 30000 + hand[0].value;
    if (isPair) {
      int pairVal = (hand[0].value == hand[1].value) ? hand[0].value : hand[1].value;
      return 20000 + pairVal;
    }
    return 10000 + hand[0].value * 100 + hand[1].value * 10 + hand[2].value;
  }

  void _resolveRound() {
    setState(() => _isDealing = true);
    final rng = Random();
    _handA = _drawHand(rng);
    _handB = _drawHand(rng);

    int scoreA = _evaluateHand(_handA);
    int scoreB = _evaluateHand(_handB);

    int winnings = 0;
    String outcome = "";

if (scoreA > scoreB) {
      outcome = "Player A Wins!";
      if (_betOnA > 0) winnings += (_betOnA * 2);
    } else if (scoreB > scoreA) {
      outcome = "Player B Wins!";
      if (_betOnB > 0) winnings += (_betOnB * 2);
    } else {
      outcome = "Tie Game! Bets returned.";
      winnings += (_betOnA + _betOnB);
    }

    if (winnings > 0) {
      _coins += winnings;
      widget.onCoinsUpdated(_coins);
      outcome += " You won 🪙$winnings!";
    }

    setState(() {
      _gameResultText = outcome;
    });

    // Start next round in 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _startRound();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: const BoxDecoration(
        color: Color(0xFF141226),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🃏 Teen Patti 3-Cards",
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
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
                    const Icon(Icons.timer, color: Color(0xFFFFD700), size: 14),
                    const SizedBox(width: 4),
                    Text("$_countdown s", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _gameResultText,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Cards Arena (Player A vs Player B)
          Row(
            children: [
              Expanded(child: _buildPlayerArena("Player A", _handA, Colors.blueAccent)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text("VS", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 18)),
              ),
              Expanded(child: _buildPlayerArena("Player B", _handB, Colors.purpleAccent)),
            ],
          ),

          const SizedBox(height: 14),

          // Betting Areas
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F284F),
                    side: const BorderSide(color: Colors.blueAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _placeBet("A"),
                  child: Column(
                    children: [

const Text("Bet Player A", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text("Bet: 🪙$_betOnA", style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF381F4F),
                    side: const BorderSide(color: Colors.purpleAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _placeBet("B"),
                  child: Column(
                    children: [
                      const Text("Bet Player B", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text("Bet: 🪙$_betOnB", style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Chips Selection & User Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 4),
                  Text("$_coins", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Row(
                children: _chipValues.map((val) {
                  final isSelected = _selectedChip == val;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedChip = val),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF221F3A),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700), width: isSelected ? 2 : 0.8),
                      ),
                      child: Text(
                        "$val",
                        style: TextStyle(
                          color: isSelected ? Colors.black : const Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPlayerArena(String name, List<CardItem> hand, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: hand.isEmpty
                ? [
                    _cardBack(),

const SizedBox(width: 4),
                    _cardBack(),
                    const SizedBox(width: 4),
                    _cardBack(),
                  ]
                : hand.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _cardFront(c),
                  )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _cardBack() {
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white30),
      ),
      child: const Center(child: Text("🂠", style: TextStyle(color: Colors.white60, fontSize: 16))),
    );
  }

  Widget _cardFront(CardItem c) {
    bool isRed = c.suit == "♥" || c.suit == "♦";
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(c.rank, style: TextStyle(color: isRed ? Colors.red : Colors.black, fontSize: 11, fontWeight: FontWeight.bold, height: 1.0)),
          Text(c.suit, style: TextStyle(color: isRed ? Colors.red : Colors.black, fontSize: 10, height: 1.0)),
        ],
      ),
    );
  }
}
