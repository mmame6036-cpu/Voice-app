import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

bool _gt(num a, num b) {
  return a.compareTo(b).sign == 1;
}

bool _lt(num a, num b) {
  return a.compareTo(b).sign == -1;
}

bool _gte(num a, num b) {
  return a.compareTo(b).sign != -1;
}

bool _lte(num a, num b) {
  return a.compareTo(b).sign != 1;
}

dynamic _d(Object? v) {
  return v;
}

class _TpCard {
  final int rank; // 2..14 (14 = A)
  final String suit; // 'S', 'H', 'D', 'C'

  const _TpCard({required this.rank, required this.suit});
}

class _TpHandEval {
  final int category; // 6=Trail, 5=PureSeq, 4=Seq, 3=Color, 2=Pair, 1=HighCard
  final String label;
  final int score;

  const _TpHandEval({
    required this.category,
    required this.label,
    required this.score,
  });
}

class _SpotChip {
  final int value;
  final double dx;
  final double dy;

  const _SpotChip({
    required this.value,
    required this.dx,
    required this.dy,
  });
}

class _FlyingTpChip {
  final int id;
  final int value;
  final double startX;
  final double targetX;

  const _FlyingTpChip({
    required this.id,
    required this.value,
    required this.startX,
    required this.targetX,
  });
}

class TeenPattiSheet {
  static Future show(
    BuildContext context, {
    int currentCoins = 0,
    Function(int)? onCoinsUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return TeenPattiDialog(
          currentCoins: currentCoins,
          onCoinsUpdated: onCoinsUpdated ?? (_) {},
        );
      },
    );
  }
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
  State createState() {
    return _TeenPattiDialogState();
  }
}

class _TeenPattiDialogState extends State with TickerProviderStateMixin {
  TeenPattiDialog get _w {
    return widget as TeenPattiDialog;
  }

  final User? _user = FirebaseAuth.instance.currentUser;
  final Random _rng = Random();

  static const List _chipValues = [1000, 10000, 30000, 50000];
  static const List _spotTitles = ["Kebab", "Matcha", "Cake"];
  static const List _spotEmojis = ["🍢", "🍵", "🍰"];

  int _selectedChipIndex = 0;
  late int _coins;
  int _roundNo = 1418;

  // Phases: "ABOUT_TO_START", "GUESSING", "REVEAL"
  String _phase = "ABOUT_TO_START";
  int _secondsLeft = 3;
  bool _soundOn = true;

  final List _pots = [0, 0, 0];
  final List _myBets = [0, 0, 0];
  final List _lastBets = [0, 0, 0];

  final List _spotChips = [[], [], []];
  final List _flyingChips = [];
  int _flySeq = 0;

  List _spotHands = [[], [], []];
  List _spotEvals = [null, null, null];
  int _winnerSpot = -1;
  int _lastWinAmount = 0;

  final List _recentWinners = [2, 0, 2, 1, 2];
  final List _leaderboard = [
    {"name": "Kedir FAMS", "win": 435000},
    {"name": "Silent👑", "win": 290000},
    {"name": "VIP6_Megan", "win": 145000},
    {"name": "Agent_Joy", "win": 87000},
  ];

  Timer? _roundTimer;
  late AnimationController _winGlowCtrl;

  @override
  void initState() {
    super.initState();
    _coins = _w.currentCoins;
    _winGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _syncInitialCoins();
    _startRoundCycle();
  }

