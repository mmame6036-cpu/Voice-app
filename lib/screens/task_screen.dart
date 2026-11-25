import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/room_session_manager.dart';
import 'room_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isClaiming = false;

  Timer? _liveClockTimer;
  int _sessionLiveSeconds = 0;
  int _lastSyncedMinuteBucket = 0;
  String _trackedCycleKey = "";
  bool _latestIsOnMic = false;
  bool _latestIsCrownSeat = false;

  static const List<Map<String, dynamic>> _twoHourTiers = [
    {"level": "L", "req": 0, "reward": 500},
    {"level": "K", "req": 24000, "reward": 2500},
    {"level": "J", "req": 50000, "reward": 5000},
    {"level": "I", "req": 150000, "reward": 10000},
    {"level": "H", "req": 300000, "reward": 18000},
    {"level": "G", "req": 900000, "reward": 27000},
    {"level": "F", "req": 1200000, "reward": 43000},
    {"level": "E", "req": 2000000, "reward": 54000},
    {"level": "D", "req": 4000000, "reward": 75000},
    {"level": "C", "req": 7000000, "reward": 90000},
    {"level": "B", "req": 15000000, "reward": 120000},
    {"level": "A", "req": 30000000, "reward": 150000},
    {"level": "S", "req": 50000000, "reward": 180000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _trackedCycleKey = _getDailyResetCycleKey();
    _startTaskCenterLiveTimer();
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getEatNow() {
    return DateTime.now().toUtc().add(const Duration(hours: 3));
  }

  String _getDailyResetCycleKey() {
    final eatNow = _getEatNow();
    final shifted = eatNow.add(const Duration(hours: 3));
    final String y = shifted.year.toString();
    final String m = shifted.month.toString().padLeft(2, '0');
    final String d = shifted.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  String _getCountdownToResetText() {
    final eatNow = _getEatNow();
    DateTime nextReset =
        DateTime.utc(eatNow.year, eatNow.month, eatNow.day, 21, 0, 0);
    if (!eatNow.isBefore(nextReset)) {
      nextReset = nextReset.add(const Duration(days: 1));
    }
    final diff = nextReset.difference(eatNow);
    final int hrs = diff.inHours;
    final int mins = diff.inMinutes % 60;
    final int secs = diff.inSeconds % 60;
    final String hStr = hrs.toString().padLeft(2, '0');
    final String mStr = mins.toString().padLeft(2, '0');
    final String sStr = secs.toString().padLeft(2, '0');
    return "$hStr:$mStr:$sStr";
  }

  String _getFormattedEatTime() {
    final eatNow = _getEatNow();
    final String h = eatNow.hour.toString().padLeft(2, '0');
    final String m = eatNow.minute.toString().padLeft(2, '0');
    return "$h:$m (EAT)";
  }

  void _startTaskCenterLiveTimer() {
    _liveClockTimer?.cancel();
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final String nowCycle = _getDailyResetCycleKey();
      if (_trackedCycleKey != nowCycle) {
        setState(() {
          _trackedCycleKey = nowCycle;
          _sessionLiveSeconds = 0;
          _lastSyncedMinuteBucket = 0;
        });
        return;
      }

      final mgr = RoomSessionManager.instance;
      bool onMicNow = _latestIsOnMic;
      if (mgr.hasActiveRoom) {
        if (mgr.seatedIndex != null) {
          if (!mgr.isMuted) {
            onMicNow = true;
          } else {
            onMicNow = false;
          }
        } else {
          onMicNow = false;
        }
      }

      if (onMicNow) {
        setState(() {
          _sessionLiveSeconds += 1;
        });
        final int completedMinutes = _sessionLiveSeconds ~/ 60;
        if (completedMinutes > _lastSyncedMinuteBucket) {
          final int diffMins = completedMinutes - _lastSyncedMinuteBucket;
          _lastSyncedMinuteBucket = completedMinutes;
          _persistSynchronizedMinutes(diffMins);
        }
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _persistSynchronizedMinutes(int minutesToAdd) async {
    final user = _user;
    if (user == null) return;
    if (minutesToAdd <= 0) return;

    final String cycleKey = _getDailyResetCycleKey();
    bool onCrown = _latestIsCrownSeat;
    if (RoomSessionManager.instance.hasActiveRoom) {
      if (RoomSessionManager.instance.seatedIndex == 0) {
        onCrown = true;
      }
    }

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final hostRef =
          FirebaseFirestore.instance.collection('hosts').doc(user.uid);
      final snap = await userRef.get();
      final data = snap.data() ?? <String, dynamic>{};
      final String storedDate =
          (data['lastMicDate'] ?? data['micDateKey'] ?? '').toString();

      if (storedDate != cycleKey) {
        await userRef.set({
          'lastMicDate': cycleKey,
          'micDateKey': cycleKey,
          'todayMicMinutes': minutesToAdd,
          'todayCrownMinutes': onCrown ? minutesToAdd : 0,
        }, SetOptions(merge: true));

        await hostRef.set({
          'micDateKey': cycleKey,
          'liveDurationMinutesToday': minutesToAdd,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final Map<String, dynamic> inc = {
          'lastMicDate': cycleKey,
          'micDateKey': cycleKey,
          'todayMicMinutes': FieldValue.increment(minutesToAdd),
        };
        if (onCrown) {
          inc['todayCrownMinutes'] = FieldValue.increment(minutesToAdd);
        }
        await userRef.set(inc, SetOptions(merge: true));

        await hostRef.set({
          'micDateKey': cycleKey,
          'liveDurationMinutesToday': FieldValue.increment(minutesToAdd),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  String _formatDurationHms(int totalSeconds) {
    final int safeSec = totalSeconds < 0 ? 0 : totalSeconds;
    final int hrs = safeSec ~/ 3600;
    final int mins = (safeSec % 3600) ~/ 60;
    final int secs = safeSec % 60;
    final String hStr = hrs.toString().padLeft(2, '0');
    final String mStr = mins.toString().padLeft(2, '0');
    final String sStr = secs.toString().padLeft(2, '0');
    return "$hStr:$mStr:$sStr";
  }

  bool _hasCompletedBiometricScan(Map userData) {
    if (userData['isFaceVerified'] != true) return false;
    if (userData['faceLivenessPassed'] != true) return false;
    final String facePhotoUrl =
        (userData['facePhotoUrl'] ?? '').toString().trim();
    if (facePhotoUrl.isEmpty) return false;

    final rawSteps = userData['faceLivenessSteps'];
    if (rawSteps is List) {
      final steps = rawSteps.map((e) => e.toString()).toList();
      if (steps.contains('FACE_ALIGNED') &&
          steps.contains('EYE_BLINK') &&
          steps.contains('MOUTH_MOVE') &&
          steps.contains('HEAD_TURN')) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _resolveActivityTier({
    required int giftIncome7Days,
    required bool isStarterPeriod,
  }) {
    int tierReward = 500;
    String tierLevel = "L";
    int nextReq = 24000;
    int stillNeed = nextReq - giftIncome7Days;
    if (stillNeed < 0) stillNeed = 0;

    for (int i = 0; i < _twoHourTiers.length; i++) {
      final tier = _twoHourTiers[i];
      final int req = tier['req'] as int;
      if (giftIncome7Days >= req) {
        tierReward = tier['reward'] as int;
        tierLevel = tier['level'].toString();
        if (i + 1 < _twoHourTiers.length) {
          final nextTier = _twoHourTiers[i + 1];
          nextReq = nextTier['req'] as int;
          stillNeed = nextReq - giftIncome7Days;
          if (stillNeed < 0) stillNeed = 0;
        } else {
          nextReq = req;
          stillNeed = 0;
        }
      }
    }

    if (isStarterPeriod) {
      return {
        "currentReward": 1000,
        "currentLevel": "Starter (1h)",
        "nextReq": nextReq,
        "stillNeed": stillNeed,
      };
    }

    return {
      "currentReward": tierReward,
      "currentLevel": tierLevel,
      "nextReq": nextReq,
      "stillNeed": stillNeed,
    };
  }

  Future<void> _navigateToMainRoom(int currentCoins) async {
    final mgr = RoomSessionManager.instance;
    if (mgr.hasActiveRoom) {
      mgr.expandRoom();
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    String mainRoomTitle = "Habesha VIP Party";
    int mainSeatCount = 12;

    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(channelName)
          .get();
      if (roomDoc.exists && roomDoc.data() != null) {
        final rData = roomDoc.data()!;
        final String fetchedTitle =
            (rData['roomName'] ?? rData['title'] ?? '').toString().trim();
        if (fetchedTitle.isNotEmpty) {
          mainRoomTitle = fetchedTitle;
        }
        if (rData['seats'] is List) {
          final int len = (rData['seats'] as List).length;
          if (len >= 8) {
            mainSeatCount = len;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RoomScreen(
          roomTitle: mainRoomTitle,
          initialCoins: currentCoins,
          seatCount: mainSeatCount,
          onCoinUpdate: (newCoins) {},
        ),
      ),
    );
  }

  Future<void> _openFaceVerificationFlow(Map userData) async {
    final user = _user;
    if (user == null) return;

    final String? uploadedUrl = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FaceBiometricDialog(uid: user.uid),
    );

    if (uploadedUrl == null) return;
    if (uploadedUrl.isEmpty) return;

    final String cycleKey = _getDailyResetCycleKey();
    final Map<String, dynamic> faceUpdate = {
      'isFaceVerified': true,
      'faceLivenessPassed': true,
      'faceLivenessSteps': [
        'FACE_ALIGNED',
        'EYE_BLINK',
        'MOUTH_MOVE',
        'HEAD_TURN'
      ],
      'facePhotoUrl': uploadedUrl,
      'faceVerifiedAt': FieldValue.serverTimestamp(),
    };

    final String currentAvatar =
        (userData['avatarUrl'] ?? userData['photoURL'] ?? '').toString();
    if (currentAvatar.isEmpty) {
      faceUpdate['avatarUrl'] = uploadedUrl;
      faceUpdate['photoURL'] = uploadedUrl;
    }

    if (userData['hostVerifiedDate'] == null) {
      faceUpdate['hostVerifiedDate'] = cycleKey;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(faceUpdate, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Face Biometric Verified! All Host tasks are now unlocked."),
          backgroundColor: Color(0xFF107C41),
        ),
      );
    }
  }

  Future<void> _claimReward({
    required String claimKey,
    required int rewardAmount,
    required String taskTitle,
    required bool isNewDay,
    bool isCoinReward = false,
    bool incrementStreak = false,
  }) async {
    final user = _user;
    if (user == null) return;
    if (_isClaiming) return;

    setState(() => _isClaiming = true);
    final String cycleKey = _getDailyResetCycleKey();

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final txRef =
          FirebaseFirestore.instance.collection('point_transactions').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        final raw = snapshot.data();
        final Map data = (raw as Map?) ?? {};
        final rawTasks = data['claimedTaskKeys'];
        final Map claimedMap = (rawTasks as Map?) ?? {};

        if (claimedMap[claimKey] == true) {
          return;
        }

        final Map<String, dynamic> updates = {
          'lastTaskDate': cycleKey,
          'claimedTaskKeys.$claimKey': true,
        };

        if (isCoinReward) {
          updates['coins'] = FieldValue.increment(rewardAmount);
        } else {
          updates['points'] = FieldValue.increment(rewardAmount);
          updates['charmExp'] = FieldValue.increment(rewardAmount);
          updates['weekTaskPoints'] = FieldValue.increment(rewardAmount);
          if (isNewDay) {
            updates['todayTaskPoints'] = rewardAmount;
          } else {
            updates['todayTaskPoints'] = FieldValue.increment(rewardAmount);
          }
        }

        if (incrementStreak) {
          updates['consecutiveHostDays'] = FieldValue.increment(1);
        }

        transaction.update(userRef, updates);

        transaction.set(txRef, {
          'userUid': user.uid,
          'senderUid': 'SYSTEM_TASK',
          'type': isCoinReward ? 'TASK_COIN_REWARD' : 'TASK_REWARD',
          'taskTitle': taskTitle,
          'points': isCoinReward ? 0 : rewardAmount,
          'coins': isCoinReward ? rewardAmount : 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        final String unitLabel = isCoinReward ? "Coins" : "Points";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "+$rewardAmount $unitLabel successfully added to your wallet!"),
            backgroundColor: const Color(0xFF107C41),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Claim error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  void _showPolicyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: const BoxDecoration(
          color: Color(0xFFFAF7F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Task Center Policy & Rules",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildPolicyTile("1. Daily Reset at 9:00 PM EAT (21:00)",
                      "The live mic timer and all daily tasks reset automatically to 00:00:00 every night at 9:00 PM EAT."),
                  _buildPolicyTile("2. 4-Step Voice Biometric Verification",
                      "Align your face inside the circle first, then follow the spoken voice steps in order: Blink Eyes, Open Mouth/Smile, and Turn Head Left & Right."),
                  _buildPolicyTile("3. First 7 Days Starter Period (1 Hour Daily)",
                      "For the first 7 consecutive days, sitting on mic for 1 hour daily earns 1,000 Points plus the 8,000 Points daily bonus."),
                  _buildPolicyTile("4. After 7 Days (Permanent 2-Hour Dynamic Tier)",
                      "After 7 days, the 8,000 bonus ends and the task becomes 2 hours daily. Your 2-hour reward adjusts dynamically with your 7-Day Activity Points and Still Need bar (500 to 180,000 Points)."),
                  _buildPolicyTile("5. Crown Seat & Open Daily Tasks",
                      "Crown Seat 1 hour + 600 Coins gift earns 1,000 Points. Gift & Mini-Game tasks (100k Gift = 5,000 Pts, 500k Gift = 10,000 Pts, Teen Patti = 100 Coins, Dragon = 200 Coins) are open to everyone without face lock and renew every 24h."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyTile(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2D6C5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildTopRightTimerBadge({
    required int totalTodaySeconds,
    required bool isLiveOnMicNow,
    required bool isStarterPeriod,
    required int userCoins,
  }) {
    final String liveClockStr = _formatDurationHms(totalTodaySeconds);
    final bool isCounting = isLiveOnMicNow;

    Color borderCol = const Color(0xFFFACC15);
    Color iconCol = const Color(0xFFFACC15);
    String stateTag = isStarterPeriod ? "1H" : "2H";
    if (isCounting) {
      borderCol = const Color(0xFF4ADE80);
      iconCol = const Color(0xFF4ADE80);
      stateTag = "LIVE";
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () {
          if (!isCounting) {
            _navigateToMainRoom(userCoins);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF3E2723),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCounting ? Icons.mic : Icons.timer_outlined,
                color: iconCol,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                liveClockStr,
                style: const TextStyle(
                  color: Color(0xFFFACC15),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isCounting
                      ? const Color(0xFF107C41)
                      : Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  stateTag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
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
    String uid = "";
    if (_user != null) {
      uid = _user!.uid;
    }

    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5EFEB),
        body: Center(
          child: Text(
            "Please log in to view tasks",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        Map userData = {};
        if (snapshot.hasData && snapshot.data != null) {
          final doc = snapshot.data!;
          if (doc.exists && doc.data() is Map) {
            userData = doc.data() as Map;
          }
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('hosts')
              .doc(uid)
              .snapshots(),
          builder: (context, hostSnapshot) {
            Map hostData = {};
            if (hostSnapshot.hasData && hostSnapshot.data != null) {
              final hDoc = hostSnapshot.data!;
              if (hDoc.exists && hDoc.data() is Map) {
                hostData = hDoc.data() as Map;
              }
            }

            final String cycleKey = _getDailyResetCycleKey();
            final int userCoins = (userData['coins'] as num?)?.toInt() ?? 0;

            final bool isFaceVerified = _hasCompletedBiometricScan(userData);

            String lastTaskDate = "";
            if (userData['lastTaskDate'] != null) {
              lastTaskDate = userData['lastTaskDate'].toString();
            }
            final bool isNewDay = lastTaskDate != cycleKey;

            String lastMicDate = "";
            if (userData['lastMicDate'] != null) {
              lastMicDate = userData['lastMicDate'].toString();
            } else if (hostData['micDateKey'] != null) {
              lastMicDate = hostData['micDateKey'].toString();
            }
            final bool isNewMicDay =
                lastMicDate.isNotEmpty && lastMicDate != cycleKey;

            int todayPoints =
                (userData['todayTaskPoints'] as num?)?.toInt() ?? 0;
            if (isNewDay) {
              todayPoints = 0;
            }
            final int weekPoints =
                (userData['weekTaskPoints'] as num?)?.toInt() ?? 0;

            int userMicMinutes =
                (userData['todayMicMinutes'] as num?)?.toInt() ?? 0;
            int hostMicMinutes =
                (hostData['liveDurationMinutesToday'] as num?)?.toInt() ?? 0;
            int rawMicMinutes = max(userMicMinutes, hostMicMinutes);
            if (isNewMicDay) {
              rawMicMinutes = 0;
            }

            final mgr = RoomSessionManager.instance;
            bool isLiveOnMicNow = false;
            if (mgr.hasActiveRoom) {
              if (mgr.seatedIndex != null) {
                if (!mgr.isMuted) {
                  isLiveOnMicNow = true;
                }
              }
            }
            if (!isLiveOnMicNow) {
              if (userData['isOnMic'] == true) {
                if (userData['isMuted'] != true) {
                  isLiveOnMicNow = true;
                }
              }
            }

            bool isOnCrownNow = false;
            if (mgr.hasActiveRoom) {
              if (mgr.seatedIndex == 0) {
                isOnCrownNow = true;
              }
            }
            if (!isOnCrownNow) {
              final int seatIdx =
                  (userData['activeSeatIndex'] as num?)?.toInt() ?? -1;
              if (seatIdx == 0) {
                isOnCrownNow = true;
              }
            }

            _latestIsOnMic = isLiveOnMicNow;
            _latestIsCrownSeat = isOnCrownNow;

            final int extraUnsyncedSeconds = _sessionLiveSeconds % 60;
            final int totalTodaySeconds =
                (rawMicMinutes * 60) + extraUnsyncedSeconds;
            final int micMinutes = totalTodaySeconds ~/ 60;

            int rawCrownMinutes =
                (userData['todayCrownMinutes'] as num?)?.toInt() ?? 0;
            if (rawCrownMinutes == 0) {
              rawCrownMinutes = rawMicMinutes;
            }
            if (isNewMicDay) {
              rawCrownMinutes = 0;
            }
            final int crownMinutes = isOnCrownNow
                ? max(rawCrownMinutes, micMinutes)
                : rawCrownMinutes;

            int rawCrownGiftCoins =
                (userData['todayGiftCoins'] as num?)?.toInt() ?? 0;
            if (isNewMicDay) {
              rawCrownGiftCoins = 0;
            }
            final int crownGiftCoins = rawCrownGiftCoins;

            int todayGiftSentCoins =
                (userData['todayGiftSentCoins'] as num?)?.toInt() ?? 0;
            if (isNewMicDay) {
              todayGiftSentCoins = 0;
            }

            int teenPattiPlays =
                (userData['todayTeenPattiPlays'] as num?)?.toInt() ?? 0;
            if (userData['playedTeenPattiDate'] == cycleKey) {
              if (teenPattiPlays == 0) teenPattiPlays = 1;
            } else {
              teenPattiPlays = 0;
            }

            int dragonPlays =
                (userData['todayDragonPlays'] as num?)?.toInt() ?? 0;
            if (userData['playedDragonDate'] == cycleKey) {
              if (dragonPlays == 0) dragonPlays = 1;
            } else {
              dragonPlays = 0;
            }

            int giftIncomeLast7Days =
                (userData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
            if (giftIncomeLast7Days == 0) {
              giftIncomeLast7Days =
                  (hostData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
            }
            if (giftIncomeLast7Days == 0) {
              giftIncomeLast7Days =
                  (userData['points'] as num?)?.toInt() ?? 0;
            }

            int daysSinceStart = 1;
            if (userData['hostVerifiedDate'] != null) {
              final parsedStart =
                  DateTime.tryParse(userData['hostVerifiedDate'].toString());
              if (parsedStart != null) {
                daysSinceStart =
                    _getEatNow().difference(parsedStart).inDays + 1;
              }
            }

            final int consecutiveDays =
                (userData['consecutiveHostDays'] as num?)?.toInt() ?? 0;

            bool isStarterPeriod = true;
            if (daysSinceStart > 7) {
              isStarterPeriod = false;
            }
            if (consecutiveDays >= 7) {
              isStarterPeriod = false;
            }

            final tierInfo = _resolveActivityTier(
              giftIncome7Days: giftIncomeLast7Days,
              isStarterPeriod: isStarterPeriod,
            );
            final int currentActivityReward = tierInfo['currentReward'] as int;
            final String currentLevel = tierInfo['currentLevel'].toString();
            final int stillNeed = tierInfo['stillNeed'] as int;

            Map claimedKeys = {};
            if (userData['claimedTaskKeys'] is Map) {
              claimedKeys = userData['claimedTaskKeys'] as Map;
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF5EFEB),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                titleSpacing: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Color(0xFF1A1A1A), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  "Task Center",
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 17.5,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  _buildTopRightTimerBadge(
                    totalTodaySeconds: totalTodaySeconds,
                    isLiveOnMicNow: isLiveOnMicNow,
                    isStarterPeriod: isStarterPeriod,
                    userCoins: userCoins,
                  ),
                ],
              ),
              body: Column(
                children: [
                  _buildTopHeaderCard(
                    todayPoints: todayPoints,
                    weekPoints: weekPoints,
                    totalTodaySeconds: totalTodaySeconds,
                    isLiveOnMicNow: isLiveOnMicNow,
                    isStarterPeriod: isStarterPeriod,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DFD8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF4A3528),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF3E2723),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13.5),
                      tabs: const [
                        Tab(text: "Host"),
                        Tab(text: "Daily"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHostTab(
                          userData: userData,
                          userCoins: userCoins,
                          cycleKey: cycleKey,
                          isNewDay: isNewDay,
                          isFaceVerified: isFaceVerified,
                          isStarterPeriod: isStarterPeriod,
                          totalTodaySeconds: totalTodaySeconds,
                          micMinutes: micMinutes,
                          crownMinutes: crownMinutes,
                          crownGiftCoins: crownGiftCoins,
                          consecutiveDays: consecutiveDays,
                          giftIncomeLast7Days: giftIncomeLast7Days,
                          currentActivityReward: currentActivityReward,
                          currentLevel: currentLevel,
                          stillNeed: stillNeed,
                          claimedKeys: claimedKeys,
                        ),
                        _buildDailyTab(
                          userCoins: userCoins,
                          cycleKey: cycleKey,
                          isNewDay: isNewDay,
                          micMinutes: micMinutes,
                          todayGiftSentCoins: todayGiftSentCoins,
                          teenPattiPlays: teenPattiPlays,
                          dragonPlays: dragonPlays,
                          claimedKeys: claimedKeys,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopHeaderCard({
    required int todayPoints,
    required int weekPoints,
    required int totalTodaySeconds,
    required bool isLiveOnMicNow,
    required bool isStarterPeriod,
  }) {
    final double targetSeconds = isStarterPeriod ? 3600.0 : 7200.0;
    final double goalProgress =
        (totalTodaySeconds / targetSeconds).clamp(0.0, 1.0);
    final bool isCounting = isLiveOnMicNow;
    final String resetCountdown = _getCountdownToResetText();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6DE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD0C2), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars, color: Color(0xFFD49B42), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Task Rewards",
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          color: Color(0xFF5C564D), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        _getFormattedEatTime(),
                        style: const TextStyle(
                            color: Color(0xFF5C564D), fontSize: 10.5),
                      ),
                    ],
                  ),
                  Text(
                    "Resets 21:00 EAT ($resetCountdown)",
                    style: const TextStyle(
                      color: Color(0xFF8B5E34),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goalProgress,
              minHeight: 4.5,
              backgroundColor: const Color(0xFFDDD0C2),
              color: isCounting
                  ? const Color(0xFF107C41)
                  : const Color(0xFFD49B42),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today",
                      style:
                          TextStyle(color: Color(0xFF5C564D), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$todayPoints Pts",
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This week",
                      style:
                          TextStyle(color: Color(0xFF5C564D), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$weekPoints Pts",
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaceVerificationBanner({
    required Map userData,
    required bool isFaceVerified,
  }) {
    String statusTitle = "Face Verification Required";
    String statusSubtitle =
        "Align face in circle, then follow voice steps (Eye, Mouth, Head) to unlock Host tasks.";
    Color cardBorderColor = const Color(0xFFF59E0B);
    Color iconBg = const Color(0xFFFEF3C7);
    Color iconColor = const Color(0xFFD97706);

    String btnText = "Verify";
    Color btnBg = const Color(0xFFFACC15);
    Color btnFg = const Color(0xFF1A1A1A);
    VoidCallback? btnAction = () => _openFaceVerificationFlow(userData);

    if (isFaceVerified) {
      statusTitle = "Biometric Face Verified ✓";
      statusSubtitle =
          "4-step voice biometric scan passed. Host tasks are unlocked.";
      cardBorderColor = const Color(0xFF107C41);
      iconBg = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF107C41);
      btnText = "Verified";
      btnBg = const Color(0xFF107C41);
      btnFg = Colors.white;
      btnAction = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.face_retouching_natural,
                color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusSubtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              disabledBackgroundColor: const Color(0xFF107C41),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            onPressed: btnAction,
            child: Text(
              btnText,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostTab({
    required Map userData,
    required int userCoins,
    required String cycleKey,
    required bool isNewDay,
    required bool isFaceVerified,
    required bool isStarterPeriod,
    required int totalTodaySeconds,
    required int micMinutes,
    required int crownMinutes,
    required int crownGiftCoins,
    required int consecutiveDays,
    required int giftIncomeLast7Days,
    required int currentActivityReward,
    required String currentLevel,
    required int stillNeed,
    required Map claimedKeys,
  }) {
    final int requiredMins = isStarterPeriod ? 60 : 120;
    final int requiredSecs = requiredMins * 60;
    final bool isActivityDone = micMinutes >= requiredMins;
    final int minDisplay = micMinutes.clamp(0, requiredMins);
    final String timerText =
        _formatDurationHms(totalTodaySeconds.clamp(0, requiredSecs));

    int streakDisplay = consecutiveDays;
    if (streakDisplay > 7) {
      streakDisplay = 7;
    }

    final String fixed7DayKey = "${cycleKey}_fixed_7day_8000";
    final bool isFixed7DayClaimed = claimedKeys[fixed7DayKey] == true;

    final String activityTierKey = "${cycleKey}_tier_activity_salary";
    final bool isActivityTierClaimed = claimedKeys[activityTierKey] == true;

    final bool isCrownDone = crownMinutes >= 60 && crownGiftCoins >= 600;
    final String crownKey = "${cycleKey}_crown_1hr_600";
    final bool isCrownClaimed = claimedKeys[crownKey] == true;
    final int crownMinDisplay = crownMinutes.clamp(0, 60);
    final int crownCoinDisplay = crownGiftCoins.clamp(0, 600);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        _buildFaceVerificationBanner(
          userData: userData,
          isFaceVerified: isFaceVerified,
        ),
        if (isStarterPeriod) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "7-Day Starter Daily Salary (24h)",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Day $streakDisplay / 7",
                style: const TextStyle(
                  color: Color(0xFFD49B42),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTaskActionCard(
            icon: Icons.mic,
            title: "7-Day Consecutive Daily Bonus (1 Hour)",
            subtitle:
                "Timer: $timerText ($minDisplay / 60 mins) • Days 1-7 Bonus",
            rewardText: "8000 Pts",
            isVerified: isFaceVerified,
            isCompleted: isActivityDone,
            isClaimed: isFixed7DayClaimed,
            onGo: () => _navigateToMainRoom(userCoins),
            onClaim: () => _claimReward(
              claimKey: fixed7DayKey,
              rewardAmount: 8000,
              taskTitle: "7-Day Starter Daily Bonus",
              isNewDay: isNewDay,
              incrementStreak: true,
            ),
          ),
          const SizedBox(height: 10),
          _buildTaskActionCard(
            icon: Icons.trending_up,
            title: "Starter 1-Hour Daily Reward ($currentLevel)",
            subtitle:
                "Timer: $timerText ($minDisplay / 60 mins) • Switches to 2h after Day 7",
            rewardText: "$currentActivityReward Pts",
            isVerified: isFaceVerified,
            isCompleted: isActivityDone,
            isClaimed: isActivityTierClaimed,
            onGo: () => _navigateToMainRoom(userCoins),
            onClaim: () => _claimReward(
              claimKey: activityTierKey,
              rewardAmount: currentActivityReward,
              taskTitle: "Starter 1-Hour Daily Reward",
              isNewDay: isNewDay,
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Permanent 2-Hour Activity Salary (24h)",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Level $currentLevel",
                style: const TextStyle(
                  color: Color(0xFFD49B42),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTaskActionCard(
            icon: Icons.trending_up,
            title: "2-Hour Activity Tier Reward (Level $currentLevel)",
            subtitle:
                "Timer: $timerText ($minDisplay / 120 mins) • Moves with 7d Activity",
            rewardText: "$currentActivityReward Pts",
            isVerified: isFaceVerified,
            isCompleted: isActivityDone,
            isClaimed: isActivityTierClaimed,
            onGo: () => _navigateToMainRoom(userCoins),
            onClaim: () => _claimReward(
              claimKey: activityTierKey,
              rewardAmount: currentActivityReward,
              taskTitle: "2-Hour Activity Tier ($currentLevel)",
              isNewDay: isNewDay,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2D6C5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("7-Day Activity Points: $giftIncomeLast7Days",
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600)),
                  Text(
                      "$currentActivityReward Pts / ${isStarterPeriod ? '1h' : '2h'}",
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF3E2723),
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("2-Hour Growth Tiers (500 to 180,000)",
                      style: TextStyle(color: Colors.black54, fontSize: 11)),
                  GestureDetector(
                    onTap: _showPolicyDialog,
                    child: const Text("Rules >",
                        style: TextStyle(
                            color: Color(0xFF3E2723),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _twoHourTiers
                      .map((t) =>
                          _buildTierPill("${t['level']}: ${t['reward']}/2h"))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Still need ",
                      style: TextStyle(color: Colors.black54, fontSize: 11.5)),
                  const Icon(Icons.stars, color: Color(0xFFD49B42), size: 13),
                  const SizedBox(width: 4),
                  Text("$stillNeed points to reach next tier",
                      style: const TextStyle(
                          color: Color(0xFFD49B42),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "Crown Seat Daily Task (24h Renewal)",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildTaskActionCard(
          icon: Icons.workspace_premium,
          title: "Crown Seat 1 Hour + 600 Coins Gift",
          subtitle:
              "Crown: $crownMinDisplay/60 mins • Gifts (Sent/Rec): $crownCoinDisplay/600 Coins",
          rewardText: "1000 Pts",
          isVerified: isFaceVerified,
          isCompleted: isCrownDone,
          isClaimed: isCrownClaimed,
          onGo: () => _navigateToMainRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: crownKey,
            rewardAmount: 1000,
            taskTitle: "Crown Seat 1h + 600 Coins Gift",
            isNewDay: isNewDay,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDailyTab({
    required int userCoins,
    required String cycleKey,
    required bool isNewDay,
    required int micMinutes,
    required int todayGiftSentCoins,
    required int teenPattiPlays,
    required int dragonPlays,
    required Map claimedKeys,
  }) {
    final bool stayDone = micMinutes >= 10;
    final String stayKey = "${cycleKey}_daily_stay_10m";
    final bool stayClaimed = claimedKeys[stayKey] == true;

    final int giftSentProgress = todayGiftSentCoins;

    final bool gift500Done = giftSentProgress >= 500;
    final String gift500Key = "${cycleKey}_daily_wealth_500";
    final bool gift500Claimed = claimedKeys[gift500Key] == true;

    final bool gift100kDone = giftSentProgress >= 100000;
    final String gift100kKey = "${cycleKey}_daily_gift_100k";
    final bool gift100kClaimed = claimedKeys[gift100kKey] == true;

    final bool gift500kDone = giftSentProgress >= 500000;
    final String gift500kKey = "${cycleKey}_daily_gift_500k";
    final bool gift500kClaimed = claimedKeys[gift500kKey] == true;

    final bool teenPattiDone = teenPattiPlays >= 1;
    final String teenPattiKey = "${cycleKey}_daily_teenpatti_100";
    final bool teenPattiClaimed = claimedKeys[teenPattiKey] == true;

    final bool dragonDone = dragonPlays >= 1;
    final String dragonKey = "${cycleKey}_daily_dragon_200";
    final bool dragonClaimed = claimedKeys[dragonKey] == true;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            "Gift & Mini-Game Rewards (Open 24h • Resets 21:00 EAT)",
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildTaskActionCard(
          icon: Icons.redeem_rounded,
          title: "Send 100,000 Coins in Gifts",
          subtitle:
              "Progress: ${giftSentProgress.clamp(0, 100000)} / 100,000 Coins • 24h Renewal",
          rewardText: "5000 Pts",
          isVerified: true,
          isCompleted: gift100kDone,
          isClaimed: gift100kClaimed,
          onGo: () => _navigateToMainRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: gift100kKey,
            rewardAmount: 5000,
            taskTitle: "Send 100,000 Coins Gift",
            isNewDay: isNewDay,
          ),
        ),
        const SizedBox(height: 10),
        _buildTaskActionCard(
          icon: Icons.workspace_premium_rounded,
          title: "Send 500,000 Coins in Gifts",
          subtitle:
              "Progress: ${giftSentProgress.clamp(0, 500000)} / 500,000 Coins • 24h Renewal",
          rewardText: "10000 Pts",
          isVerified: true,
          isCompleted: gift500kDone,
          isClaimed: gift500kClaimed,
          onGo: () => _navigateToMainRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: gift500kKey,
            rewardAmount: 10000,
            taskTitle: "Send 500,000 Coins Gift",
            isNewDay: isNewDay,
          ),
        ),
        const SizedBox(height: 10),
        _buildTaskActionCard(
          icon: Icons.style_rounded,
          title: "Play Teen Patti",
          subtitle:
              "Progress: ${teenPattiPlays.clamp(0, 1)} / 1 Game • 24h Renewal",
          rewardText: "100 Coins",
          isCoinReward: true,
          isVerified: true,
          isCompleted: teenPattiDone,
          isClaimed: teenPattiClaimed,
          onGo: () => _navigateToMainRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: teenPattiKey,
            rewardAmount: 100,
            taskTitle: "Play Teen Patti Daily",
            isNewDay: isNewDay,
            isCoinReward: true,
          ),
        ),
        const SizedBox(height: 10),
        _buildTaskActionCard(
          icon: Icons.local_fire_department_rounded,
          title: "Play Dragon Game",
          subtitle:
              "Progress: ${dragonPlays.clamp(0, 1)} / 1 Game • 24h Renewal",
          rewardText: "200 Coins",
          isCoinReward: true,
          isVerified: true,
          isCompleted: dragonDone,
          isClaimed: dragonClaimed,
          onGo: () => _navigateToMainRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: dragonKey,
            rewardAmount: 200,
            taskTitle: "Play Dragon Daily",
            isNewDay: isNewDay,
            isCoinReward: true,
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            "Daily Activity Tasks",
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildTaskActionCard(
          icon: Icons.headset_mic,
          title: "Stay on room mic for 10 minutes",
          subtitle: "Progress: ${micMinutes.clamp(0, 10)} / 10 mins",
          rewardText: "200 Pts",
          isVerified: true,
          isCompleted: stayDone,
          isClaimed: stayClaimed,
          onGo: () => _navigateToMainRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: stayKey,
            rewardAmount: 200,
            taskTitle: "Daily 10m Room Mic",
            isNewDay: isNewDay,
          ),
        ),
        const SizedBox(height: 10),
        _buildTaskActionCard(
          icon: Icons.card_giftcard,
          title: "Send gifts worth 500+ Coins",
          subtitle: "Progress: ${giftSentProgress.clamp(0, 500)} / 500 Coins",
          rewardText: "300 Pts",
          isVerified: true,
          isCompleted: gift500Done,
          isClaimed: gift500Claimed,
          onGo: () => _navigateToMainRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: gift500Key,
            rewardAmount: 300,
            taskTitle: "Send 500+ Coins Gift",
            isNewDay: isNewDay,
          ),
        ),
      ],
    );
  }

  Widget _buildTierPill(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDD0C2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTaskActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String rewardText,
    bool isCoinReward = false,
    required bool isVerified,
    required bool isCompleted,
    required bool isClaimed,
    required VoidCallback onGo,
    required VoidCallback onClaim,
  }) {
    Color btnBg = const Color(0xFF4A3528);
    String btnLabel = "Go";
    VoidCallback? btnAction = onGo;

    if (isClaimed) {
      btnBg = Colors.black26;
      btnLabel = "Claimed";
      btnAction = null;
    } else if (!isVerified) {
      btnBg = Colors.black26;
      btnLabel = "Locked";
      btnAction = null;
    } else if (isCompleted) {
      btnBg = const Color(0xFF107C41);
      btnLabel = "Claim";
      btnAction = onClaim;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2D6C5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFEB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF3E2723), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isCoinReward ? Icons.monetization_on : Icons.stars,
                      color: isCoinReward
                          ? const Color(0xFFEAB308)
                          : const Color(0xFFD49B42),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(rewardText,
                        style: const TextStyle(
                            color: Color(0xFFD49B42),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            onPressed: btnAction,
            child: Text(
              btnLabel,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceBiometricDialog extends StatefulWidget {
  final String uid;
  const _FaceBiometricDialog({required this.uid});

  @override
  State<_FaceBiometricDialog> createState() => _FaceBiometricDialogState();
}

class _FaceBiometricDialogState extends State<_FaceBiometricDialog> {
  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  late final FaceDetector _faceDetector;
  final FlutterTts _tts = FlutterTts();

  bool _isCameraReady = false;
  bool _isProcessingFrame = false;
  bool _isUploading = false;
  bool _faceInCircle = false;
  String _lastSpokenPrompt = "";

  int _alignedStableFrames = 0;
  bool _faceAlignedVerified = false;

  bool _sawEyesOpen = false;
  bool _sawEyesClosed = false;
  int _closedEyeFrames = 0;
  bool _eyeVerified = false;

  bool _mouthVerified = false;

  bool _turnedHeadLeft = false;
  bool _turnedHeadRight = false;
  bool _headVerified = false;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _initVoiceAndCamera();
  }

  @override
  void dispose() {
    _tts.stop();
    _disposeCameraAndDetector();
    super.dispose();
  }

  Future<void> _speakVoiceCommand(String command, {bool force = false}) async {
    if (!force && _lastSpokenPrompt == command) return;
    _lastSpokenPrompt = command;
    try {
      await _tts.stop();
      await _tts.speak(command);
    } catch (_) {}
  }

  Future<void> _disposeCameraAndDetector() async {
    final ctrl = _cameraController;
    _cameraController = null;
    if (ctrl != null) {
      try {
        if (ctrl.value.isStreamingImages) {
          await ctrl.stopImageStream();
        }
      } catch (_) {}
      try {
        await ctrl.dispose();
      } catch (_) {}
    }
    try {
      await _faceDetector.close();
    } catch (_) {}
  }

  Future<void> _initVoiceAndCamera() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.46);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}

    try {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        await _speakVoiceCommand(
            "Camera permission is required. Please allow camera access.");
        return;
      }

      final cameras = await availableCameras();
      CameraDescription? selected;
      for (final cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          selected = cam;
          break;
        }
      }
      if (selected == null && cameras.isNotEmpty) {
        selected = cameras.first;
      }
      if (selected == null) {
        await _speakVoiceCommand("No front camera found on this device.");
        return;
      }

      _frontCamera = selected;
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() {
        _isCameraReady = true;
      });

      await _speakVoiceCommand(
          "Step one. Place your face inside the circle and hold steady.",
          force: true);

      await controller.startImageStream(_onCameraFrame);
    } catch (_) {
      await _speakVoiceCommand("Camera error. Please try again.");
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final cam = _frontCamera;
    if (cam == null) return null;

    final rotation =
        InputImageRotationValue.fromRawValue(cam.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  bool _isFaceProperlyInsideCircle(Face face, double imgW, double imgH) {
    if (imgW <= 0) return true;
    if (imgH <= 0) return true;
    final box = face.boundingBox;
    final double faceCenterX = box.center.dx / imgW;
    final double faceCenterY = box.center.dy / imgH;
    final double widthRatio = box.width / imgW;

    if (faceCenterX < 0.22) return false;
    if (faceCenterX > 0.78) return false;
    if (faceCenterY < 0.20) return false;
    if (faceCenterY > 0.80) return false;
    if (widthRatio < 0.22) return false;
    if (widthRatio > 0.88) return false;
    return true;
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_isProcessingFrame) return;
    if (_isUploading) return;
    if (!mounted) return;

    _isProcessingFrame = true;
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final List<Face> faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      if (faces.isEmpty) {
        setState(() {
          _faceInCircle = false;
          if (!_faceAlignedVerified) {
            _alignedStableFrames = 0;
          }
        });
        _speakVoiceCommand(
            "No face detected. Please place your face inside the circle.");
        _isProcessingFrame = false;
        return;
      }

      final Face face = faces.first;
      final bool insideCircle = _isFaceProperlyInsideCircle(
        face,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      if (!_faceAlignedVerified) {
        if (!insideCircle) {
          setState(() {
            _faceInCircle = false;
            _alignedStableFrames = 0;
          });
          _speakVoiceCommand(
              "Center your face inside the circle and move closer.");
          _isProcessingFrame = false;
          return;
        }

        final double yaw = (face.headEulerAngleY ?? 0.0).abs();
        if (yaw > 14.0) {
          setState(() {
            _faceInCircle = false;
            _alignedStableFrames = 0;
          });
          _speakVoiceCommand("Look straight at the camera inside the circle.");
          _isProcessingFrame = false;
          return;
        }

        _faceInCircle = true;
        _alignedStableFrames += 1;
        if (_alignedStableFrames >= 6) {
          _faceAlignedVerified = true;
        } else {
          setState(() {
            _progress = (_alignedStableFrames / 6.0) * 0.25;
          });
          _isProcessingFrame = false;
          return;
        }
      }

      if (!insideCircle) {
        setState(() {
          _faceInCircle = false;
        });
        _speakVoiceCommand("Keep your face inside the circle.");
        _isProcessingFrame = false;
        return;
      }
      _faceInCircle = true;

      if (_faceAlignedVerified && !_eyeVerified) {
        final double? leftOpen = face.leftEyeOpenProbability;
        final double? rightOpen = face.rightEyeOpenProbability;
        if (leftOpen != null && rightOpen != null) {
          if (leftOpen > 0.60 && rightOpen > 0.60) {
            if (_sawEyesClosed) {
              _eyeVerified = true;
            } else {
              _sawEyesOpen = true;
            }
          }
          bool eitherEyeClosed = false;
          if (leftOpen < 0.35) eitherEyeClosed = true;
          if (rightOpen < 0.35) eitherEyeClosed = true;

          if (eitherEyeClosed) {
            _sawEyesClosed = true;
            _closedEyeFrames += 1;
            if (_sawEyesOpen && _closedEyeFrames >= 2) {
              _eyeVerified = true;
            }
          }
        }
      }

      if (_faceAlignedVerified && _eyeVerified && !_mouthVerified) {
        final double? smileProb = face.smilingProbability;
        if (smileProb != null && smileProb > 0.70) {
          _mouthVerified = true;
        }
        if (!_mouthVerified) {
          final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
          final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
          final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
          if (bottomMouth != null && leftMouth != null && rightMouth != null) {
            final double mouthWidth =
                (rightMouth.position.x - leftMouth.position.x).abs().toDouble();
            final double centerMouthY =
                (leftMouth.position.y + rightMouth.position.y) / 2.0;
            final double mouthDrop =
                (bottomMouth.position.y - centerMouthY).abs().toDouble();
            if (mouthWidth > 0) {
              final double ratio = mouthDrop / mouthWidth;
              if (ratio > 0.42) {
                _mouthVerified = true;
              }
            }
          }
        }
      }

      if (_faceAlignedVerified &&
          _eyeVerified &&
          _mouthVerified &&
          !_headVerified) {
        final double? yawY = face.headEulerAngleY;
        if (yawY != null) {
          if (yawY > 15.0) {
            _turnedHeadLeft = true;
          }
          if (yawY < -15.0) {
            _turnedHeadRight = true;
          }
          if (_turnedHeadLeft && _turnedHeadRight) {
            _headVerified = true;
          }
        }
      }

      int completedSteps = 0;
      if (_faceAlignedVerified) completedSteps += 1;
      if (_eyeVerified) completedSteps += 1;
      if (_mouthVerified) completedSteps += 1;
      if (_headVerified) completedSteps += 1;

      String voiceInstruction = "";
      if (!_faceAlignedVerified) {
        voiceInstruction =
            "Step one. Place your face inside the circle and hold steady.";
      } else if (!_eyeVerified) {
        voiceInstruction = "Face locked. Step two. Please blink your eyes.";
      } else if (!_mouthVerified) {
        voiceInstruction = "Step three. Please open your mouth or smile.";
      } else if (!_headVerified) {
        if (!_turnedHeadLeft && !_turnedHeadRight) {
          voiceInstruction =
              "Step four. Slowly turn your head left and right.";
        } else if (!_turnedHeadLeft) {
          voiceInstruction = "Now turn your head to the left.";
        } else {
          voiceInstruction = "Now turn your head to the right.";
        }
      } else {
        voiceInstruction = "Verification complete. Saving your face scan.";
      }

      setState(() {
        _progress = completedSteps / 4.0;
      });
      _speakVoiceCommand(voiceInstruction);

      if (_faceAlignedVerified &&
          _eyeVerified &&
          _mouthVerified &&
          _headVerified) {
        await _completeAndUploadCapture();
      }
    } catch (_) {
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _completeAndUploadCapture() async {
    if (_isUploading) return;
    final ctrl = _cameraController;
    if (ctrl == null) return;

    setState(() {
      _isUploading = true;
      _progress = 1.0;
    });

    try {
      if (ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }
      final XFile shot = await ctrl.takePicture();
      final Uint8List bytes = await shot.readAsBytes();

      String uploadedUrl = "";
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('face_verifications')
            .child('${widget.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final task = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        uploadedUrl = await task.ref.getDownloadURL();
      } catch (_) {
        if (bytes.length <= 700000) {
          uploadedUrl = "data:image/jpeg;base64,${base64Encode(bytes)}";
        }
      }

      if (uploadedUrl.isEmpty) {
        throw Exception("Could not save face photo");
      }

      if (mounted) {
        Navigator.pop(context, uploadedUrl);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      await _speakVoiceCommand("Error saving scan. Please try again.");
    }
  }

  Widget _buildStepChip(
      IconData icon, String label, bool done, bool active) {
    Color bg = Colors.black12;
    Color fg = Colors.black54;
    if (done) {
      bg = const Color(0xFF107C41);
      fg = Colors.white;
    } else if (active) {
      bg = const Color(0xFFFACC15);
      fg = const Color(0xFF1A1A1A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : icon,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color ringColor = _progress >= 1.0
        ? const Color(0xFF107C41)
        : (_faceInCircle ? const Color(0xFF4ADE80) : Colors.redAccent);

    return AlertDialog(
      backgroundColor: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.volume_up_rounded,
              color: Color(0xFF107C41), size: 20),
          const SizedBox(width: 6),
          const Text(
            "Face Verification",
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              if (_lastSpokenPrompt.isNotEmpty) {
                _speakVoiceCommand(_lastSpokenPrompt, force: true);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE6DE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.replay_rounded,
                  size: 16, color: Color(0xFF3E2723)),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepChip(Icons.center_focus_strong, "1.Face",
                  _faceAlignedVerified, !_faceAlignedVerified),
              _buildStepChip(Icons.visibility, "2.Eye", _eyeVerified,
                  _faceAlignedVerified && !_eyeVerified),
              _buildStepChip(Icons.tag_faces, "3.Mouth", _mouthVerified,
                  _faceAlignedVerified && _eyeVerified && !_mouthVerified),
              _buildStepChip(
                  Icons.swap_horiz,
                  "4.Head",
                  _headVerified,
                  _faceAlignedVerified &&
                      _eyeVerified &&
                      _mouthVerified &&
                      !_headVerified),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: ringColor, width: 4.5),
            ),
            child: ClipOval(
              child: (_isCameraReady && _cameraController != null)
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize?.height ??
                            200,
                        height:
                            _cameraController!.value.previewSize?.width ?? 200,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFACC15),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.black12,
            color: ringColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context, null),
          child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }
}
