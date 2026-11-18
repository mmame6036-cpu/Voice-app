import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

class DragonTigerSheet extends StatefulWidget {
  final String roomId;
  final String userName;
  final String? userUid;
  final int? userNumericId;

  const DragonTigerSheet({
    super.key,
    required this.roomId,
    required this.userName,
    this.userUid,
    this.userNumericId,
  });

  static void show(
    BuildContext context, {
    required String roomId,
    required String userName,
    String? userUid,
    int? userNumericId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DragonTigerSheet(
        roomId: roomId,
        userName: userName,
        userUid: userUid,
        userNumericId: userNumericId,
      ),
    );
  }

  @override
  State<DragonTigerSheet> createState() => _DragonTigerSheetState();
}

class _DragonTigerSheetState extends State<DragonTigerSheet> {
  static const Color kBgDark = Color(0xFF140D09);
  static const Color kCardDark = Color(0xFF231710);
  static const Color kGold = Color(0xFFFFD700);
  static const Color kGoldBorder = Color(0xFFD49B42);
  static const Color kDragonRed = Color(0xFFB71C1C);
  static const Color kTigerAmber = Color(0xFFE65100);
  static const Color kTieGreen = Color(0xFF1B5E20);

  static const int kBettingDurationMs = 15000;
  static const int kRevealDurationMs = 3000;
  static const int kSettlementDurationMs = 4000;

  final List _chips = [100, 500, 1000, 5000, 10000, 50000];
  int _selectedChip = 100;

  String _resolvedUid = "";
  String _resolvedName = "Player";
  int _resolvedNumericId = 0;

  int _myCoins = 0;
  int _remainingSec = 15;

  String _roundId = "";
  int _roundNumber = 1;
  String _phase = "BETTING";
  int _roundEndTime = 0;
  int _revealEndTime = 0;
  int _nextRoundTime = 0;

  int _potDragon = 0;
  int _potTie = 0;
  int _potTiger = 0;

  int _myBetDragon = 0;
  int _myBetTie = 0;
  int _myBetTiger = 0;

  Map? _dragonCard;
  Map? _tigerCard;
  String? _winner;
  List _topWinners = [];
  List _history = [];

  int _lastSettledWin = 0;
  String _lastSettledRound = "";
  String? _statusBanner;
  bool _isPlacingBet = false;
  bool _isAdvancingEngine = false;
  bool _isSettlingMyBet = false;

  StreamSubscription? _gameSub;
  StreamSubscription? _userSub;
  StreamSubscription? _myBetSub;
  Timer? _clockTimer;
  Timer? _bannerTimer;

  DocumentReference get _gameDoc =>
      FirebaseFirestore.instance.collection('games').doc('dragon_tiger');