  Future _syncInitialCoins() async {
    final user = _user;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')

.doc(user.uid)
          .get();
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      if (!mounted) return;
      setState(() {
        _coins = (data['coins'] as num?)?.toInt() ?? _coins;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _winGlowCtrl.dispose();
    super.dispose();
  }

  void _startRoundCycle() {
    _roundTimer?.cancel();
    if (!mounted) return;

    final int prevTotal = (_myBets[0] as int) +
        (_myBets[1] as int) +
        (_myBets[2] as int);
    if (_gt(prevTotal, 0)) {
      _lastBets[0] = _myBets[0];
      _lastBets[1] = _myBets[1];
      _lastBets[2] = _myBets[2];
    }

    setState(() {
      _phase = "ABOUT_TO_START";
      _secondsLeft = 3;
      _winnerSpot = -1;
      _lastWinAmount = 0;
      _pots[0] = 0;
      _pots[1] = 0;
      _pots[2] = 0;
      _myBets[0] = 0;
      _myBets[1] = 0;
      _myBets[2] = 0;
      (_spotChips[0] as List).clear();
      (_spotChips[1] as List).clear();
      (_spotChips[2] as List).clear();
      _flyingChips.clear();
      _spotHands = [[], [], []];
      _spotEvals = [null, null, null];
    });

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_gt(_secondsLeft, 1)) {
        setState(() {
          _secondsLeft -= 1;
        });
      } else {
        t.cancel();
        _enterGuessingStage();
      }
    });
  }

  void _enterGuessingStage() {
    if (!mounted) return;
    setState(() {
      _phase = "GUESSING";
      _secondsLeft = 15;
    });

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_gt(_secondsLeft, 1)) {
        setState(() {
          _secondsLeft -= 1;
          _simulateRoomBets();
        });
      } else {
        t.cancel();
        _revealCardsAndSettle();
      }
    });
  }

  void _simulateRoomBets() {
    final samples = [1000, 1000, 10000, 30000];
    for (int spot = 0; _lt(spot, 3); spot++) {
      if (_rng.nextBool()) {
        final int addAmt = (samples[_rng.nextInt(samples.length)] as num).toInt();
        _pots[spot] = (_pots[spot] as int) + addAmt;
        _spawnChipFlight(spot, addAmt, fromBot: true);
      }
    }
  }

  void _spawnChipFlight(int spotIndex, int chipVal, {bool fromBot = false}) {
    if (!mounted) return;
    _flySeq += 1;
    final int id = _flySeq;

    double targetX = 0.0;
    if (spotIndex == 0) targetX = -0.66;
    if (spotIndex == 2) targetX = 0.66;

    double startX = -0.45 + (_selectedChipIndex * 0.22);
    if (fromBot) {
      startX = _rng.nextBool() ? -0.92 : 0.92;
    }

    final fly = _FlyingTpChip(
      id: id,
      value: chipVal,
      startX: startX,
      targetX: targetX,
    );

    setState(() {
      _flyingChips.add(fly);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _flyingChips.removeWhere((item) {
          return (item as _FlyingTpChip).id == id;
        });
        final list = _spotChips[spotIndex] as List;
        list.add(_SpotChip(
          value: chipVal,
          dx: (_rng.nextDouble() * 46) - 23,
          dy: (_rng.nextDouble() * 20) - 10,
        ));
        if (_gt(list.length, 24)) {
          list.removeAt(0);
        }
      });
    });
  }

  Future _placeBetOnSpot(int spotIndex, {int? overrideAmount}) async {
    if (_phase != "GUESSING") {
      _showToast("Wait for Guessing Stage to place bets.");
      return;
    }

    final int betVal =
        overrideAmount ?? (_chipValues[_selectedChipIndex] as num).toInt();
    if (_lt(_coins, betVal)) {
      _showToast("Insufficient coins! Please recharge.");
      return;
    }

    if (_soundOn) {
      HapticFeedback.lightImpact();
    }

    _spawnChipFlight(spotIndex, betVal);

setState(() {
      _coins -= betVal;
      _myBets[spotIndex] = (_myBets[spotIndex] as int) + betVal;
      _pots[spotIndex] = (_pots[spotIndex] as int) + betVal;
    });

    _w.onCoinsUpdated(_coins);
    await _updateFirestoreCoins(-betVal);
  }

  Future _repeatLastBets() async {
    if (_phase != "GUESSING") {
      _showToast("Repeat is available during Guessing Stage.");
      return;
    }
    final int needed = (_lastBets[0] as int) +
        (_lastBets[1] as int) +
        (_lastBets[2] as int);
    if (_lte(needed, 0)) {
      _showToast("No previous bets to repeat.");
      return;
    }
    if (_lt(_coins, needed)) {
      _showToast("Insufficient coins to repeat.");
      return;
    }

    for (int i = 0; _lt(i, 3); i++) {
      final int b = _lastBets[i] as int;
      if (_gt(b, 0)) {
        await _placeBetOnSpot(i, overrideAmount: b);
      }
    }
  }

  Future _updateFirestoreCoins(int delta) async {
    final user = _user;
    if (user == null) return;
    if (delta == 0) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'coins': _d(FieldValue.increment(delta))}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _revealCardsAndSettle() async {
    if (!mounted) return;

    // Deal 9 unique cards from a standard 52-card deck
    final List deck = [];
    const suits = ['S', 'H', 'D', 'C'];
    for (final s in suits) {
      for (int r = 2; _lte(r, 14); r++) {
        deck.add(_TpCard(rank: r, suit: s));
      }
    }
    deck.shuffle(_rng);

    final List h0 = [deck[0], deck[1], deck[2]];
    final List h1 = [deck[3], deck[4], deck[5]];
    final List h2 = [deck[6], deck[7], deck[8]];

    final e0 = _evaluateHand(h0);
    final e1 = _evaluateHand(h1);
    final e2 = _evaluateHand(h2);

    int bestSpot = 0;
    int bestScore = e0.score;
    if (_gt(e1.score, bestScore)) {
      bestSpot = 1;
      bestScore = e1.score;
    }
    if (_gt(e2.score, bestScore)) {
      bestSpot = 2;
      bestScore = e2.score;
    }

    final int myWinningBet = _myBets[bestSpot] as int;
    int wonCoins = 0;
    if (_gt(myWinningBet, 0)) {
      wonCoins = (myWinningBet * 2.9).round();
    }

    setState(() {
      _phase = "REVEAL";
      _spotHands = [h0, h1, h2];
      _spotEvals = [e0, e1, e2];
      _winnerSpot = bestSpot;
      _lastWinAmount = wonCoins;
      _coins += wonCoins;

      _recentWinners.insert(0, bestSpot);
      if (_gt(_recentWinners.length, 5)) {
        _recentWinners.removeLast();
      }
    });

    if (_gt(wonCoins, 0)) {
      _w.onCoinsUpdated(_coins);
      await _updateFirestoreCoins(wonCoins);
      _showToast("You won +$wonCoins Coins!");
    }

    // Hold reveal & golden winner glow for 6 seconds, then start next round
    _roundTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      _roundNo += 1;
      _startRoundCycle();
    });
  }

  _TpHandEval _evaluateHand(List cards) {
    final List sorted = List.of(cards);
    sorted.sort((a, b) {
      final ca = a as _TpCard;
      final cb = b as _TpCard;
      return cb.rank.compareTo(ca.rank);
    });

    final int r0 = (sorted[0] as _TpCard).rank;
    final int r1 = (sorted[1] as _TpCard).rank;
    final int r2 = (sorted[2] as _TpCard).rank;

    final String s0 = (sorted[0] as _TpCard).suit;
    final String s1 = (sorted[1] as _TpCard).suit;
    final String s2 = (sorted[2] as _TpCard).suit;

    final bool isFlush = (s0 == s1) && (s1 == s2);

    bool isSeq = false;
    int seqTop = r0;
    if (r0 - 1 == r1) {
      if (r1 - 1 == r2) {
        isSeq = true;
      }
    }
    // A-2-3 special sequence
    if (r0 == 14) {
      if (r1 == 3) {
        if (r2 == 2) {
          isSeq = true;
          seqTop = 13;
        }
      }
    }

    // 1. Trail (Three of a kind)
    if (r0 == r1 && r1 == r2) {
      return _TpHandEval(
        category: 6,
        label: "Trail",
        score: 6000000 + (r0 * 10000),
      );
    }

// 2. Pure Sequence (Straight Flush)
    if (isFlush && isSeq) {
      return _TpHandEval(
        category: 5,
        label: "Pure Sequence",
        score: 5000000 + (seqTop * 10000),
      );
    }

    // 3. Sequence (Straight)
    if (isSeq) {
      return _TpHandEval(
        category: 4,
        label: "Sequence",
        score: 4000000 + (seqTop * 10000),
      );
    }

    // 4. Color (Flush)
    if (isFlush) {
      return _TpHandEval(
        category: 3,
        label: "Color",
        score: 3000000 + (r0 * 400) + (r1 * 20) + r2,
      );
    }

    // 5. Pair
    if (r0 == r1) {
      return _TpHandEval(
        category: 2,
        label: "Pair",
        score: 2000000 + (r0 * 400) + r2,
      );
    }
    if (r1 == r2) {
      return _TpHandEval(
        category: 2,
        label: "Pair",
        score: 2000000 + (r1 * 400) + r0,
      );
    }

    // 6. High Card
    return _TpHandEval(
      category: 1,
      label: "High Card",
      score: 1000000 + (r0 * 400) + (r1 * 20) + r2,
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A2511),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatChip(int val) {
    if (_gte(val, 1000000)) {
      return "${(val / 1000000).toStringAsFixed(1)}M";
    }
    if (_gte(val, 1000)) {
      return "${val ~/ 1000}K";
    }
    return "$val";
  }

  String _rankStr(int rank) {
    if (rank == 14) return "A";
    if (rank == 13) return "K";
    if (rank == 12) return "Q";
    if (rank == 11) return "J";
    return "$rank";
  }

  String _suitStr(String suit) {
    if (suit == 'H') return "♥";
    if (suit == 'D') return "♦";
    if (suit == 'C') return "♣";
    return "♠";
  }

  Color _chipColor(int val) {
    if (_gte(val, 50000)) return const Color(0xFFDB2777);
    if (_gte(val, 30000)) return const Color(0xFF7C3AED);
    if (_gte(val, 10000)) return const Color(0xFF2563EB);
    return const Color(0xFF16A34A);
  }

  void _openRulesSheet() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8EE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFD97706), width: 2),
          ),
          title: const Text(
            "TeenPatti Rules",
            style: TextStyle(
                color: Color(0xFF4A2511), fontWeight: FontWeight.w900),
          ),
          content: const Text(
            "1. Choose a chip (1K, 10K, 30K, 50K) and tap any of the 3 spots during the 15s Guessing Stage.\n\n"
            "2. Each spot receives 3 cards. Highest TeenPatti hand wins (2.9x Payout):\n"
            "   • Trail (Three of a Kind)\n"
            "   • Pure Sequence (Straight Flush)\n"
            "   • Sequence (Straight)\n"
            "   • Color (Flush)\n"
            "   • Pair\n"
            "   • High Card",
            style: TextStyle(
                color: Color(0xFF3E2723), fontSize: 12.5, height: 1.45),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("OK",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openLeaderboardSheet() {
    showDialog(

context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8EE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFD97706), width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                "Today's Top Winners",
                style: TextStyle(
                    color: Color(0xFF4A2511),
                    fontSize: 16,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_leaderboard.length, (i) {
              final row = _leaderboard[i] as Map;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "#${i + 1}  ${row['name']}",
                      style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5),
                    ),
                    Text(
                      "+${row['win']}",
                      style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5),
                    ),
                  ],
                ),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("Close",
                  style: TextStyle(
                      color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCountdownPhase =
        _phase == "ABOUT_TO_START" || _phase == "GUESSING";

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF8C5327),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Top Illustrated TeenPatti Banner (Coins + 3 Aces + Logo + Teapot)
                  _buildTopTeenPattiBanner(),

                  // 2. Round Number Strip (NO.1418 + Collapse Arrow)
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFC07A3E),
                          Color(0xFF9C5D28),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

