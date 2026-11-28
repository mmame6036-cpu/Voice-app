import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _PlayingCard {
  final int rank; // 2..14 (11=J, 12=Q, 13=K, 14=A)
  final String suit; // '♠', '♥', '♦', '♣'

  const _PlayingCard({required this.rank, required this.suit});

  bool get isRed => suit == '♥' || suit == '♦';

  String get rankLabel {
    switch (rank) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      default:
        return '$rank';
    }
  }
}

class _HandEval {
  final int category; // 6=Set, 5=PureSeq, 4=Seq, 3=Color, 2=Pair, 1=HighCard
  final String label;
  final List<int> tieBreakers;

  const _HandEval({
    required this.category,
    required this.label,
    required this.tieBreakers,
  });
}

class RoyalBattleSheet extends StatefulWidget {
  final String roomId;
  final String userName;
  final String userUid;
  final int userNumericId;

  const RoyalBattleSheet({
    super.key,
    required this.roomId,
    required this.userName,
    required this.userUid,
    required this.userNumericId,
  });

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required String userName,
    required String userUid,
    required int userNumericId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoyalBattleSheet(
        roomId: roomId,
        userName: userName,
        userUid: userUid,
        userNumericId: userNumericId,
      ),
    );
  }

  @override
  State<RoyalBattleSheet> createState() => _RoyalBattleSheetState();
}