  Map _asMap(Object? raw) {
    if (raw is Map) {
      return Map.from(raw);
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    _initPlayerIdentity();
    _ensureGameInitialized();
    _listenToGameStream();
    _startClockTimer();
  }

  Future<void> _initPlayerIdentity() async {
    final authUser = FirebaseAuth.instance.currentUser;
    String uid = "";
    final passedUid = widget.userUid ?? "";
    if (passedUid.isNotEmpty && passedUid != "user_guest_id") {
      uid = passedUid;
    } else if (authUser != null) {
      uid = authUser.uid;
    }

    _resolvedUid = uid;
    _resolvedName = widget.userName.isNotEmpty ? widget.userName : "Player";
    _resolvedNumericId = widget.userNumericId ?? 0;

    if (uid.isNotEmpty) {
      _userSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        if (!snap.exists) return;
        final d = _asMap(snap.data());
        if (d.isEmpty) return;

        setState(() {
          _myCoins = (d['coins'] as num?)?.toInt() ?? 0;

if ((d['name'] ?? '').toString().isNotEmpty) {
            _resolvedName = d['name'].toString();
          }
          if (d['numericId'] != null) {
            _resolvedNumericId = (d['numericId'] as num).toInt();
          }
        });
      });
    }
  }

  Future<void> _ensureGameInitialized() async {
    try {
      final snap = await _gameDoc.get();
      if (!snap.exists) {
        await _advanceGameEngine(forceInit: true);
      } else {
        await _advanceGameEngine();
      }
    } catch (_) {}
  }

  void _listenToGameStream() {
    _gameSub = _gameDoc.snapshots().listen((snap) {
      if (!mounted) return;
      if (!snap.exists) {
        _advanceGameEngine(forceInit: true);
        return;
      }
      final d = _asMap(snap.data());
      if (d.isEmpty) {
        _advanceGameEngine(forceInit: true);
        return;
      }
      _applyGameData(d);
    });
  }

  void _applyGameData(Map d) {
    if (!mounted) return;

    final String newRoundId = (d['roundId'] ?? '').toString();
    final String newPhase = (d['phase'] ?? 'BETTING').toString();

    if (newRoundId.isNotEmpty && newRoundId != _roundId) {
      _roundId = newRoundId;
      _myBetDragon = 0;
      _myBetTie = 0;
      _myBetTiger = 0;
      _lastSettledWin = 0;
      _subscribeToMyRoundBet(newRoundId);
    }

    final potMap = _asMap(d['pot']);
    final rawWinners = d['topWinners'];
    final List nextWinners = [];
    if (rawWinners is Iterable) {
      for (final item in rawWinners) {
        if (item is Map) {
          nextWinners.add(Map.from(item));
        }
      }
    }

    final rawHistory = d['history'];
    final List nextHistory = [];
    if (rawHistory is Iterable) {
      for (final item in rawHistory) {
        nextHistory.add(item.toString());
      }
    }

    setState(() {
      _roundNumber = (d['roundNumber'] as num?)?.toInt() ?? _roundNumber;
      _phase = newPhase;
      _roundEndTime = (d['roundEndTime'] as num?)?.toInt() ?? _roundEndTime;
      _revealEndTime = (d['revealEndTime'] as num?)?.toInt() ?? _revealEndTime;
      _nextRoundTime = (d['nextRoundTime'] as num?)?.toInt() ?? _nextRoundTime;

      _potDragon = (potMap['dragon'] as num?)?.toInt() ?? 0;
      _potTie = (potMap['tie'] as num?)?.toInt() ?? 0;
      _potTiger = (potMap['tiger'] as num?)?.toInt() ?? 0;

      _dragonCard =
          (d['dragonCard'] is Map) ? Map.from(d['dragonCard'] as Map) : null;
      _tigerCard =
          (d['tigerCard'] is Map) ? Map.from(d['tigerCard'] as Map) : null;
      _winner = d['winner']?.toString();

      _topWinners = nextWinners;
      _history = nextHistory;
    });

    bool isRevealOrSettle = false;
    if (newPhase == "REVEALING") isRevealOrSettle = true;
    if (newPhase == "SETTLEMENT") isRevealOrSettle = true;

    if (isRevealOrSettle && _winner != null && _winner!.isNotEmpty) {
      _settleMyBetIfNeeded(newRoundId, _winner!);
    }
  }

  void _subscribeToMyRoundBet(String roundId) {
    _myBetSub?.cancel();
    if (_resolvedUid.isEmpty) return;
    if (roundId.isEmpty) return;

    _myBetSub = _gameDoc
        .collection('rounds')
        .doc(roundId)
        .collection('bets')
        .doc(_resolvedUid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (!snap.exists) return;
      final d = _asMap(snap.data());
      if (d.isEmpty) return;

      final int won = (d['wonAmount'] as num?)?.toInt() ?? 0;
      final bool paid = d['paid'] == true;

      setState(() {
        _myBetDragon = (d['dragon'] as num?)?.toInt() ?? 0;
        _myBetTie = (d['tie'] as num?)?.toInt() ?? 0;
        _myBetTiger = (d['tiger'] as num?)?.toInt() ?? 0;

        if (paid && won > 0 && _lastSettledRound != roundId) {
          _lastSettledRound = roundId;
          _lastSettledWin = won;
          _playWinSound();
        }
      });
    });
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) return;
      final int now = DateTime.now().millisecondsSinceEpoch;