children: [
                        Text(
                          "NO.$_roundNo",
                          style: const TextStyle(
                            color: Color(0xFFFFFBEB),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFFFFFBEB),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Emerald Felt Table Container
                  Container(
                    margin: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Color(0xFF238263),
                          Color(0xFF155741),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFD99B52), width: 1.8),
                    ),
                    child: Column(
                      children: [
                        // History Row (NEW + 5 Winner Icons) & 3 Red Action Buttons
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFACC15),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "NEW",
                                style: TextStyle(
                                  color: Color(0xFF451A03),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 28,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _recentWinners.length,
                                  itemBuilder: (_, idx) {
                                    final int spotIdx =
                                        (_recentWinners[idx] as num).toInt();
                                    return Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.only(right: 5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,

color: const Color(0xFFFFF7ED),
                                        border: Border.all(
                                          color: idx == 0
                                              ? const Color(0xFFFACC15)
                                              : const Color(0xFFD97706),
                                          width: idx == 0 ? 1.8 : 1.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _spotEmojis[spotIdx].toString(),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            _redCircleBtn(
                              Icons.emoji_events_rounded,
                              _openLeaderboardSheet,
                            ),
                            const SizedBox(width: 6),
                            _redCircleBtn(
                              _soundOn
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              () {
                                setState(() {
                                  _soundOn = !_soundOn;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _redCircleBtn(
                              Icons.question_mark_rounded,
                              _openRulesSheet,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 3 Betting Columns + Center Countdown Pill
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              children: List.generate(3, (spotIndex) {
                                return Expanded(
                                  child: _buildSpotColumn(spotIndex),
                                );
                              }),
                            ),

                            // Center Countdown Pill ("About To Start" / "Guessing Stage")
                            if (isCountdownPhase)
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 6, 8, 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.74),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: const Color(0xFFFACC15),
                                      width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _phase == "ABOUT_TO_START"
                                          ? "About To Start"
                                          : "Guessing Stage",
                                      style: const TextStyle(
                                        color: Color(0xFFFEF08A),
                                        fontSize: 15,

fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const RadialGradient(
                                          colors: [
                                            Color(0xFFFEF08A),
                                            Color(0xFFD97706),
                                          ],
                                        ),
                                        border: Border.all(
                                            color: Colors.white, width: 1.4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "$_secondsLeft",
                                          style: const TextStyle(
                                            color: Color(0xFF451A03),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Bottom Wood Control Bar (Coins + 4 Chips + Repeat)
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFA86432),
                          Color(0xFF78421B),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        // User Coin Balance Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A2511),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: const Color(0xFFFACC15), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: Color(0xFFFACC15), size: 17),
                              const SizedBox(width: 5),
                              Text(
                                "$_coins",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

// 4 Selectable Casino Chips (1K, 10K, 30K, 50K)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_chipValues.length, (i) {
                              final int val = (_chipValues[i] as num).toInt();
                              final bool selected = _selectedChipIndex == i;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedChipIndex = i;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  width: selected ? 44 : 38,
                                  height: selected ? 44 : 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _chipColor(val),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFFEF08A)
                                          : Colors.white,
                                      width: selected ? 2.6 : 1.6,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFACC15)
                                                  .withOpacity(0.75),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: selected ? 32 : 27,
                                      height: selected ? 32 : 27,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white54,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _formatChip(val),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Repeat Button
                        GestureDetector(
                          onTap: _repeatLastBets,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),

decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFEF3C7),
                                  Color(0xFFF59E0B),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: const Color(0xFFFFFBEB), width: 1.4),
                            ),
                            child: const Text(
                              "Repeat",
                              style: TextStyle(
                                color: Color(0xFF5C2D0C),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Flying Casino Chips Overlay
              ..._flyingChips.map((rawFly) {
                final f = rawFly as _FlyingTpChip;
                return TweenAnimationBuilder(
                  key: ValueKey("tp_fly_${f.id}"),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 290),
                  curve: Curves.easeOutCubic,
                  builder: (context, rawT, child) {
                    final double t = (rawT as num).toDouble();
                    final double curX =
                        f.startX + ((f.targetX - f.startX) * t);
                    final double curY = 0.88 - (0.36 * t);
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment(curX, curY),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _chipColor(f.value),
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopTeenPattiBanner() {
    return Container(
      height: 86,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFD9F99D),
            Color(0xFFFEF3C7),
            Color(0xFFFDE68A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Gold Coins Stack Art
          const Positioned(
            left: 12,
            bottom: 6,
            child: Row(
              children: [
                Icon(Icons.monetization_on,
                    color: Color(0xFFF59E0B), size: 34),
                Icon(Icons.monetization_on,
                    color: Color(0xFFD97706), size: 26),
              ],
            ),
          ),

          // Right Porcelain Teapot & Flower Art
          const Positioned(
            right: 14,
            bottom: 8,
            child: Row(
              children: [
                Icon(Icons.local_florist_rounded,
                    color: Color(0xFFEC4899), size: 24),
                SizedBox(width: 2),
                Icon(Icons.emoji_food_beverage_rounded,
                    color: Color(0xFF0D9488), size: 36),
              ],
            ),
          ),

// Center Fanned 3 Aces + Bold TeenPatti Logo
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _miniAceBadge("A♣", Colors.black87, -0.18),
                  _miniAceBadge("A♠", Colors.black, 0.0),
                  _miniAceBadge("A♥", const Color(0xFFDC2626), 0.18),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF78350F), Color(0xFF451A03)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFFACC15), width: 1.6),
                ),
                child: const Text(
                  "TeenPatti",
                  style: TextStyle(
                    color: Color(0xFFFEF08A),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniAceBadge(String text, Color color, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 24,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD97706), width: 1),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _redCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFF87171), Color(0xFFDC2626)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFFEF08A), width: 1.2),
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }

  Widget _buildSpotColumn(int spotIndex) {
    final int potVal = (_pots[spotIndex] as num).toInt();
    final int myVal = (_myBets[spotIndex] as num).toInt();
    final List landed = _spotChips[spotIndex] as List;
    final bool isWinner = _phase == "REVEAL" && _winnerSpot == spotIndex;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _placeBetOnSpot(spotIndex);
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedBuilder(
            animation: _winGlowCtrl,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.fromLTRB(3, 18, 3, 0),
                padding: const EdgeInsets.fromLTRB(4, 22, 4, 6),
                decoration: BoxDecoration(
                  color: isWinner
                      ? const Color(0xFF1F7A5B)
                      : const Color(0xFF134E3A).withOpacity(0.82),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWinner
                        ? const Color(0xFFFEF08A)

: const Color(0xFFD99B52).withOpacity(0.65),
                    width: isWinner ? 2.8 : 1.3,
                  ),
                  boxShadow: isWinner
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFACC15)
                                .withOpacity(0.45 + (_winGlowCtrl.value * 0.4)),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: child,
              );
            },
            child: Column(
              children: [
                // POT Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E3B2C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "POT: $potVal",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFEF08A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),

                // You: X Banner
                Text(
                  "You: $myVal",
                  style: TextStyle(
                    color: _gt(myVal, 0)
                        ? const Color(0xFF4ADE80)
                        : Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // 3 Cards Area (Face Down or Revealed with Hand Rank)
                _buildThreeCardsRow(spotIndex),

                const SizedBox(height: 6),

                // Chips Tray Area
                SizedBox(
                  height: 38,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isWinner)
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFEF08A),
                          size: 26,
                        ),
                      ...landed.map((rawC) {
                        final c = rawC as _SpotChip;
                        return Transform.translate(
                          offset: Offset(c.dx, c.dy),
                          child: Container(
                            width: 17,
                            height: 17,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _chipColor(c.value),
                              border:
                                  Border.all(color: Colors.white, width: 1.0),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top Circular Food/Drink Emblem (Kebab, Matcha Tea, Cake)
          Positioned(
            top: 0,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFFBEB),

Color(0xFFFDE68A),
                  ],
                ),
                border: Border.all(
                  color: isWinner
                      ? const Color(0xFFFEF08A)
                      : const Color(0xFFD97706),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _spotEmojis[spotIndex].toString(),
                  style: const TextStyle(fontSize: 19),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeCardsRow(int spotIndex) {
    final bool revealed = _phase == "REVEAL";
    final List cards = _spotHands[spotIndex] as List;
    final _TpHandEval? eval = _spotEvals[spotIndex] as _TpHandEval?;

    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (cIdx) {
              if (!revealed || _lt(cards.length, 3)) {
                return Container(
                  width: 28,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                            color: const Color(0xFFFCA5A5), width: 0.7),
                      ),
                    ),
                  ),
                );
              }

              final card = cards[cIdx] as _TpCard;
              final bool isRed = card.suit == 'H' || card.suit == 'D';
              final Color ink =
                  isRed ? const Color(0xFFDC2626) : const Color(0xFF111827);

              return Container(
                width: 30,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: const Color(0xFFD1D5DB), width: 0.9),
                ),
                child: Column(
                  children: [
                    Text(
                      _rankStr(card.rank),
                      style: TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      _suitStr(card.suit),
                      style: TextStyle(
                        color: ink,
                        fontSize: 11,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Hand Rank Ribbon ("High Card", "Pair", "Sequence", "Trail", etc.)
          if (revealed && eval != null)
            Positioned(
              bottom: 0,
              child: Container(

padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _winnerSpot == spotIndex
                        ? [const Color(0xFFF59E0B), const Color(0xFFB45309)]
                        : [const Color(0xFF991B1B), const Color(0xFF7F1D1D)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFFEF08A), width: 1.0),
                ),
                child: Text(
                  eval.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
