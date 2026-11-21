import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

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

class _LandedChip {
  final int value;
  final double dx;
  final double dy;
  final double angle;

  const _LandedChip({
    required this.value,
    required this.dx,
    required this.dy,
    required this.angle,
  });
}

class _FlyingCoin {
  final int id;
  final int value;
  final String targetSide;
  final double startX;
  final double targetX;
  final double targetY;

  const _FlyingCoin({
    required this.id,
    required this.value,
    required this.targetSide,
    required this.startX,
    required this.targetX,
    required this.targetY,
  });
}

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
      builder: (ctx) {
        return DragonTigerSheet(
          roomId: roomId,
          userName: userName,
          userUid: userUid,
          userNumericId: userNumericId,
        );
      },
    );
  }

  @override
  State createState() {
    return _DragonTigerSheetState();
  }
}

class _DragonTigerSheetState extends State with TickerProviderStateMixin {
  DragonTigerSheet get _w {
    return widget as DragonTigerSheet;
  }

  static const Color kGold = Color(0xFFFFD700);
  static const Color kGoldLight = Color(0xFFFEF08A);
  static const Color kGoldBorder = Color(0xFFD49B42);
  static const Color kDragonRed = Color(0xFFDC2626);
  static const Color kTigerBlue = Color(0xFF2563EB);
  static const Color kTieGreen = Color(0xFF16A34A);

  static const int kBettingDurationMs = 15000;
  static const int kRevealDurationMs = 3000;
  static const int kSettlementDurationMs = 4000;

  final List _chips = [100, 500, 1000, 5000, 10000, 50000];
  int _selectedChip = 100;
  final Random _rng = Random();

  String _resolvedUid = "";
  String _resolvedName = "Player";
  int _resolvedNumericId = 0;

  int _myCoins = 0;
  int _remainingSec = 15;
  int _pingMs = 186;

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

  // Optimistic instant-touch deltas so rapid taps respond in 0ms
  int _pendingCoinsSpend = 0;
  int _pendingDragon = 0;
  int _pendingTie = 0;
  int _pendingTiger = 0;

  // Previous round bets for Repeat button
  int _prevBetDragon = 0;
  int _prevBetTie = 0;
  int _prevBetTiger = 0;

  // Visual landed & flying chips
  final List _dragonChips = [];
  final List _tieChips = [];
  final List _tigerChips = [];
  final List _flyingCoins = [];
  int _flightSeq = 0;

  Map? _dragonCard;
  Map? _tigerCard;
  String? _winner;
  List _topWinners = [];
  List _history = [];

  int _lastSettledWin = 0;
  String _lastSettledRound = "";
  String? _statusBanner;
  bool _isAdvancingEngine = false;
  bool _isSettlingMyBet = false;

  StreamSubscription? _gameSub;
  StreamSubscription? _userSub;
  StreamSubscription? _myBetSub;
  Timer? _clockTimer;
  Timer? _bannerTimer;
  late AnimationController _pulseCtrl;

DocumentReference get _gameDoc {
    return FirebaseFirestore.instance.collection('games').doc('dragon_tiger');
  }

  int get _effectiveCoins {
    final int val = _myCoins - _pendingCoinsSpend;
    if (_lt(val, 0)) return 0;
    return val;
  }

  int get _effectiveMyDragon {
    return _myBetDragon + _pendingDragon;
  }

  int get _effectiveMyTie {
    return _myBetTie + _pendingTie;
  }

  int get _effectiveMyTiger {
    return _myBetTiger + _pendingTiger;
  }

  int get _effectivePotDragon {
    return _potDragon + _pendingDragon;
  }

  int get _effectivePotTie {
    return _potTie + _pendingTie;
  }

  int get _effectivePotTiger {
    return _potTiger + _pendingTiger;
  }