if (_roundId.isEmpty) {
        _advanceGameEngine(forceInit: true);
        return;
      }

      int target = _roundEndTime;
      if (_phase == "REVEALING") target = _revealEndTime;
      if (_phase == "SETTLEMENT") target = _nextRoundTime;

      final int diffSec = ((target - now) / 1000).ceil();
      setState(() {
        _remainingSec = diffSec.clamp(0, 30);
      });

      if (now >= target) {
        _advanceGameEngine();
      }
    });
  }

  Future<void> _advanceGameEngine({bool forceInit = false}) async {
    if (_isAdvancingEngine) return;
    _isAdvancingEngine = true;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(_gameDoc);
        final int now = DateTime.now().millisecondsSinceEpoch;
        final data = _asMap(snap.data());

        if (!snap.exists || data.isEmpty) {
          tx.set(_gameDoc, {
            'roundNumber': 1,
            'roundId': 'round_1_$now',
            'phase': 'BETTING',
            'roundEndTime': now + kBettingDurationMs,
            'revealEndTime': now + kBettingDurationMs + kRevealDurationMs,
            'nextRoundTime': now +
                kBettingDurationMs +
                kRevealDurationMs +
                kSettlementDurationMs,
            'pot': {'dragon': 0, 'tie': 0, 'tiger': 0},
            'dragonCard': null,
            'tigerCard': null,
            'winner': null,
            'topWinners': [],
            'history': [],
          });
          return;
        }

        final String currentPhase = (data['phase'] ?? 'BETTING').toString();
        final int roundNumber = (data['roundNumber'] as num?)?.toInt() ?? 1;
        final int roundEndTime = (data['roundEndTime'] as num?)?.toInt() ?? 0;
        final int revealEndTime =
            (data['revealEndTime'] as num?)?.toInt() ?? 0;
        final int nextRoundTime =
            (data['nextRoundTime'] as num?)?.toInt() ?? 0;

        bool shouldStartNext = false;
        if (currentPhase == 'SETTLEMENT' && now >= nextRoundTime) {
          shouldStartNext = true;
        }
        if (nextRoundTime > 0 && (now - nextRoundTime) > 15000) {
          shouldStartNext = true;
        }

        if (currentPhase == 'BETTING' && now >= roundEndTime) {
          final rng = Random.secure();
          const suits = ['S', 'H', 'D', 'C'];
          final int dRank = rng.nextInt(13) + 1;
          final int tRank = rng.nextInt(13) + 1;
          final String dSuit = suits[rng.nextInt(4)];
          final String tSuit = suits[rng.nextInt(4)];

          String winnerSide = 'tie';
          String historyCode = 'Tie';
          if (dRank > tRank) {
            winnerSide = 'dragon';
            historyCode = 'D';
          } else if (tRank > dRank) {
            winnerSide = 'tiger';
            historyCode = 'T';
          }

          final List hist = [];
          final rawHist = data['history'];
          if (rawHist is Iterable) {
            for (final h in rawHist) {
              hist.add(h.toString());
            }
          }
          hist.insert(0, historyCode);
          if (hist.length > 15) {
            hist.removeRange(15, hist.length);
          }

          tx.update(_gameDoc, {
            'phase': 'REVEALING',
            'dragonCard': {'rank': dRank, 'suit': dSuit},
            'tigerCard': {'rank': tRank, 'suit': tSuit},
            'winner': winnerSide,
            'history': hist,
            'revealEndTime': now + kRevealDurationMs,
            'nextRoundTime': now + kRevealDurationMs + kSettlementDurationMs,
          });
        } else if (currentPhase == 'REVEALING' && now >= revealEndTime) {
          tx.update(_gameDoc, {
            'phase': 'SETTLEMENT',
            'nextRoundTime': now + kSettlementDurationMs,
          });

} else if (shouldStartNext) {
          final int nextNum = roundNumber + 1;
          tx.update(_gameDoc, {
            'roundNumber': nextNum,
            'roundId': 'round_${nextNum}_$now',
            'phase': 'BETTING',
            'roundEndTime': now + kBettingDurationMs,
            'revealEndTime': now + kBettingDurationMs + kRevealDurationMs,
            'nextRoundTime': now +
                kBettingDurationMs +
                kRevealDurationMs +
                kSettlementDurationMs,
            'pot': {'dragon': 0, 'tie': 0, 'tiger': 0},
            'dragonCard': null,
            'tigerCard': null,
            'winner': null,
            'topWinners': [],
          });
        }
      });
    } catch (_) {
    } finally {
      _isAdvancingEngine = false;
    }
  }

  Future<void> _settleMyBetIfNeeded(String roundId, String winnerSide) async {
    if (_isSettlingMyBet) return;
    if (_resolvedUid.isEmpty) return;
    if (roundId.isEmpty) return;
    if (_lastSettledRound == roundId) return;

    _isSettlingMyBet = true;
    try {
      final betRef = _gameDoc
          .collection('rounds')
          .doc(roundId)
          .collection('bets')
          .doc(_resolvedUid);
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_resolvedUid);

      int creditedWin = 0;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final betSnap = await tx.get(betRef);
        if (!betSnap.exists) return;

        final betData = _asMap(betSnap.data());
        if (betData.isEmpty) return;
        if (betData['paid'] == true) return;

        final int dBet = (betData['dragon'] as num?)?.toInt() ?? 0;
        final int tBet = (betData['tiger'] as num?)?.toInt() ?? 0;
        final int tieBet = (betData['tie'] as num?)?.toInt() ?? 0;

        int winAmount = 0;
        if (winnerSide == 'dragon' && dBet > 0) {
          winAmount = dBet * 2;
        } else if (winnerSide == 'tiger' && tBet > 0) {
          winAmount = tBet * 2;
        } else if (winnerSide == 'tie' && tieBet > 0) {
          winAmount = tieBet * 22;
        }

        tx.update(betRef, {
          'paid': true,
          'wonAmount': winAmount,
          'settledAt': FieldValue.serverTimestamp(),
        });

        if (winAmount > 0) {
          tx.update(userRef, {
            'coins': FieldValue.increment(winAmount),
          });
          tx.update(_gameDoc, {
            'topWinners': FieldValue.arrayUnion([
              {
                'uid': _resolvedUid,
                'name': _resolvedName,
                'wonAmount': winAmount,
              }
            ]),
          });
          creditedWin = winAmount;
        }
      });

      if (creditedWin > 0 && mounted) {
        setState(() {
          _lastSettledRound = roundId;
          _lastSettledWin = creditedWin;
        });
        _playWinSound();
      }
    } catch (_) {
    } finally {
      _isSettlingMyBet = false;
    }
  }

  void _playWinSound() async {
    try {
      final player = AudioPlayer();
      await player.setVolume(1.0);
      try {
        await player.play(AssetSource('sounds/Five_win.mp3'));
      } catch (_) {
        await player.play(AssetSource('sounds/five_win.mp3'));
      }
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {}
  }

  void _showNotice(String text) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() => _statusBanner = text);
    _bannerTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusBanner = null);
    });
  }

  Future<void> _placeBet(String side) async {
    if (_isPlacingBet) return;
    if (_roundId.isEmpty) {
      await _advanceGameEngine(forceInit: true);
      return;
    }
    if (_phase != "BETTING") {

_showNotice("Betting closed! Wait for next round.");
      return;
    }
    if (_remainingSec <= 1) {
      _showNotice("Betting closed! Wait for next round.");
      return;
    }
    if (_resolvedUid.isEmpty) {
      _showNotice("Please sign in to play.");
      return;
    }
    if (_myCoins < _selectedChip) {
      _showNotice("Insufficient coins balance!");
      return;
    }

    setState(() => _isPlacingBet = true);

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_resolvedUid);
      final betRef = _gameDoc
          .collection('rounds')
          .doc(_roundId)
          .collection('bets')
          .doc(_resolvedUid);

      final int betAmount = _selectedChip;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final gameSnap = await tx.get(_gameDoc);

        if (!userSnap.exists) {
          throw Exception("Account not ready");
        }
        if (!gameSnap.exists) {
          throw Exception("Game not ready");
        }

        final userData = _asMap(userSnap.data());
        final gameData = _asMap(gameSnap.data());

        final int currentCoins = (userData['coins'] as num?)?.toInt() ?? 0;
        final String livePhase = (gameData['phase'] ?? '').toString();

        if (livePhase != 'BETTING') {
          throw Exception("Betting closed for this round");
        }
        if (currentCoins < betAmount) {
          throw Exception("Insufficient coins balance!");
        }

        tx.update(userRef, {
          'coins': currentCoins - betAmount,
        });

        tx.update(_gameDoc, {
          'pot.$side': FieldValue.increment(betAmount),
        });

        tx.set(
          betRef,
          {
            'uid': _resolvedUid,
            'name': _resolvedName,
            'numericId': _resolvedNumericId,
            'roomId': widget.roomId,
            side: FieldValue.increment(betAmount),
            'paid': false,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showNotice(msg.isNotEmpty ? msg : "Could not place bet, try again.");
    } finally {
      if (mounted) setState(() => _isPlacingBet = false);
    }
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _userSub?.cancel();
    _myBetSub?.cancel();
    _clockTimer?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  String _formatNum(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 10000) return "${(n / 1000).toStringAsFixed(1)}K";
    return "$n";
  }

  String _rankLabel(int rank) {
    if (rank == 1) return "A";
    if (rank == 11) return "J";
    if (rank == 12) return "Q";
    if (rank == 13) return "K";
    return "$rank";
  }

  String _suitSymbol(String suit) {
    if (suit == 'H') return "♥";
    if (suit == 'D') return "♦";
    if (suit == 'C') return "♣";
    return "♠";
  }

  Widget _buildCardBack(Color accentColor) {
    return Container(
      width: 68,
      height: 94,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [accentColor, const Color(0xFF1A100B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: kGold, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: kGold, size: 28),
      ),
    );
  }

  Widget _buildPlayingCard(Map? card, Color accentColor) {
    bool isRevealPhase = false;
    if (_phase == "REVEALING") isRevealPhase = true;
    if (_phase == "SETTLEMENT") isRevealPhase = true;

if (!isRevealPhase) {
      return _buildCardBack(accentColor);
    }
    if (card == null) {
      return _buildCardBack(accentColor);
    }

    final int rank = (card['rank'] as num?)?.toInt() ?? 1;
    final String suit = (card['suit'] ?? 'S').toString();
    bool isRed = false;
    if (suit == 'H') isRed = true;
    if (suit == 'D') isRed = true;

    final Color cardColor =
        isRed ? const Color(0xFFC62828) : const Color(0xFF1A1A1A);

    return Container(
      width: 68,
      height: 94,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGold, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.55),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              "${_rankLabel(rank)}${_suitSymbol(suit)}",
              style: TextStyle(
                color: cardColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            _suitSymbol(suit),
            style: TextStyle(color: cardColor, fontSize: 28),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _rankLabel(rank),
              style: TextStyle(
                color: cardColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetBox({
    required String side,
    required String title,
    required String multiplier,
    required int pot,
    required int myBet,
    required Color baseColor,
  }) {
    bool isRevealPhase = false;
    if (_phase == "REVEALING") isRevealPhase = true;
    if (_phase == "SETTLEMENT") isRevealPhase = true;

    final bool isWinner = isRevealPhase && _winner == side;

    return Expanded(
      child: GestureDetector(
        onTap: () => _placeBet(side),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor.withOpacity(isWinner ? 0.95 : 0.65),
                const Color(0xFF1A110B),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isWinner ? kGold : kGoldBorder.withOpacity(0.75),
              width: isWinner ? 2.6 : 1.2,
            ),
            boxShadow: [
              if (isWinner)
                BoxShadow(
                  color: kGold.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(

color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  multiplier,
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "POT: ${_formatNum(pot)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: myBet > 0 ? kGold : Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "ME: ${_formatNum(myBet)}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: myBet > 0 ? Colors.black : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
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
    bool isRevealPhase = false;
    if (_phase == "REVEALING") isRevealPhase = true;
    if (_phase == "SETTLEMENT") isRevealPhase = true;

    String phaseText = "BETTING: ${_remainingSec}s";
    Color phaseColor = const Color(0xFF107C41);

    if (_phase == "REVEALING") {
      phaseText = "REVEALING CARDS...";
      phaseColor = const Color(0xFFD84315);
    } else if (_phase == "SETTLEMENT") {
      phaseText = "NEXT ROUND: ${_remainingSec}s";
      phaseColor = const Color(0xFF6A1B9A);
    }

    return Container(
      decoration: const BoxDecoration(
        color: kBgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: kGoldBorder, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Text(
                  "🐉 DRAGON vs TIGER 🐅",
                  style: TextStyle(
                    color: kGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kCardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kGoldBorder, width: 0.8),
                  ),
                  child: Text(
                    "#$_roundNumber",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

decoration: BoxDecoration(
                    color: kCardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kGold, width: 1.1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: kGold, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        "$_myCoins",
                        style: const TextStyle(
                          color: kGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
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

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: phaseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    phaseText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _history.length,
                      itemBuilder: (ctx, idx) {
                        final item = _history[idx].toString();
                        Color c = kTieGreen;
                        if (item == "D") c = kDragonRed;
                        if (item == "T") c = kTigerAmber;
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.white24, width: 0.7),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kGoldBorder.withOpacity(0.5)),

),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        "🐉 DRAGON",
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildPlayingCard(_dragonCard, kDragonRed),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        "VS",
                        style: TextStyle(
                          color: kGold,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_winner != null && isRevealPhase)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${_winner!.toUpperCase()} WINS!",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        "🐅 TIGER",
                        style: TextStyle(
                          color: Color(0xFFFFAB40),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildPlayingCard(_tigerCard, kTigerAmber),
                    ],
                  ),
                ],
              ),
            ),

            if (_lastSettledWin > 0 && _phase == "SETTLEMENT")
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF107C41),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kGold),
                ),
                child: Text(
                  "🎉 YOU WON +$_lastSettledWin COINS!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),

            if (_topWinners.isNotEmpty && _phase == "SETTLEMENT")
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

const Text(
                      "🏆 Top: ",
                      style: TextStyle(
                        color: kGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ..._topWinners.take(3).map((item) {
                      final w = _asMap(item);
                      final int wonAmt = (w['wonAmount'] as num?)?.toInt() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          "${w['name']} (+${_formatNum(wonAmt)})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            if (_statusBanner != null)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusBanner!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Row(
              children: [
                _buildBetBox(
                  side: "dragon",
                  title: "DRAGON",
                  multiplier: "X2",
                  pot: _potDragon,
                  myBet: _myBetDragon,
                  baseColor: kDragonRed,
                ),
                _buildBetBox(
                  side: "tie",
                  title: "TIE",
                  multiplier: "X22",
                  pot: _potTie,
                  myBet: _myBetTie,
                  baseColor: kTieGreen,
                ),
                _buildBetBox(
                  side: "tiger",
                  title: "TIGER",
                  multiplier: "X2",
                  pot: _potTiger,
                  myBet: _myBetTiger,
                  baseColor: kTigerAmber,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _chips.map((chip) {
                final int chipVal = (chip as num).toInt();
                final bool selected = _selectedChip == chipVal;
                return GestureDetector(
                  onTap: () => setState(() => _selectedChip = chipVal),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: selected
                            ? [kGold, const Color(0xFFB8860B)]
                            : [
                                const Color(0xFF3A281E),
                                const Color(0xFF1D130D)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

border: Border.all(
                        color: selected ? Colors.white : kGoldBorder,
                        width: selected ? 2.2 : 1.0,
                      ),
                    ),
                    child: Text(
                      _formatNum(chipVal),
                      style: TextStyle(
                        color: selected ? Colors.black : kGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