class _RoyalBattleSheetState extends State<RoyalBattleSheet>
    with SingleTickerProviderStateMixin {
  static const Color kGoldBright = Color(0xFFFFD700);
  static const Color kGoldDeep = Color(0xFFB45309);
  static const Color kBlueRoyal = Color(0xFF1D4ED8);
  static const Color kBlueLight = Color(0xFF38BDF8);
  static const Color kRedRoyal = Color(0xFFB91C1C);
  static const Color kRedLight = Color(0xFFF87171);
  static const Color kDarkFelt = Color(0xFF0B1324);

  static const List<int> _chips = [10, 100, 1000, 10000, 100000];

  // Bet zones:
  // 'blue' (1.95x), 'red' (1.95x),
  // 'pair' (3.5x), 'color' (10x), 'sequence' (15x), 'pure_seq' (100x), 'set' (100x)
  static const Map<String, double> _multipliers = {
    'blue': 1.95,
    'red': 1.95,
    'pair': 3.5,
    'color': 10.0,
    'sequence': 15.0,
    'pure_seq': 100.0,
    'set': 100.0,
  };

  final Random _random = Random();
  StreamSubscription? _walletSub;
  Timer? _roundTimer;
  Timer? _botBetTimer;
  late AnimationController _cardFlipController;

  int _userCoins = 0;
  int _selectedChipIndex = 0;
  int _secondsLeft = 20;
  bool _isRevealing = false;
  bool _isPlacingBet = false;

  final Map<String, int> _myBets = {
    'blue': 0,
    'red': 0,
    'pair': 0,
    'color': 0,
    'sequence': 0,
    'pure_seq': 0,
    'set': 0,
  };

  final Map<String, int> _totalPoolBets = {
    'blue': 0,
    'red': 0,
    'pair': 0,
    'color': 0,
    'sequence': 0,
    'pure_seq': 0,
    'set': 0,
  };

  List<_PlayingCard> _blueCards = [];
  List<_PlayingCard> _redCards = [];
  _HandEval? _blueEval;
  _HandEval? _redEval;
  String _winnerSide = ''; // 'BLUE' or 'RED'
  int _lastRoundWinCoins = 0;
  String _statusBanner = "Place Your Bets!";

  // History of winners: 'B' or 'R'
  final List<String> _history = ['B', 'R', 'B', 'B', 'R', 'B', 'R', 'R', 'B', 'R'];

  @override
  void initState() {
    super.initState();
    _cardFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _listenToWallet();
    _startNewRound();
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _roundTimer?.cancel();
    _botBetTimer?.cancel();
    _cardFlipController.dispose();
    super.dispose();
  }

  void _listenToWallet() {
    if (widget.userUid.isEmpty || widget.userUid.startsWith('guest_')) return;
    _walletSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userUid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (snap.exists && snap.data() != null) {
        setState(() {
          _userCoins = (snap.data()!['coins'] as num?)?.toInt() ?? _userCoins;
        });
      }
    });
  }

  void _startNewRound() {
    _roundTimer?.cancel();
    _botBetTimer?.cancel();
    _cardFlipController.reset();

    setState(() {
      _secondsLeft = 20;
      _isRevealing = false;
      _winnerSide = '';
      _lastRoundWinCoins = 0;
      _blueCards = [];
      _redCards = [];
      _blueEval = null;
      _redEval = null;
      _statusBanner = "Place Your Bets!";

      for (final k in _myBets.keys) {
        _myBets[k] = 0;
        _totalPoolBets[k] = (1 + _random.nextInt(5)) * 100;
      }
    });

    _botBetTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted || _isRevealing) return;
      final keys = _totalPoolBets.keys.toList();
      final pick = keys[_random.nextInt(keys.length)];
      final addAmt = [100, 500, 1000, 2000][_random.nextInt(4)];
      setState(() {
        _totalPoolBets[pick] = (_totalPoolBets[pick] ?? 0) + addAmt;
      });
    });

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft -= 1;
        });
      } else {
        timer.cancel();
        _botBetTimer?.cancel();
        _revealRoundOutcome();
      }
    });
  }

  Future<void> _placeBet(String zone) async {
    if (_isRevealing) {
      _showToast("Round is revealing cards. Wait for next round!");
      return;
    }
    if (_isPlacingBet) return;

    final int chipAmount = _chips[_selectedChipIndex];
    if (_userCoins < chipAmount) {
      _showToast("Insufficient coins! Recharge in Wallet.");
      return;
    }

    _isPlacingBet = true;
    try {
      if (!widget.userUid.startsWith('guest_')) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(widget.userUid);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(userRef);
          final cur = (snap.data()?['coins'] as num?)?.toInt() ?? 0;
          if (cur < chipAmount) {
            throw Exception("Insufficient coins");
          }
          tx.update(userRef, {
            'coins': FieldValue.increment(-chipAmount),
          });
        });
      } else {
        setState(() {
          _userCoins -= chipAmount;
        });
      }

      if (mounted) {
        setState(() {
          _myBets[zone] = (_myBets[zone] ?? 0) + chipAmount;
          _totalPoolBets[zone] = (_totalPoolBets[zone] ?? 0) + chipAmount;
        });
      }
    } catch (_) {
      _showToast("Bet could not be placed.");
    } finally {
      _isPlacingBet = false;
    }
  }

  List<_PlayingCard> _buildShuffledDeck() {
    const suits = ['♠', '♥', '♦', '♣'];
    final List<_PlayingCard> deck = [];
    for (final s in suits) {
      for (int r = 2; r <= 14; r++) {
        deck.add(_PlayingCard(rank: r, suit: s));
      }
    }
    deck.shuffle(_random);
    return deck;
  }

  _HandEval _evaluateThreeCardHand(List<_PlayingCard> cards) {
    final sorted = List<_PlayingCard>.from(cards)
      ..sort((a, b) => b.rank.compareTo(a.rank));
    final r0 = sorted[0].rank;
    final r1 = sorted[1].rank;
    final r2 = sorted[2].rank;

    final bool isFlush =
        sorted[0].suit == sorted[1].suit && sorted[1].suit == sorted[2].suit;
    final bool isStraightNormal = (r0 - 1 == r1) && (r1 - 1 == r2);
    final bool isAceLowStraight = (r0 == 14 && r1 == 3 && r2 == 2);
    final bool isStraight = isStraightNormal || isAceLowStraight;

    final List<int> straightTie =
        isAceLowStraight ? [3, 2, 1] : [r0, r1, r2];

    if (r0 == r1 && r1 == r2) {
      return _HandEval(
        category: 6,
        label: "SET",
        tieBreakers: [r0],
      );
    }
    if (isFlush && isStraight) {
      return _HandEval(
        category: 5,
        label: "PURE SEQ",
        tieBreakers: straightTie,
      );
    }
    if (isStraight) {
      return _HandEval(
        category: 4,
        label: "SEQUENCE",
        tieBreakers: straightTie,
      );
    }
    if (isFlush) {
      return _HandEval(
        category: 3,
        label: "COLOR",
        tieBreakers: [r0, r1, r2],
      );
    }
    if (r0 == r1 || r1 == r2) {
      final int pairRank = r1;
      final int kicker = (r0 == r1) ? r2 : r0;
      return _HandEval(
        category: 2,
        label: "PAIR",
        tieBreakers: [pairRank, kicker],
      );
    }
    return _HandEval(
      category: 1,
      label: "HIGH CARD",
      tieBreakers: [r0, r1, r2],
    );
  }

  int _compareHands(_HandEval a, _HandEval b) {
    if (a.category != b.category) {
      return a.category.compareTo(b.category);
    }
    final int len = min(a.tieBreakers.length, b.tieBreakers.length);
    for (int i = 0; i < len; i++) {
      if (a.tieBreakers[i] != b.tieBreakers[i]) {
        return a.tieBreakers[i].compareTo(b.tieBreakers[i]);
      }
    }
    return 0;
  }

  Future<void> _revealRoundOutcome() async {
    final deck = _buildShuffledDeck();
    final blue = [deck[0], deck[1], deck[2]];
    final red = [deck[3], deck[4], deck[5]];

    final bEval = _evaluateThreeCardHand(blue);
    final rEval = _evaluateThreeCardHand(red);
    final int cmp = _compareHands(bEval, rEval);
    final String winSide = cmp >= 0 ? 'BLUE' : 'RED';
    final _HandEval winningHandEval = winSide == 'BLUE' ? bEval : rEval;

    int payout = 0;
    final int blueBet = _myBets['blue'] ?? 0;
    final int redBet = _myBets['red'] ?? 0;

    if (winSide == 'BLUE' && blueBet > 0) {
      payout += (blueBet * _multipliers['blue']!).round();
    }
    if (winSide == 'RED' && redBet > 0) {
      payout += (redBet * _multipliers['red']!).round();
    }

    // Special side bets trigger when winning hand matches category
    if (winningHandEval.category == 2 && (_myBets['pair'] ?? 0) > 0) {
      payout += (_myBets['pair']! * _multipliers['pair']!).round();
    } else if (winningHandEval.category == 3 && (_myBets['color'] ?? 0) > 0) {
      payout += (_myBets['color']! * _multipliers['color']!).round();
    } else if (winningHandEval.category == 4 &&
        (_myBets['sequence'] ?? 0) > 0) {
      payout += (_myBets['sequence']! * _multipliers['sequence']!).round();
    } else if (winningHandEval.category == 5 &&
        (_myBets['pure_seq'] ?? 0) > 0) {
      payout += (_myBets['pure_seq']! * _multipliers['pure_seq']!).round();
    } else if (winningHandEval.category == 6 && (_myBets['set'] ?? 0) > 0) {
      payout += (_myBets['set']! * _multipliers['set']!).round();
    }

    if (mounted) {
      setState(() {
        _isRevealing = true;
        _blueCards = blue;
        _redCards = red;
        _blueEval = bEval;
        _redEval = rEval;
        _winnerSide = winSide;
        _lastRoundWinCoins = payout;
        _statusBanner = "$winSide WINS (${winningHandEval.label})!";
        _history.add(winSide == 'BLUE' ? 'B' : 'R');
        if (_history.length > 14) {
          _history.removeAt(0);
        }
      });
    }

    _cardFlipController.forward();

    if (payout > 0) {
      if (!widget.userUid.startsWith('guest_')) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userUid)
            .set({
          'coins': FieldValue.increment(payout),
        }, SetOptions(merge: true)).catchError((_) {});
      } else if (mounted) {
        setState(() {
          _userCoins += payout;
        });
      }

      if (payout >= 5000 && widget.roomId.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('messages')
            .add({
          'sender': 'System',
          'senderUid': widget.userUid,
          'message':
              "👑 ${widget.userName} won $payout Coins in Royal Battle ($winSide - ${winningHandEval.label})!",
          'isSystem': true,
          'ts': DateTime.now().millisecondsSinceEpoch,
        }).catchError((_) {});
      }
    }

    await Future.delayed(const Duration(seconds: 6));
    if (mounted) {
      _startNewRound();
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatCompact(int val) {
    if (val >= 1000000) return "${(val / 1000000).toStringAsFixed(1)}M";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}K";
    return "$val";
  }

  Widget _buildCardWidget(_PlayingCard? card) {
    if (!_isRevealing || card == null) {
      return Container(
        width: 34,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kGoldBright, width: 1.2),
        ),
        child: const Center(
          child: Text("👑", style: TextStyle(fontSize: 15)),
        ),
      );
    }

    return Container(
      width: 34,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kGoldBright, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rankLabel,
            style: TextStyle(
              color: card.isRed ? Colors.red.shade700 : Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              height: 1.0,
            ),
          ),
          Text(
            card.suit,
            style: TextStyle(
              color: card.isRed ? Colors.red.shade700 : Colors.black87,
              fontSize: 13,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSideBetBox({
    required String zone,
    required String title,
    required String multLabel,
    required List<Color> gradientColors,
    required Color borderColor,
  }) {
    final int myBet = _myBets[zone] ?? 0;
    final int poolBet = _totalPoolBets[zone] ?? 0;
    final bool isWin = _isRevealing && _winnerSide == title;

    return Expanded(
      child: GestureDetector(
        onTap: () => _placeBet(zone),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 86,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isWin ? kGoldBright : borderColor,
              width: isWin ? 2.4 : 1.3,
            ),
            boxShadow: isWin
                ? [
                    BoxShadow(
                      color: kGoldBright.withOpacity(0.55),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      multLabel,
                      style: const TextStyle(
                        color: kGoldBright,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "Total: ${_formatCompact(poolBet)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: myBet > 0 ? kGoldBright : Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    myBet > 0 ? "My Bet: ${_formatCompact(myBet)}" : "Tap to Bet",
                    style: TextStyle(
                      color: myBet > 0 ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialBetTile({
    required String zone,
    required String label,
    required String multText,
  }) {
    final int myBet = _myBets[zone] ?? 0;
    final int poolBet = _totalPoolBets[zone] ?? 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => _placeBet(zone),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          decoration: BoxDecoration(
            color: myBet > 0
                ? const Color(0xFF2B2110)
                : const Color(0xFF141E33),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: myBet > 0 ? kGoldBright : Colors.white24,
              width: myBet > 0 ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                multText,
                style: const TextStyle(
                  color: kGoldBright,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                myBet > 0 ? _formatCompact(myBet) : _formatCompact(poolBet),
                style: TextStyle(
                  color: myBet > 0 ? const Color(0xFF34D399) : Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalMyBet =
        _myBets.values.fold<int>(0, (sum, item) => sum + item);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF131D36), kDarkFelt],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: kGoldBright, width: 1.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Title, Timer, Close
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("⚔️", style: TextStyle(fontSize: 14)),
                      SizedBox(width: 5),
                      Text(
                        "ROYAL BATTLE",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isRevealing
                        ? Colors.orange.withOpacity(0.22)
                        : const Color(0xFF10B981).withOpacity(0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isRevealing ? Colors.orangeAccent : kGoldBright,
                    ),
                  ),
                  child: Text(
                    _isRevealing ? "Result" : "${_secondsLeft}s",
                    style: const TextStyle(
                      color: kGoldBright,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.close, color: Colors.white70, size: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // History Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text(
                    "History:",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _history.map((h) {
                          final bool isB = h == 'B';
                          return Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isB ? kBlueRoyal : kRedRoyal,
                              border: Border.all(color: Colors.white30, width: 0.8),
                            ),
                            child: Center(
                              child: Text(
                                h,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // BLUE vs RED Card Arena
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF111827),
                    Color(0xFF7F1D1D),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kGoldBright.withOpacity(0.6)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // BLUE King Side
                      Column(
                        children: [
                          Row(
                            children: [
                              const Text("🤴", style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Text(
                                _blueEval != null ? _blueEval!.label : "BLUE",
                                style: const TextStyle(
                                  color: kBlueLight,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              3,
                              (i) => _buildCardWidget(
                                i < _blueCards.length ? _blueCards[i] : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Center VS / Winner Banner
                      Column(
                        children: [
                          const Text(
                            "VS",
                            style: TextStyle(
                              color: kGoldBright,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusBanner,
                              style: TextStyle(
                                color: _isRevealing
                                    ? kGoldBright
                                    : Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // RED Queen Side
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                _redEval != null ? _redEval!.label : "RED",
                                style: const TextStyle(
                                  color: kRedLight,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text("👸", style: TextStyle(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              3,
                              (i) => _buildCardWidget(
                                i < _redCards.length ? _redCards[i] : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isRevealing && _lastRoundWinCoins > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "🎉 You Won +$_lastRoundWinCoins Coins!",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Main Side Bet Zones: BLUE (1.95x) vs RED (1.95x)
            Row(
              children: [
                _buildMainSideBetBox(
                  zone: 'blue',
                  title: 'BLUE',
                  multLabel: '1.95X',
                  gradientColors: const [Color(0xFF1E40AF), Color(0xFF1D4ED8)],
                  borderColor: kBlueLight,
                ),
                const SizedBox(width: 10),
                _buildMainSideBetBox(
                  zone: 'red',
                  title: 'RED',
                  multLabel: '1.95X',
                  gradientColors: const [Color(0xFF991B1B), Color(0xFFDC2626)],
                  borderColor: kRedLight,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 5 Special Hand Bet Zones
            Row(
              children: [
                _buildSpecialBetTile(
                  zone: 'pair',
                  label: 'PAIR',
                  multText: '3.5X',
                ),
                _buildSpecialBetTile(
                  zone: 'color',
                  label: 'COLOR',
                  multText: '10X',
                ),
                _buildSpecialBetTile(
                  zone: 'sequence',
                  label: 'SEQ',
                  multText: '15X',
                ),
                _buildSpecialBetTile(
                  zone: 'pure_seq',
                  label: 'PURE',
                  multText: '100X',
                ),
                _buildSpecialBetTile(
                  zone: 'set',
                  label: 'SET',
                  multText: '100X',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Wallet + Chip Selector Bar
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kGoldBright.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🪙 $_userCoins",
                        style: const TextStyle(
                          color: kGoldBright,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Bet: $totalMyBet",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_chips.length, (i) {
                      final int val = _chips[i];
                      final bool sel = _selectedChipIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedChipIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: sel ? 42 : 36,
                          height: sel ? 42 : 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: sel
                                  ? const [Color(0xFFFFF59D), Color(0xFFF59E0B)]
                                  : const [Color(0xFF334155), Color(0xFF0F172A)],
                            ),
                            border: Border.all(
                              color: sel ? Colors.white : kGoldBright,
                              width: sel ? 2.0 : 1.1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _formatCompact(val),
                              style: TextStyle(
                                color: sel ? Colors.black : kGoldBright,
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
