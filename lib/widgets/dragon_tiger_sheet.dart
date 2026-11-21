import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

enum _GamePhase {
  vsIntro,
  betting,
  drawing,
  settlement,
}

class _PlacedChip {
  final int amount;
  final double dx;
  final double dy;

  const _PlacedChip({
    required this.amount,
    required this.dx,
    required this.dy,
  });
}

class _VictorEntry {
  final String name;
  final int winAmount;
  final bool isMe;

  const _VictorEntry({
    required this.name,
    required this.winAmount,
    this.isMe = false,
  });
}

class DragonTigerDialog extends StatefulWidget {
  final int currentCoins;
  final Function(int) onCoinsUpdated;
  final String userName;
  final int userNumericId;

  const DragonTigerDialog({
    super.key,
    required this.currentCoins,
    required this.onCoinsUpdated,
    this.userName = "Player",
    this.userNumericId = 100001,
  });

  @override
  State createState() {
    return _DragonTigerDialogState();
  }
}

class _DragonTigerDialogState extends State with TickerProviderStateMixin {
  DragonTigerDialog get _w {
    return widget as DragonTigerDialog;
  }

  final User? _user = FirebaseAuth.instance.currentUser;
  final Random _rng = Random();

  late int _coins;
  int _roundNumber = 2144;
  _GamePhase _phase = _GamePhase.vsIntro;
  int _secondsLeft = 20;
  int _pingMs = 186;

  static const List _chipValues = [1000, 10000, 30000, 50000];
  int _selectedChipIndex = 0;

  int _potDragon = 0;
  int _potTie = 0;
  int _potTiger = 0;

  int _myDragonBet = 0;
  int _myTieBet = 0;
  int _myTigerBet = 0;

  int _lastDragonBet = 0;
  int _lastTieBet = 0;
  int _lastTigerBet = 0;

  final List _dragonChips = [];
  final List _tieChips = [];
  final List _tigerChips = [];

  int _dragonCard = 7;
  int _tigerCard = 1;
  bool _dragonCardRevealed = false;
  bool _tigerCardRevealed = false;
  String _roundWinner = "";
  int _myRoundWin = 0;

  final List _recentResults = [
    "Dragon",
    "Tiger",
    "Dragon",
    "Dragon",
    "Tiger",
    "Tie",
    "Dragon",
    "Tiger",
    "Dragon",
    "Tiger",
  ];

  final List _roundHistory = [];
  List _topVictors = [];

  Timer? _loopTimer;
  late AnimationController _pulseCtrl;

  static const List _botNames = [
    "حكيم",
    "PYIA🔥Anasvia",
    "مبارك",
    "محمد باديولا",
    "Silent👑",
    "Agent_Joy",
    "VIP6_Megan",
    "Murat_TR",
  ];

  @override
  void initState() {
    super.initState();
    _coins = _w.currentCoins;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startNewRound();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startNewRound() {
    _loopTimer?.cancel();
    if (!mounted) return;

    final int prevTotal = _myDragonBet + _myTieBet + _myTigerBet;
    if (_gt(prevTotal, 0)) {
      _lastDragonBet = _myDragonBet;
      _lastTieBet = _myTieBet;
      _lastTigerBet = _myTigerBet;
    }

    setState(() {
      _phase = _GamePhase.vsIntro;
      _secondsLeft = 20;
      _dragonCardRevealed = false;
      _tigerCardRevealed = false;
      _roundWinner = "";
      _myRoundWin = 0;

      _myDragonBet = 0;
      _myTieBet = 0;
      _myTigerBet = 0;

      _potDragon = 8000 + _rng.nextInt(12000);
      _potTie = 2000 + _rng.nextInt(5000);
      _potTiger = 8000 + _rng.nextInt(12000);

      _dragonChips.clear();
      _tieChips.clear();
      _tigerChips.clear();
      _seedInitialChips();
    });

_loopTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _phase = _GamePhase.betting;
        _secondsLeft = 20;
      });