  Map _asMap(Object? raw) {
    if (raw is Map) {
      return Map.from(raw);
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _initPlayerIdentity();
    _ensureGameInitialized();
    _listenToGameStream();
    _startClockTimer();
  }

  Future _initPlayerIdentity() async {
    final authUser = FirebaseAuth.instance.currentUser;
    String uid = "";
    final String passedUid = _w.userUid ?? "";
    if (passedUid.isNotEmpty && passedUid != "user_guest_id") {
      uid = passedUid;
    } else if (authUser != null) {
      uid = authUser.uid;
    }

    _resolvedUid = uid;
    _resolvedName = _w.userName.isNotEmpty ? _w.userName : "Player";
    _resolvedNumericId = _w.userNumericId ?? 0;

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

  Future _ensureGameInitialized() async {
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
      // Save previous round bets for Repeat button
      final int prevTotal =
          _effectiveMyDragon + _effectiveMyTie + _effectiveMyTiger;
      if (_gt(prevTotal, 0)) {
        _prevBetDragon = _effectiveMyDragon;
        _prevBetTie = _effectiveMyTie;
        _prevBetTiger = _effectiveMyTiger;
      }

      _roundId = newRoundId;
      _myBetDragon = 0;
      _myBetTie = 0;
      _myBetTiger = 0;
      _pendingDragon = 0;
      _pendingTie = 0;
      _pendingTiger = 0;
      _pendingCoinsSpend = 0;
      _lastSettledWin = 0;
      _dragonChips.clear();
      _tieChips.clear();
      _tigerChips.clear();
      _flyingCoins.clear();
      _subscribeToMyRoundBet(newRoundId);
    }

    final potMap = _asMap(d['pot']);
    final int nextPotD = (potMap['dragon'] as num?)?.toInt() ?? 0;
    final int nextPotTie = (potMap['tie'] as num?)?.toInt() ?? 0;
    final int nextPotT = (potMap['tiger'] as num?)?.toInt() ?? 0;

// Trigger flying coins when other players bet in the room
    if (_gt(nextPotD, _potDragon + _pendingDragon)) {
      _launchFlyingCoin("dragon", 1000, fromOtherPlayer: true);
    }
    if (_gt(nextPotTie, _potTie + _pendingTie)) {
      _launchFlyingCoin("tie", 1000, fromOtherPlayer: true);
    }
    if (_gt(nextPotT, _potTiger + _pendingTiger)) {
      _launchFlyingCoin("tiger", 1000, fromOtherPlayer: true);
    }

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

      _potDragon = nextPotD;
      _potTie = nextPotTie;
      _potTiger = nextPotT;

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

        if (paid && _gt(won, 0) && _lastSettledRound != roundId) {
          _lastSettledRound = roundId;
          _lastSettledWin = won;
          _playWinSound();
        }
      });
    });
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
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
        if (now % 1000 == 0) {
          _pingMs = 172 + _rng.nextInt(38);
        }
      });

      if (_gte(now, target)) {
        _advanceGameEngine();
      }
    });
  }

  Future _advanceGameEngine({bool forceInit = false}) async {
    if (_isAdvancingEngine) return;
    _isAdvancingEngine = true;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(_gameDoc);
        final int now = DateTime.now().millisecondsSinceEpoch;
        final data = _asMap(snap.data());

if (!snap.exists || data.isEmpty) {
          tx.set(_gameDoc, {
            'roundNumber': _d(1),
            'roundId': _d('round_1_$now'),
            'phase': _d('BETTING'),
            'roundEndTime': _d(now + kBettingDurationMs),
            'revealEndTime': _d(now + kBettingDurationMs + kRevealDurationMs),
            'nextRoundTime': _d(now +
                kBettingDurationMs +
                kRevealDurationMs +
                kSettlementDurationMs),
            'pot': _d({'dragon': 0, 'tie': 0, 'tiger': 0}),
            'dragonCard': _d(null),
            'tigerCard': _d(null),
            'winner': _d(null),
            'topWinners': _d([]),
            'history': _d([]),
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
        if (currentPhase == 'SETTLEMENT' && _gte(now, nextRoundTime)) {
          shouldStartNext = true;
        }
        if (_gt(nextRoundTime, 0) && _gt(now - nextRoundTime, 15000)) {
          shouldStartNext = true;
        }

        if (currentPhase == 'BETTING' && _gte(now, roundEndTime)) {
          final rng = Random.secure();
          const suits = ['S', 'H', 'D', 'C'];
          final int dRank = rng.nextInt(13) + 1;
          final int tRank = rng.nextInt(13) + 1;
          final String dSuit = suits[rng.nextInt(4)];
          final String tSuit = suits[rng.nextInt(4)];

          String winnerSide = 'tie';
          String historyCode = 'Tie';
          if (_gt(dRank, tRank)) {
            winnerSide = 'dragon';
            historyCode = 'D';
          } else if (_gt(tRank, dRank)) {
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
          if (_gt(hist.length, 15)) {
            hist.removeRange(15, hist.length);
          }

          tx.update(_gameDoc, {
            'phase': _d('REVEALING'),
            'dragonCard': _d({'rank': dRank, 'suit': dSuit}),
            'tigerCard': _d({'rank': tRank, 'suit': tSuit}),
            'winner': _d(winnerSide),
            'history': _d(hist),
            'revealEndTime': _d(now + kRevealDurationMs),
            'nextRoundTime':
                _d(now + kRevealDurationMs + kSettlementDurationMs),
          });
        } else if (currentPhase == 'REVEALING' && _gte(now, revealEndTime)) {
          tx.update(_gameDoc, {
            'phase': _d('SETTLEMENT'),
            'nextRoundTime': _d(now + kSettlementDurationMs),
          });
        } else if (shouldStartNext) {
          final int nextNum = roundNumber + 1;
          tx.update(_gameDoc, {
            'roundNumber': _d(nextNum),
            'roundId': _d('round_${nextNum}_$now'),
            'phase': _d('BETTING'),
            'roundEndTime': _d(now + kBettingDurationMs),
            'revealEndTime': _d(now + kBettingDurationMs + kRevealDurationMs),
            'nextRoundTime': _d(now +
                kBettingDurationMs +
                kRevealDurationMs +
                kSettlementDurationMs),
            'pot': _d({'dragon': 0, 'tie': 0, 'tiger': 0}),
            'dragonCard': _d(null),
            'tigerCard': _d(null),
            'winner': _d(null),
            'topWinners': _d([]),
          });
        }
      });
    } catch (_) {
    } finally {
      _isAdvancingEngine = false;
    }
  }

Future _settleMyBetIfNeeded(String roundId, String winnerSide) async {
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
        if (winnerSide == 'dragon' && _gt(dBet, 0)) {
          winAmount = dBet * 2;
        } else if (winnerSide == 'tiger' && _gt(tBet, 0)) {
          winAmount = tBet * 2;
        } else if (winnerSide == 'tie' && _gt(tieBet, 0)) {
          winAmount = tieBet * 22;
        }

        tx.update(betRef, {
          'paid': _d(true),
          'wonAmount': _d(winAmount),
          'settledAt': _d(FieldValue.serverTimestamp()),
        });

        if (_gt(winAmount, 0)) {
          tx.update(userRef, {
            'coins': _d(FieldValue.increment(winAmount)),
          });
          tx.update(_gameDoc, {
            'topWinners': _d(FieldValue.arrayUnion([
              {
                'uid': _resolvedUid,
                'name': _resolvedName,
                'wonAmount': winAmount,
              }
            ])),
          });
          creditedWin = winAmount;
        }
      });

      if (_gt(creditedWin, 0) && mounted) {
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
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {}
  }

  void _showNotice(String text) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _statusBanner = text;
    });
    _bannerTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusBanner = null;
        });
      }
    });
  }

  // Launch a diamond coin flying into the selected betting area
  void _launchFlyingCoin(String side, int chipValue,
      {bool fromOtherPlayer = false}) {
    if (!mounted) return;
    _flightSeq += 1;
    final int id = _flightSeq;

    double targetX = 0.0;
    if (side == "dragon") {
      targetX = -0.66 + ((_rng.nextDouble() * 0.22) - 0.11);
    } else if (side == "tiger") {
      targetX = 0.66 + ((_rng.nextDouble() * 0.22) - 0.11);
    } else {
      targetX = (_rng.nextDouble() * 0.20) - 0.10;
    }

    double startX = 0.0;
    if (fromOtherPlayer) {
      startX = _rng.nextBool() ? -0.92 : 0.92;
    } else {
      final int idx = _chips.indexOf(chipValue);
      if (_gte(idx, 0)) {
        startX = -0.52 + (idx * 0.20);
      }
    }

    final flight = _FlyingCoin(
      id: id,
      value: chipValue,
      targetSide: side,
      startX: startX,
      targetX: targetX,
      targetY: 0.24 + ((_rng.nextDouble() * 0.16) - 0.08),
    );

    setState(() {
      _flyingCoins.add(flight);
    });

Future.delayed(const Duration(milliseconds: 340), () {
      if (!mounted) return;
      setState(() {
        _flyingCoins.removeWhere((item) {
          return (item as _FlyingCoin).id == id;
        });
        final landed = _LandedChip(
          value: chipValue,
          dx: (_rng.nextDouble() * 44) - 22,
          dy: (_rng.nextDouble() * 34) - 17,
          angle: (_rng.nextDouble() * 0.5) - 0.25,
        );
        if (side == "dragon") {
          _dragonChips.add(landed);
          if (_gt(_dragonChips.length, 32)) _dragonChips.removeAt(0);
        } else if (side == "tie") {
          _tieChips.add(landed);
          if (_gt(_tieChips.length, 32)) _tieChips.removeAt(0);
        } else {
          _tigerChips.add(landed);
          if (_gt(_tigerChips.length, 32)) _tigerChips.removeAt(0);
        }
      });
    });
  }

  // Ultra-fast optimistic bet placement (0ms touch latency)
  Future _placeBet(String side, {int? customAmount}) async {
    if (_roundId.isEmpty) {
      await _advanceGameEngine(forceInit: true);
      return;
    }
    if (_phase != "BETTING" || _lte(_remainingSec, 1)) {
      _showNotice("Betting closed! Wait for next round.");
      return;
    }
    if (_resolvedUid.isEmpty) {
      _showNotice("Please sign in to play.");
      return;
    }

    final int betAmount = customAmount ?? _selectedChip;
    if (_lt(_effectiveCoins, betAmount)) {
      _showNotice("Insufficient coins balance!");
      return;
    }

    HapticFeedback.lightImpact();
    _launchFlyingCoin(side, betAmount);

    // 1. Instant local update so user sees coin fly and balance update immediately
    setState(() {
      _pendingCoinsSpend += betAmount;
      if (side == "dragon") _pendingDragon += betAmount;
      if (side == "tie") _pendingTie += betAmount;
      if (side == "tiger") _pendingTiger += betAmount;
    });

    // 2. Sync to Firestore in background using your exact working transaction
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_resolvedUid);
      final betRef = _gameDoc
          .collection('rounds')
          .doc(_roundId)
          .collection('bets')
          .doc(_resolvedUid);

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
        if (_lt(currentCoins, betAmount)) {
          throw Exception("Insufficient coins balance!");
        }

        tx.update(userRef, {
          'coins': _d(currentCoins - betAmount),
        });

        tx.update(_gameDoc, {
          'pot.$side': _d(FieldValue.increment(betAmount)),
        });

        tx.set(
          betRef,
          {
            'uid': _d(_resolvedUid),
            'name': _d(_resolvedName),
            'numericId': _d(_resolvedNumericId),
            'roomId': _d(_w.roomId),
            side: _d(FieldValue.increment(betAmount)),
            'paid': _d(false),
            'updatedAt': _d(FieldValue.serverTimestamp()),
          },
          SetOptions(merge: true),
        );
      });

      if (mounted) {
        setState(() {
          _pendingCoinsSpend =
              (_pendingCoinsSpend - betAmount).clamp(0, 999999999);
          if (side == "dragon") {

_pendingDragon = (_pendingDragon - betAmount).clamp(0, 999999999);
          }
          if (side == "tie") {
            _pendingTie = (_pendingTie - betAmount).clamp(0, 999999999);
          }
          if (side == "tiger") {
            _pendingTiger = (_pendingTiger - betAmount).clamp(0, 999999999);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingCoinsSpend =
              (_pendingCoinsSpend - betAmount).clamp(0, 999999999);
          if (side == "dragon") {
            _pendingDragon = (_pendingDragon - betAmount).clamp(0, 999999999);
          }
          if (side == "tie") {
            _pendingTie = (_pendingTie - betAmount).clamp(0, 999999999);
          }
          if (side == "tiger") {
            _pendingTiger = (_pendingTiger - betAmount).clamp(0, 999999999);
          }
        });
        final msg = e.toString().replaceFirst('Exception: ', '');
        _showNotice(msg.isNotEmpty ? msg : "Could not place bet, try again.");
      }
    }
  }

  Future _repeatPreviousRound() async {
    if (_phase != "BETTING" || _lte(_remainingSec, 1)) {
      _showNotice("Wait for betting time to repeat.");
      return;
    }
    final int needed = _prevBetDragon + _prevBetTie + _prevBetTiger;
    if (_lte(needed, 0)) {
      _showNotice("No previous round bet to repeat.");
      return;
    }
    if (_lt(_effectiveCoins, needed)) {
      _showNotice("Insufficient coins to repeat!");
      return;
    }
    if (_gt(_prevBetDragon, 0)) {
      _placeBet("dragon", customAmount: _prevBetDragon);
    }
    if (_gt(_prevBetTie, 0)) {
      _placeBet("tie", customAmount: _prevBetTie);
    }
    if (_gt(_prevBetTiger, 0)) {
      _placeBet("tiger", customAmount: _prevBetTiger);
    }
  }

  void _openRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F120D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: kGoldBorder, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: kGold),
              SizedBox(width: 8),
              Text(
                "Dragon vs Tiger Rules",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "1. Select a diamond chip and tap Dragon, Tie, or Tiger during the countdown.\n\n"
            "2. Two cards are drawn (A=1 up to K=13). Higher card wins!\n"
            "   • Dragon Wins: X2 Payout\n"
            "   • Tiger Wins: X2 Payout\n"
            "   • Tie (Equal Ranks): X22 Payout",
            style:
                TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.45),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kGoldBorder),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("Got It",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _userSub?.cancel();
    _myBetSub?.cancel();
    _clockTimer?.cancel();
    _bannerTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatNum(int n) {
    if (_gte(n, 1000000)) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (_gte(n, 1000)) {
      if (n % 1000 == 0) return "${n ~/ 1000}K";
      return "${(n / 1000).toStringAsFixed(1)}K";
    }
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

  Color _chipColor(int val) {
    if (_gte(val, 50000)) return const Color(0xFFEC4899);
    if (_gte(val, 10000)) return const Color(0xFF8B5CF6);
    if (_gte(val, 5000)) return const Color(0xFF06B6D4);
    if (_gte(val, 1000)) return const Color(0xFF3B82F6);
    if (_gte(val, 500)) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  Widget _buildCardBack(bool isDragon) {
    return Container(
      width: 68,
      height: 94,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: isDragon
              ? [const Color(0xFFDC2626), const Color(0xFF7F1D1D)]
              : [const Color(0xFF2563EB), const Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: isDragon ? kGold : const Color(0xFF7DD3FC), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 46,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: (isDragon ? kGold : const Color(0xFFBAE6FD))
                  .withOpacity(0.45),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              isDragon
                  ? Icons.local_fire_department_rounded
                  : Icons.bolt_rounded,
              color: isDragon ? kGold : const Color(0xFFBAE6FD),
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayingCard(Map? card, bool isDragon) {
    bool isRevealPhase = false;
    if (_phase == "REVEALING") isRevealPhase = true;
    if (_phase == "SETTLEMENT") isRevealPhase = true;

    if (!isRevealPhase || card == null) {
      return _buildCardBack(isDragon);
    }

    final int rank = (card['rank'] as num?)?.toInt() ?? 1;
    final String suit = (card['suit'] ?? 'S').toString();
    bool isRed = false;
    if (suit == 'H') isRed = true;
    if (suit == 'D') isRed = true;

    final Color cardColor =
        isRed ? const Color(0xFFDC2626) : const Color(0xFF1E293B);

    return Container(
      width: 68,
      height: 94,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGold, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: (isDragon ? kDragonRed : kTigerBlue).withOpacity(0.65),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Column(
              children: [
                Text(
                  _rankLabel(rank),
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                Text(
                  _suitSymbol(suit),
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              _rankLabel(rank),
              style: TextStyle(
                color: cardColor,
                fontSize: 34,
                fontWeight: FontWeight.w900,
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
    required List landedChips,
    required Color boxTint,
    required Color borderHue,
    required IconData watermarkIcon,
  }) {
    bool isRevealPhase = false;
    if (_phase == "REVEALING") isRevealPhase = true;
    if (_phase == "SETTLEMENT") isRevealPhase = true;

    final bool isWinner = isRevealPhase && _winner == side;

    return Expanded(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          _placeBet(side);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 158,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                boxTint.withOpacity(isWinner ? 0.85 : 0.55),
                Colors.black.withOpacity(0.65),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isWinner ? kGoldLight : borderHue,
              width: isWinner ? 2.6 : 1.4,
            ),
            boxShadow: [
              if (isWinner)
                BoxShadow(
                  color: kGold.withOpacity(0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (side == "tie")
                Text(
                  "Tie",
                  style: TextStyle(
                    color: kGold.withOpacity(0.24),
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                Icon(
                  watermarkIcon,
                  size: 74,
                  color: Colors.white.withOpacity(0.11),
                ),

              // Landed Diamond Chips Pile
              ...landedChips.map((raw) {
                final c = raw as _LandedChip;
                return Transform.translate(
                  offset: Offset(c.dx, c.dy),
                  child: Transform.rotate(
                    angle: c.angle,
                    child: CustomPaint(
                      size: const Size(20, 20),
                      painter: _DiamondChipPainter(
                        baseColor: _chipColor(c.value),
                        isSelected: false,
                      ),
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
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    multiplier,
                    style: const TextStyle(
                      color: kGoldLight,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),

const SizedBox(height: 2),
                  Text(
                    "POT:${_formatNum(pot)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: _gt(myBet, 0)
                          ? kGold.withOpacity(0.92)
                          : Colors.black38,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      "ME:${_formatNum(myBet)}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _gt(myBet, 0) ? Colors.black : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementModal() {
    final int totalMyBet =
        _effectiveMyDragon + _effectiveMyTie + _effectiveMyTiger;
    String winTitle = "Tie Win";
    IconData emblem = Icons.balance_rounded;
    if (_winner == "dragon") {
      winTitle = "Dragon Win";
      emblem = Icons.local_fire_department_rounded;
    } else if (_winner == "tiger") {
      winTitle = "Tiger Win";
      emblem = Icons.bolt_rounded;
    }

    return Container(
      color: Colors.black.withOpacity(0.72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            border: Border.all(color: kGold, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kGoldLight, width: 1),
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
              Icon(emblem, color: kGold, size: 46),
              Text(
                winTitle,
                style: const TextStyle(
                  color: kGoldLight,
                  fontSize: 15,

fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The top victors of this round",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 8),
              if (_topWinners.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _topWinners.take(3).map((raw) {
                    final w = _asMap(raw);
                    final int wonAmt = (w['wonAmount'] as num?)?.toInt() ?? 0;
                    return Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.workspace_premium,
                              color: kGold, size: 20),
                          const CircleAvatar(
                            radius: 19,
                            backgroundColor: kGold,
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: Color(0xFF1F2937),
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (w['name'] ?? 'Player').toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Win ${_formatNum(wonAmt)}",
                            style: const TextStyle(
                              color: kGold,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Next round starting soon...",
                    style: TextStyle(color: Colors.white60, fontSize: 11.5),
                  ),
                ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGold.withOpacity(0.45)),
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
                        _resolvedName,
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
                          "Bet   ${_formatNum(totalMyBet)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Win   ${_formatNum(_lastSettledWin)}",
                          style: const TextStyle(
                            color: kGold,
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

  @override
  Widget build(BuildContext context) {
    bool isRevealPhase = false;
    if (_phase == "REVEALING") isRevealPhase = true;
    if (_phase == "SETTLEMENT") isRevealPhase = true;

    bool showDrawingBanner = false;
    if (_phase == "REVEALING" && _winner == null) {
      showDrawingBanner = true;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: kGoldBorder, width: 1.5)),
        ),
        child: CustomPaint(
          painter: _DragonTigerBgPainter(),
          child: SafeArea(
            top: false,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Top Controls Bar (Title, Round #, Help ?, Close, Ping ms)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.keyboard_arrow_down,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 2),
                                  Text(
                                    "Dragon vs Tiger #$_roundNumber",
                                    style: const TextStyle(
                                      color: kGoldLight,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _openRulesDialog,
                            child: Container(
                              width: 24,

height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF59E0B),
                                border: Border.all(color: kGoldLight, width: 1),
                              ),
                              child: const Icon(Icons.question_mark_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black45,
                                border:
                                    Border.all(color: Colors.white30, width: 1),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.wifi,
                                  color: Color(0xFF4ADE80), size: 13),
                              const SizedBox(width: 2),
                              Text(
                                "${_pingMs}ms",
                                style: const TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 2. Center Cards & Timer / VS / Winner Ribbon
                      SizedBox(
                        height: 104,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildPlayingCard(_dragonCard, true),
                                const SizedBox(width: 66),
                                _buildPlayingCard(_tigerCard, false),
                              ],
                            ),

                            // Countdown Clock Badge (Matches Video Center Timer)
                            if (_phase == "BETTING")
                              AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, child) {
                                  final double s = _lte(_remainingSec, 5)
                                      ? (0.95 + _pulseCtrl.value * 0.14)
                                      : 1.0;
                                  return Transform.scale(
                                      scale: s, child: child);
                                },
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,

gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFF78350F),
                                        Color(0xFF451A03),
                                      ],
                                    ),
                                    border: Border.all(
                                        color: kGoldLight, width: 3.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kGold.withOpacity(0.55),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "$_remainingSec",
                                      style: TextStyle(
                                        color: _lte(_remainingSec, 5)
                                            ? const Color(0xFFF87171)
                                            : Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Text(
                                "VS",
                                style: TextStyle(
                                  color: kGold,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),

                            // Winner Ribbon Banner across cards
                            if (_winner != null && isRevealPhase)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 26, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _winner == "tiger"
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
                                  borderRadius: BorderRadius.circular(18),
                                  border:
                                      Border.all(color: kGoldLight, width: 2.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.6),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _winner == "dragon"
                                      ? "Dragon Win"
                                      : (_winner == "tiger"

? "Tiger Win"
                                          : "Tie Win!"),
                                  style: const TextStyle(
                                    color: kGoldLight,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 3. Result History Orbs Strip
                      Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Result:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _history.length,
                                itemBuilder: (ctx, idx) {
                                  final String item = _history[idx].toString();
                                  Color orbColor = kTieGreen;
                                  if (item == "D") orbColor = kDragonRed;
                                  if (item == "T") orbColor = kTigerBlue;
                                  return Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: orbColor,
                                      border: Border.all(
                                          color: kGoldLight, width: 1.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item == "Tie" ? "=" : item,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
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

                      if (_statusBanner != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
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

                      const SizedBox(height: 8),

                      // 4. Three Betting Boxes (Dragon X2 | Tie X22 | Tiger X2)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            children: [
                              _buildBetBox(
                                side: "dragon",
                                title: "Dragon",
                                multiplier: "X2",
                                pot: _effectivePotDragon,
                                myBet: _effectiveMyDragon,
                                landedChips: _dragonChips,
                                boxTint: const Color(0xFF991B1B),
                                borderHue: const Color(0xFFF97316),
                                watermarkIcon:
                                    Icons.local_fire_department_rounded,
                              ),
                              _buildBetBox(
                                side: "tie",
                                title: "Tie",
                                multiplier: "X22",
                                pot: _effectivePotTie,
                                myBet: _effectiveMyTie,
                                landedChips: _tieChips,
                                boxTint: const Color(0xFF78350F),
                                borderHue: kGold,
                                watermarkIcon: Icons.balance_rounded,
                              ),
                              _buildBetBox(
                                side: "tiger",
                                title: "Tiger",
                                multiplier: "X2",
                                pot: _effectivePotTiger,
                                myBet: _effectiveMyTiger,
                                landedChips: _tigerChips,
                                boxTint: const Color(0xFF1E3A8A),
                                borderHue: const Color(0xFF38BDF8),
                                watermarkIcon: Icons.bolt_rounded,
                              ),
                            ],
                          ),
                          if (showDrawingBanner)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              color: Colors.black.withOpacity(0.76),
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

                      const SizedBox(height: 10),

                      // 5. Bottom Coins, Faceted Diamond Chips & Repeat Button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(

horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: kGold.withOpacity(0.6), width: 1.0),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: kGold, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  _formatNum(_effectiveCoins),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _chips.map((chip) {
                                final int chipVal = (chip as num).toInt();
                                final bool selected = _selectedChip == chipVal;
                                return Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: (_) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedChip = chipVal;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    width: selected ? 44 : 38,
                                    height: selected ? 44 : 38,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CustomPaint(
                                          size: Size(selected ? 44 : 38,
                                              selected ? 44 : 38),
                                          painter: _DiamondChipPainter(
                                            baseColor: _chipColor(chipVal),
                                            isSelected: selected,
                                          ),
                                        ),
                                        Text(
                                          _formatNum(chipVal),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.black,
                                                  blurRadius: 3),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

);
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (_) {
                              _repeatPreviousRound();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: kGoldLight, width: 1.2),
                              ),
                              child: const Text(
                                "Repeat",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
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
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                // Flying Diamond Coins Overlay Layer
                ..._flyingCoins.map((rawFlight) {
                  final f = rawFlight as _FlyingCoin;
                  return TweenAnimationBuilder(
                    key: ValueKey("fly_${f.id}"),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, rawT, child) {
                      final double t = (rawT as num).toDouble();
                      final double curX =
                          f.startX + ((f.targetX - f.startX) * t);
                      final double curY = 0.88 + ((f.targetY - 0.88) * t);
                      final double scale = 1.15 - (0.45 * t);
                      return Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(curX, curY),
                            child: Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: CustomPaint(
                      size: const Size(28, 28),
                      painter: _DiamondChipPainter(
                        baseColor: _chipColor(f.value),
                        isSelected: true,
                      ),
                    ),
                  );
                }),

                // Settlement Overlay (Matches Video Settlement Screen)
                if (_phase == "SETTLEMENT")
                  Positioned.fill(child: _buildSettlementModal()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: FIERY DRAGON (LEFT) VS ELECTRIC BLUE TIGER (RIGHT) ARENA
// ============================================================================
class _DragonTigerBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;
    final double midX = size.width * 0.5;

    // 1. Base split fire vs ice gradient
    final Paint basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF9A3412),
          Color(0xFF7F1D1D),
          Color(0xFF1E1B4B),
          Color(0xFF1D4ED8),
        ],
        stops: [0.0, 0.46, 0.54, 1.0],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, basePaint);

    // 2. Fiery Dragon Aura on Left
    final Paint fireGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.75, -0.35),
        radius: 0.95,
        colors: [
          const Color(0xFFF97316).withOpacity(0.65),
          const Color(0xFFDC2626).withOpacity(0.25),
          Colors.transparent,
        ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, fireGlow);

    // 3. Electric Tiger Aura on Right
    final Paint iceGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.75, -0.35),
        radius: 0.95,
        colors: [
          const Color(0xFF38BDF8).withOpacity(0.60),
          const Color(0xFF1D4ED8).withOpacity(0.25),
          Colors.transparent,
        ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, iceGlow);

    // 4. Stylized Dragon Silhouette Horn/Wing Curves (Left)
    final Paint dragonArt = Paint()
      ..color = const Color(0xFFFDBA74).withOpacity(0.16)
      ..style = PaintingStyle.fill;
    final Path dPath = Path()
      ..moveTo(0, size.height * 0.12)
      ..quadraticBezierTo(
          midX * 0.55, size.height * 0.04, midX * 0.85, size.height * 0.28)
      ..quadraticBezierTo(
          midX * 0.45, size.height * 0.34, midX * 0.72, size.height * 0.55)
      ..quadraticBezierTo(
          midX * 0.30, size.height * 0.50, 0, size.height * 0.72)
      ..close();
    canvas.drawPath(dPath, dragonArt);

    // 5. Stylized Tiger Fang/Claw Energy Curves (Right)
    final Paint tigerArt = Paint()
      ..color = const Color(0xFF7DD3FC).withOpacity(0.16)
      ..style = PaintingStyle.fill;
    final Path tPath = Path()
      ..moveTo(size.width, size.height * 0.12)
      ..quadraticBezierTo(size.width - (midX * 0.55), size.height * 0.04,
          size.width - (midX * 0.85), size.height * 0.28)
      ..quadraticBezierTo(size.width - (midX * 0.45), size.height * 0.34,
          size.width - (midX * 0.72), size.height * 0.55)
      ..quadraticBezierTo(size.width - (midX * 0.30), size.height * 0.50,
          size.width, size.height * 0.72)
      ..close();
    canvas.drawPath(tPath, tigerArt);

    // 6. Center Energy Clash Line
    final Paint clashPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFEF08A).withOpacity(0.55),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(midX - 2, 0, 4, size.height * 0.45))
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(midX, 0), Offset(midX, size.height * 0.42), clashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================================
// CUSTOM PAINTER: FACETED DIAMOND CHIP (MATCHES VIDEO GEMS)
// ============================================================================
class _DiamondChipPainter extends CustomPainter {
  final Color baseColor;
  final bool isSelected;

  const _DiamondChipPainter({
    required this.baseColor,
    required this.isSelected,
  });

@override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w * 0.5, h * 0.5);

    // Outer Diamond Shape
    final Path outer = Path()
      ..moveTo(w * 0.5, 1)
      ..lineTo(w - 1, h * 0.38)
      ..lineTo(w * 0.78, h - 1)
      ..lineTo(w * 0.22, h - 1)
      ..lineTo(1, h * 0.38)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.85),
          baseColor,
          Color.lerp(baseColor, Colors.black, 0.45) ?? baseColor,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(outer, fillPaint);

    // Inner Facet Lines
    final Paint facetPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(Offset(w * 0.5, 1), center, facetPaint);
    canvas.drawLine(Offset(1, h * 0.38), Offset(w - 1, h * 0.38), facetPaint);

    // Border Ring
    final Paint borderPaint = Paint()
      ..color = isSelected ? const Color(0xFFFEF08A) : Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.0;
    canvas.drawPath(outer, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _DiamondChipPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.isSelected != isSelected;
  }
}