      _loopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_gt(_secondsLeft, 1)) {
          setState(() {
            _secondsLeft -= 1;
            _pingMs = 175 + _rng.nextInt(35);
            _simulateRoomActivity();
          });
        } else {
          timer.cancel();
          _beginPrizeDrawing();
        }
      });
    });
  }

  void _seedInitialChips() {
    for (int i = 0; _lt(i, 3); i++) {
      _dragonChips.add(_randomChip(1000));
      _tigerChips.add(_randomChip(1000));
    }
    _tieChips.add(_randomChip(1000));
  }

  _PlacedChip _randomChip(int amount) {
    return _PlacedChip(
      amount: amount,
      dx: (_rng.nextDouble() * 54) - 27,
      dy: (_rng.nextDouble() * 34) - 17,
    );
  }

  void _simulateRoomActivity() {
    final choices = [1000, 1000, 10000, 30000];
    final int amt1 = choices[_rng.nextInt(choices.length)];
    final int amt2 = choices[_rng.nextInt(choices.length)];

    _potDragon += amt1;
    if (_lt(_dragonChips.length, 28)) {
      _dragonChips.add(_randomChip(amt1));
    }

    _potTiger += amt2;
    if (_lt(_tigerChips.length, 28)) {
      _tigerChips.add(_randomChip(amt2));
    }

    if (_rng.nextBool()) {
      final int tieAmt = choices[_rng.nextInt(3)];
      _potTie += tieAmt;
      if (_lt(_tieChips.length, 24)) {
        _tieChips.add(_randomChip(tieAmt));
      }
    }
  }

  Future _placeBet(String area) async {
    if (_phase != _GamePhase.betting) {
      _showGameNotice("Please wait for the next betting round.");
      return;
    }

    final int betAmount = (_chipValues[_selectedChipIndex] as num).toInt();
    if (_lt(_coins, betAmount)) {
      _showGameNotice("Insufficient coins! Please recharge.");
      return;
    }

    setState(() {
      _coins -= betAmount;
      if (area == "Dragon") {
        _myDragonBet += betAmount;
        _potDragon += betAmount;
        if (_lt(_dragonChips.length, 36)) {
          _dragonChips.add(_randomChip(betAmount));
        }
      } else if (area == "Tie") {
        _myTieBet += betAmount;
        _potTie += betAmount;
        if (_lt(_tieChips.length, 36)) {
          _tieChips.add(_randomChip(betAmount));
        }
      } else if (area == "Tiger") {
        _myTigerBet += betAmount;
        _potTiger += betAmount;
        if (_lt(_tigerChips.length, 36)) {
          _tigerChips.add(_randomChip(betAmount));
        }
      }
    });

    _w.onCoinsUpdated(_coins);
    await _syncCoinsDelta(-betAmount);
  }

  Future _repeatPreviousBets() async {
    if (_phase != _GamePhase.betting) {
      _showGameNotice("You can only repeat bets during betting time.");
      return;
    }

    final int totalNeeded = _lastDragonBet + _lastTieBet + _lastTigerBet;
    if (_lte(totalNeeded, 0)) {
      _showGameNotice("No previous bets to repeat.");
      return;
    }

    if (_lt(_coins, totalNeeded)) {
      _showGameNotice("Insufficient coins to repeat previous bet.");
      return;
    }

    setState(() {
      _coins -= totalNeeded;
      if (_gt(_lastDragonBet, 0)) {
        _myDragonBet += _lastDragonBet;
        _potDragon += _lastDragonBet;
        _dragonChips.add(_randomChip(_lastDragonBet));
      }
      if (_gt(_lastTieBet, 0)) {
        _myTieBet += _lastTieBet;
        _potTie += _lastTieBet;
        _tieChips.add(_randomChip(_lastTieBet));
      }
      if (_gt(_lastTigerBet, 0)) {
        _myTigerBet += _lastTigerBet;
        _potTiger += _lastTigerBet;
        _tigerChips.add(_randomChip(_lastTigerBet));
      }
    });

    _w.onCoinsUpdated(_coins);
    await _syncCoinsDelta(-totalNeeded);
  }

Future _syncCoinsDelta(int delta) async {
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

  void _beginPrizeDrawing() {
    if (!mounted) return;
    final int dCard = _rng.nextInt(13) + 1;
    final int tCard = _rng.nextInt(13) + 1;

    setState(() {
      _phase = _GamePhase.drawing;
      _dragonCard = dCard;
      _tigerCard = tCard;
      _dragonCardRevealed = false;
      _tigerCardRevealed = false;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _dragonCardRevealed = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      setState(() {
        _tigerCardRevealed = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;

      String winner = "Tie";
      if (_gt(_dragonCard, _tigerCard)) {
        winner = "Dragon";
      } else if (_gt(_tigerCard, _dragonCard)) {
        winner = "Tiger";
      }

      int winCoins = 0;
      if (winner == "Dragon") {
        if (_gt(_myDragonBet, 0)) {
          winCoins = _myDragonBet * 2;
        }
      } else if (winner == "Tiger") {
        if (_gt(_myTigerBet, 0)) {
          winCoins = _myTigerBet * 2;
        }
      } else if (winner == "Tie") {
        if (_gt(_myTieBet, 0)) {
          winCoins = _myTieBet * 22;
        }
      }

      final int totalMyBet = _myDragonBet + _myTieBet + _myTigerBet;

      setState(() {
        _roundWinner = winner;
        _myRoundWin = winCoins;
        _coins += winCoins;
        _recentResults.insert(0, winner);
        if (_gt(_recentResults.length, 12)) {
          _recentResults.removeLast();
        }
        _roundHistory.insert(0, {
          "round": _roundNumber,
          "dragon": _dragonCard,
          "tiger": _tigerCard,
          "winner": winner,
          "bet": totalMyBet,
          "win": winCoins,
        });
        if (_gt(_roundHistory.length, 30)) {
          _roundHistory.removeLast();
        }
        _buildVictorsList(winCoins);
      });

      if (_gt(winCoins, 0)) {
        _w.onCoinsUpdated(_coins);
        await _syncCoinsDelta(winCoins);
      }

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _phase = _GamePhase.settlement;
        });

        _loopTimer = Timer(const Duration(milliseconds: 3800), () {
          if (!mounted) return;
          _roundNumber += 1;
          _startNewRound();
        });
      });
    });
  }

  void _buildVictorsList(int myWin) {
    final shuffled = List.of(_botNames)..shuffle(_rng);
    final List list = [
      _VictorEntry(
        name: shuffled[0].toString(),
        winAmount: (20 + _rng.nextInt(40)) * 1000,
      ),
      _VictorEntry(
        name: shuffled[1].toString(),
        winAmount: (100 + _rng.nextInt(300)) * 1000,
      ),
      _VictorEntry(
        name: shuffled[2].toString(),
        winAmount: (15 + _rng.nextInt(35)) * 1000,
      ),
    ];

    if (_gt(myWin, 0)) {
      list[1] = _VictorEntry(
        name: _w.userName,
        winAmount: myWin,
        isMe: true,
      );
    }
    _topVictors = list;
  }

  void _showGameNotice(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatCompact(int val) {
    if (_gte(val, 1000000)) {
      return "${(val / 1000000).toStringAsFixed(1)}M";
    }
    if (_gte(val, 1000)) {
      final int k = val ~/ 1000;
      return "${k}K";
    }
    return "$val";
  }

void _openRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1410),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFD49B42), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Color(0xFFFACC15)),
              SizedBox(width: 8),
              Text("Dragon vs Tiger Rules",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "1. Select a chip (1K, 10K, 30K, 50K) and tap Dragon, Tie, or Tiger during the 20s betting countdown.\n\n"
            "2. Two cards are drawn (1 to 13). Higher card wins!\n"
            "   • Dragon Wins: 2x Payout (X2)\n"
            "   • Tiger Wins: 2x Payout (X2)\n"
            "   • Tie (Equal Cards): 22x Payout (X22)",
            style:
                TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.45),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706)),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("Got It",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1410),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFD49B42), width: 1.5),
          ),
          title: const Text("Round History",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 260,
            child: _roundHistory.isEmpty
                ? const Center(
                    child: Text("No completed rounds yet.",
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12.5)),
                  )
                : ListView.builder(
                    itemCount: _roundHistory.length,
                    itemBuilder: (_, i) {
                      final r = _roundHistory[i] as Map;
                      final String w = r['winner'].toString();
                      Color wColor = const Color(0xFFFACC15);
                      if (w == "Dragon") {
                        wColor = const Color(0xFFEF4444);
                      } else if (w == "Tiger") {
                        wColor = const Color(0xFF3B82F6);
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Round #${r['round']}",
                                style: const TextStyle(

color: Colors.white70, fontSize: 11.5)),
                            Text("D:${r['dragon']} vs T:${r['tiger']}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text(w,
                                style: TextStyle(
                                    color: wColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("Close",
                  style: TextStyle(color: Color(0xFFFACC15))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalMyBet = _myDragonBet + _myTieBet + _myTigerBet;
    final bool showDrawingBar =
        _phase == _GamePhase.drawing && _roundWinner.isEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.66,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF7C1D05),
            Color(0xFF431407),
            Color(0xFF1E1B4B),
            Color(0xFF0F296D),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Stack(
          children: [
            Positioned(
              left: -18,
              top: 30,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 185,
                color: const Color(0xFFF97316).withOpacity(0.22),
              ),
            ),
            Positioned(
              right: -18,
              top: 30,
              child: Icon(
                Icons.bolt_rounded,
                size: 185,
                color: const Color(0xFF38BDF8).withOpacity(0.22),
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 2),
                                Text("Dragon vs Tiger",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,

fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _topIconBtn(
                                Icons.history_rounded, _openHistoryDialog),
                            const SizedBox(width: 6),
                            _topIconBtn(
                                Icons.question_mark_rounded, _openRulesDialog),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(Icons.wifi,
                                    color: Color(0xFF22C55E), size: 13),
                                const SizedBox(width: 2),
                                Text(
                                  "${_pingMs}ms",
                                  style: const TextStyle(
                                      color: Color(0xFF4ADE80),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    SizedBox(
                      height: 112,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildPlayingCard(
                                isDragon: true,
                                revealed: _dragonCardRevealed,
                                value: _dragonCard,
                              ),
                              const SizedBox(width: 64),
                              _buildPlayingCard(
                                isDragon: false,
                                revealed: _tigerCardRevealed,
                                value: _tigerCard,
                              ),
                            ],
                          ),

                          if (_phase == _GamePhase.vsIntro)
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (context, child) {
                                final double s =
                                    0.9 + (_pulseCtrl.value * 0.25);
                                return Transform.scale(scale: s, child: child);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [
                                      Color(0xFFFEF08A),
                                      Color(0xFFD97706),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFACC15)
                                          .withOpacity(0.7),
                                      blurRadius: 16,
                                    ),
                                  ],

),
                                child: const Text(
                                  "VS",
                                  style: TextStyle(
                                    color: Color(0xFF7C2D12),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else if (_phase == _GamePhase.betting)
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF451A03),
                                border: Border.all(
                                    color: const Color(0xFFFACC15), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "$_secondsLeft",
                                  style: TextStyle(
                                    color: _lte(_secondsLeft, 5)
                                        ? const Color(0xFFEF4444)
                                        : Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),

                          if (_roundWinner.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 26, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _roundWinner == "Tiger"
                                      ? [
                                          const Color(0xFF1D4ED8),
                                          const Color(0xFF3B82F6),
                                          const Color(0xFF1D4ED8),
                                        ]
                                      : [
                                          const Color(0xFF991B1B),
                                          const Color(0xFFDC2626),
                                          const Color(0xFF991B1B),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFFACC15), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.55),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Text(
                                _roundWinner == "Tie"
                                    ? "Tie Win!"
                                    : "$_roundWinner Win",
                                style: const TextStyle(

color: Color(0xFFFEF08A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "Result:",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _recentResults.length,
                              itemBuilder: (_, idx) {
                                final String res =
                                    _recentResults[idx].toString();
                                Color badgeBg = const Color(0xFFEA580C);
                                String letter = "D";
                                if (res == "Tiger") {
                                  badgeBg = const Color(0xFF2563EB);
                                  letter = "T";
                                } else if (res == "Tie") {
                                  badgeBg = const Color(0xFF16A34A);
                                  letter = "=";
                                }
                                return Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: badgeBg,
                                    border: Border.all(
                                        color: const Color(0xFFFACC15),
                                        width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildBettingZone(

title: "Dragon",
                                  multiplier: "X2",
                                  pot: _potDragon,
                                  myBet: _myDragonBet,
                                  chips: _dragonChips,
                                  borderColor: const Color(0xFFF97316),
                                  bgTint: const Color(0xFF7C2D12),
                                  watermarkIcon:
                                      Icons.local_fire_department_rounded,
                                  onTap: () {
                                    _placeBet("Dragon");
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildBettingZone(
                                  title: "Tie",
                                  multiplier: "X22",
                                  pot: _potTie,
                                  myBet: _myTieBet,
                                  chips: _tieChips,
                                  borderColor: const Color(0xFFFACC15),
                                  bgTint: const Color(0xFF713F12),
                                  watermarkIcon: Icons.balance_rounded,
                                  onTap: () {
                                    _placeBet("Tie");
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildBettingZone(
                                  title: "Tiger",
                                  multiplier: "X2",
                                  pot: _potTiger,
                                  myBet: _myTigerBet,
                                  chips: _tigerChips,
                                  borderColor: const Color(0xFF38BDF8),
                                  bgTint: const Color(0xFF1E3A8A),
                                  watermarkIcon: Icons.bolt_rounded,
                                  onTap: () {
                                    _placeBet("Tiger");
                                  },
                                ),
                              ),
                            ],
                          ),

                          if (showDrawingBar)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              color: Colors.black.withOpacity(0.75),
                              child: const Text(
                                "Betting stopped, prize drawing in progress.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(16),

border: Border.all(
                                color:
                                    const Color(0xFFFACC15).withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: Color(0xFFFACC15), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _formatCompact(_coins),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

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
                                  duration: const Duration(milliseconds: 180),
                                  width: selected ? 46 : 40,
                                  height: selected ? 46 : 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _chipColor(val),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFFEF08A)
                                          : Colors.white38,
                                      width: selected ? 2.5 : 1.2,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFACC15)
                                                  .withOpacity(0.65),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _formatCompact(val),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(width: 6),

                        GestureDetector(
                          onTap: _repeatPreviousBets,
                          child: Container(

padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF59E0B),
                                  Color(0xFFD97706),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: const Color(0xFFFEF08A), width: 1.2),
                            ),
                            child: const Text(
                              "Repeat",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    const Text(
                      "Steps: Select Amount • Click the Betting Area",
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            if (_phase == _GamePhase.settlement)
              _buildSettlementOverlay(totalMyBet),
          ],
        ),
      ),
    );
  }

  Widget _topIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF59E0B),
          border: Border.all(color: const Color(0xFFFEF08A), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Color _chipColor(int val) {
    if (_gte(val, 50000)) return const Color(0xFFDB2777);
    if (_gte(val, 30000)) return const Color(0xFF7C3AED);
    if (_gte(val, 10000)) return const Color(0xFF2563EB);
    return const Color(0xFF16A34A);
  }

  Widget _buildPlayingCard({
    required bool isDragon,
    required bool revealed,
    required int value,
  }) {
    final Color backColor =
        isDragon ? const Color(0xFFB91C1C) : const Color(0xFF1D4ED8);
    final Color accent =
        isDragon ? const Color(0xFFEF4444) : const Color(0xFF2563EB);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) {
        return ScaleTransition(scale: anim, child: child);
      },
      child: revealed
          ? Container(
              key: ValueKey("open_${isDragon}_$value"),
              width: 68,
              height: 94,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFFFACC15), width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 5,
                    left: 6,
                    child: Column(
                      children: [
                        Text(
                          "$value",
                          style: TextStyle(
                            color: accent,

fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Icon(
                          isDragon
                              ? Icons.local_fire_department
                              : Icons.bolt_rounded,
                          color: accent,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Text(
                      "$value",
                      style: TextStyle(
                        color: accent,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              key: ValueKey("back_$isDragon"),
              width: 68,
              height: 94,
              decoration: BoxDecoration(
                color: backColor,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFFFACC15), width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isDragon
                      ? Icons.local_fire_department_rounded
                      : Icons.bolt_rounded,
                  color: const Color(0xFFFEF08A).withOpacity(0.75),
                  size: 38,
                ),
              ),
            ),
    );
  }

  Widget _buildBettingZone({
    required String title,
    required String multiplier,
    required int pot,
    required int myBet,
    required List chips,
    required Color borderColor,
    required Color bgTint,
    required IconData watermarkIcon,
    required VoidCallback onTap,
  }) {
    final bool isWinnerZone = _roundWinner == title;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bgTint.withOpacity(isWinnerZone ? 0.85 : 0.58),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWinnerZone ? const Color(0xFFFEF08A) : borderColor,
            width: isWinnerZone ? 2.6 : 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              watermarkIcon,
              size: 72,
              color: Colors.white.withOpacity(0.09),
            ),

            ...chips.map((rawChip) {
              final c = rawChip as _PlacedChip;
              return Transform.translate(
                offset: Offset(c.dx, c.dy),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _chipColor(c.amount),
                    border: Border.all(color: Colors.white, width: 0.8),
                  ),
                  child: const Center(
                    child: Icon(Icons.diamond, color: Colors.white, size: 9),
                  ),
                ),
              );
            }),

            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(

color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  multiplier,
                  style: const TextStyle(
                    color: Color(0xFFFEF08A),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "POT:${_formatCompact(pot)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "ME:${_formatCompact(myBet)}",
                  style: TextStyle(
                    color: _gt(myBet, 0)
                        ? const Color(0xFF4ADE80)
                        : Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementOverlay(int totalMyBet) {
    IconData emblemIcon = Icons.local_fire_department_rounded;
    if (_roundWinner == "Tiger") {
      emblemIcon = Icons.bolt_rounded;
    } else if (_roundWinner == "Tie") {
      emblemIcon = Icons.balance_rounded;
    }

    return Container(
      color: Colors.black.withOpacity(0.72),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF991B1B),
                Color(0xFF450A0A),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFACC15), width: 2.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Settlement",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Round:$_roundNumber",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 6),

              Icon(
                emblemIcon,
                color: const Color(0xFFFACC15),
                size: 46,
              ),
              Text(
                "$_roundWinner Win",
                style: const TextStyle(
                  color: Color(0xFFFEF08A),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                "The top victors of this round",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 8),

if (_gte(_topVictors.length, 3))
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildVictorColumn(_topVictors[0] as _VictorEntry, 2),
                    _buildVictorColumn(_topVictors[1] as _VictorEntry, 1),
                    _buildVictorColumn(_topVictors[2] as _VictorEntry, 3),
                  ],
                ),

              const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFACC15).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFF59E0B),
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _w.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Bet   ${_formatCompact(totalMyBet)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Win   ${_formatCompact(_myRoundWin)}",
                          style: const TextStyle(
                            color: Color(0xFFFACC15),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVictorColumn(_VictorEntry v, int rank) {
    final bool isFirst = rank == 1;
    Color crownColor = const Color(0xFFD97706);
    if (isFirst) {
      crownColor = const Color(0xFFFACC15);
    } else if (rank == 2) {
      crownColor = const Color(0xFFE5E7EB);
    }

    return Expanded(
      child: Column(
        children: [
          Icon(Icons.workspace_premium,
              color: crownColor, size: isFirst ? 22 : 18),
          CircleAvatar(
            radius: isFirst ? 22 : 18,
            backgroundColor: crownColor,
            child: CircleAvatar(
              radius: isFirst ? 20 : 16,
              backgroundColor: const Color(0xFF1F2937),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            v.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "Win ${_formatCompact(v.winAmount)}",
            style: const TextStyle(
              color: Color(0xFFFACC15),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
