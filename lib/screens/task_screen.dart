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

  // Live Task Center Timer state (ticks every 1 second at top-right of Task Center)
  Timer? _liveClockTimer;
  int _sessionLiveSeconds = 0;
  int _lastSyncedMinuteBucket = 0;
  String _trackedDateKey = "";
  bool _latestIsVerified = false;
  bool _latestIsOnMic = false;
  bool _latestIsCrownSeat = false;

  static const List<Map<String, dynamic>> _twoHourTiers = [
    {"level": "L", "req": 0, "reward": 500},
    {"level": "Starter", "req": 0, "reward": 1000},
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
    _trackedDateKey = _getTodayDateKey();
    _startTaskCenterLiveTimer();
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startTaskCenterLiveTimer() {
    _liveClockTimer?.cancel();
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final String nowKey = _getTodayDateKey();
      if (_trackedDateKey != nowKey) {
        setState(() {
          _trackedDateKey = nowKey;
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

      if (_latestIsVerified) {
        if (onMicNow) {
          setState(() {
            _sessionLiveSeconds += 1;
          });
          final int completedMinutes = _sessionLiveSeconds ~/ 60;
          if (completedMinutes > _lastSyncedMinuteBucket) {
            final int diffMins = completedMinutes - _lastSyncedMinuteBucket;
            _lastSyncedMinuteBucket = completedMinutes;
            _persistTaskCenterMinutes(diffMins);
          }
        }
      }
    });
  }

  Future<void> _persistTaskCenterMinutes(int minutesToAdd) async {
    final user = _user;
    if (user == null) return;
    if (minutesToAdd <= 0) return;

    final String todayKey = _getTodayDateKey();
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

      if (storedDate != todayKey) {
        await userRef.set({
          'lastMicDate': todayKey,
          'micDateKey': todayKey,
          'todayMicMinutes': minutesToAdd,
          'todayCrownMinutes': onCrown ? minutesToAdd : 0,
        }, SetOptions(merge: true));

        await hostRef.set({
          'micDateKey': todayKey,
          'liveDurationMinutesToday': minutesToAdd,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final Map<String, dynamic> inc = {
          'lastMicDate': todayKey,
          'micDateKey': todayKey,
          'todayMicMinutes': FieldValue.increment(minutesToAdd),
        };
        if (onCrown) {
          inc['todayCrownMinutes'] = FieldValue.increment(minutesToAdd);
        }
        await userRef.set(inc, SetOptions(merge: true));

        await hostRef.set({
          'micDateKey': todayKey,
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

  String _getTodayDateKey() {
    final now = DateTime.now();
    final String y = now.year.toString();
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  String _getFormattedEatTime() {
    final now = DateTime.now();
    final String h = now.hour.toString().padLeft(2, '0');
    final String m = now.minute.toString().padLeft(2, '0');
    return "$h:$m (EAT)";
  }

  bool _isProfileComplete(Map userData) {
    String nameVal = "";
    if (userData['name'] != null) {
      nameVal = userData['name'].toString().trim();
    }
    if (nameVal.isEmpty) return false;
    if (nameVal == "User") return false;

    String genderVal = "";
    if (userData['gender'] != null) {
      genderVal = userData['gender'].toString().trim();
    }
    if (genderVal.isEmpty) return false;

    int ageVal = (userData['age'] as num?)?.toInt() ?? 0;
    if (ageVal < 18) return false;

    String countryVal = "";
    if (userData['country'] != null) {
      countryVal = userData['country'].toString().trim();
    }
    if (countryVal.isEmpty) return false;

    return true;
  }

  Map<String, dynamic> _resolveTwoHourTier({
    required int giftIncome7Days,
    required int daysSinceStart,
  }) {
    int currentReward = 1000;
    String currentLevel = "Starter (7d)";
    int nextReq = 24000;

    if (daysSinceStart > 7) {
      currentReward = 500;
      currentLevel = "L";
    }

    int stillNeed = nextReq - giftIncome7Days;
    if (stillNeed < 0) {
      stillNeed = 0;
    }

    for (int i = 2; i < _twoHourTiers.length; i++) {
      final tier = _twoHourTiers[i];
      final int req = tier['req'] as int;
      if (giftIncome7Days >= req) {
        currentReward = tier['reward'] as int;
        currentLevel = tier['level'].toString();
        if (i + 1 < _twoHourTiers.length) {

final nextTier = _twoHourTiers[i + 1];
          nextReq = nextTier['req'] as int;
          stillNeed = nextReq - giftIncome7Days;
          if (stillNeed < 0) {
            stillNeed = 0;
          }
        } else {
          nextReq = req;
          stillNeed = 0;
        }
      }
    }

    return {
      "currentReward": currentReward,
      "currentLevel": currentLevel,
      "nextReq": nextReq,
      "stillNeed": stillNeed,
    };
  }

  void _navigateToRoom(int currentCoins) {
    final mgr = RoomSessionManager.instance;
    if (mgr.hasActiveRoom) {
      mgr.expandRoom();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomScreen(
          roomTitle: "VIP Voice Room",
          initialCoins: currentCoins,
          onCoinUpdate: (newCoins) {},
        ),
      ),
    );
  }

  Future<void> _openFaceVerificationFlow(Map userData) async {
    final user = _user;
    if (user == null) return;

    final String existingFaceUrl =
        (userData['facePhotoUrl'] ?? '').toString().trim();
    bool hasRealFacePhoto = false;
    if (userData['isFaceVerified'] == true) {
      if (existingFaceUrl.isNotEmpty) {
        if (userData['faceLivenessPassed'] == true) {
          hasRealFacePhoto = true;
        }
      }
    }

    String? savedFaceUrl = existingFaceUrl;

    if (!hasRealFacePhoto) {
      final String? uploadedUrl = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _FaceBiometricDialog(uid: user.uid),
      );

      if (uploadedUrl == null) return;
      if (uploadedUrl.isEmpty) return;
      savedFaceUrl = uploadedUrl;

      final String todayKey = _getTodayDateKey();
      final Map<String, dynamic> faceUpdate = {
        'isFaceVerified': true,
        'faceLivenessPassed': true,
        'faceLivenessSteps': ['EYE_BLINK', 'MOUTH_MOVE', 'HEAD_TURN'],
        'facePhotoUrl': savedFaceUrl,
        'faceVerifiedAt': FieldValue.serverTimestamp(),
      };

      final String currentAvatar =
          (userData['avatarUrl'] ?? userData['photoURL'] ?? '').toString();
      if (currentAvatar.isEmpty) {
        faceUpdate['avatarUrl'] = savedFaceUrl;
        faceUpdate['photoURL'] = savedFaceUrl;
      }

      if (userData['hostVerifiedDate'] == null) {
        faceUpdate['hostVerifiedDate'] = todayKey;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(faceUpdate, SetOptions(merge: true));
    }

    if (!mounted) return;
    _openHostProfileCompletionDialog(userData, facePhotoUrl: savedFaceUrl);
  }

  void _openHostProfileCompletionDialog(Map userData,
      {String? facePhotoUrl}) {
    String initName = "";
    if (userData['name'] != null) {
      final trimmed = userData['name'].toString().trim();
      if (trimmed != "User") {
        initName = trimmed;
      }
    }
    String initGender = "Male";
    if (userData['gender'] != null) {
      final gTrim = userData['gender'].toString().trim();
      if (gTrim.isNotEmpty) {
        initGender = gTrim;
      }
    }
    String initAge = "";
    if (userData['age'] != null) {
      final int a = (userData['age'] as num?)?.toInt() ?? 0;
      if (a > 0) {
        initAge = a.toString();
      }
    }
    String initCountry = "Ethiopia";
    if (userData['country'] != null) {
      final cTrim = userData['country'].toString().trim();
      if (cTrim.isNotEmpty) {
        initCountry = cTrim;
      }
    }
    String initBio = "";
    if (userData['bio'] != null) {
      initBio = userData['bio'].toString();
    }

    final nameCtrl = TextEditingController(text: initName);
    final ageCtrl = TextEditingController(text: initAge);
    final countryCtrl = TextEditingController(text: initCountry);
    final bioCtrl = TextEditingController(text: initBio);
    String selectedGender = initGender;
    bool isSaving = false;

showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          VoidCallback? saveAction = () async {
            final String nameStr = nameCtrl.text.trim();
            final int ageNum = int.tryParse(ageCtrl.text.trim()) ?? 0;
            final String countryStr = countryCtrl.text.trim();
            final String bioStr = bioCtrl.text.trim();

            bool invalidName = nameStr.isEmpty;
            if (nameStr == "User") invalidName = true;

            if (invalidName) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Please enter your full host name")),
              );
              return;
            }
            if (ageNum < 18) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Host must be 18 years or older")),
              );
              return;
            }
            if (countryStr.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter your country")),
              );
              return;
            }

            setDialogState(() => isSaving = true);

            try {
              final user = _user;
              if (user != null) {
                final Map<String, dynamic> profilePayload = {
                  'name': nameStr,
                  'nickname': nameStr,
                  'gender': selectedGender,
                  'age': ageNum,
                  'country': countryStr,
                  'bio': bioStr,
                  'isFaceVerified': true,
                  'faceLivenessPassed': true,
                  'isHostProfileComplete': true,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (facePhotoUrl != null) {
                  if (facePhotoUrl.isNotEmpty) {
                    profilePayload['facePhotoUrl'] = facePhotoUrl;
                  }
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set(profilePayload, SetOptions(merge: true));
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        "Face & Profile Verified! Host tasks are now unlocked."),
                    backgroundColor: Color(0xFF107C41),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text("Error saving profile: $e")),
                );
              }
            } finally {
              setDialogState(() => isSaving = false);
            }
          };

          Widget saveChild = const Text(
            "Complete & Unlock Tasks",
            style: TextStyle(fontWeight: FontWeight.bold),
          );
          if (isSaving) {
            saveAction = null;
            saveChild = const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            );
          }

          return AlertDialog(
            backgroundColor: const Color(0xFFFAF7F2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.verified_user, color: Color(0xFF107C41), size: 22),

SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Complete Host Profile",
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "3-Step Face Liveness passed! Fill in your required profile details to unlock task hour tracking:",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Text("Host Full Name *",
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: "Enter your real full name",
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Gender *",
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: ["Female", "Male"].map((g) {
                      final bool sel = selectedGender == g;
                      Color bg = Colors.white;
                      Color fg = Colors.black87;
                      if (sel) {
                        bg = const Color(0xFF4A3528);
                        fg = Colors.white;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(g),
                          selected: sel,
                          selectedColor: const Color(0xFF4A3528),
                          backgroundColor: bg,
                          labelStyle: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          onSelected: (_) {
                            setDialogState(() => selectedGender = g);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const Text("Age (18+) *",
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "e.g. 22",
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Country / Region *",

style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: countryCtrl,
                    decoration: InputDecoration(
                      hintText: "e.g. Ethiopia",
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Host Bio / Intro",
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Welcome to my voice room!",
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Later",
                    style: TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: saveAction,
                child: saveChild,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _claimReward({
    required String claimKey,
    required int pointsAmount,
    required String taskTitle,
    required bool isNewDay,
    bool incrementStreak = false,
  }) async {
    final user = _user;
    if (user == null) return;
    if (_isClaiming) return;

    setState(() => _isClaiming = true);
    final String todayKey = _getTodayDateKey();

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
          'points': FieldValue.increment(pointsAmount),
          'charmExp': FieldValue.increment(pointsAmount),
          'weekTaskPoints': FieldValue.increment(pointsAmount),
          'lastTaskDate': todayKey,
          'claimedTaskKeys.$claimKey': true,
        };

        if (isNewDay) {
          updates['todayTaskPoints'] = pointsAmount;
        } else {
          updates['todayTaskPoints'] = FieldValue.increment(pointsAmount);
        }

        if (incrementStreak) {
          updates['consecutiveHostDays'] = FieldValue.increment(1);
        }

        transaction.update(userRef, updates);

        transaction.set(txRef, {
          'userUid': user.uid,
          'senderUid': 'SYSTEM_TASK',
          'type': 'TASK_REWARD',
          'taskTitle': taskTitle,
          'points': pointsAmount,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("+$pointsAmount Points successfully added to wallet!"),
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
                "Host Policy & Salary Rules",
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
                  _buildPolicyTile("1. 3-Step Biometric Face Verification",
                      "Hosts must complete live Front Camera liveness detection (Eye Blink, Mouth Movement, and Head Turn Left/Right) and fill out required Profile details before task timer counts."),
                  _buildPolicyTile("2. Fixed 7-Day Daily Base Salary",
                      "Sit on mic for 2 hours (120 mins) daily to claim 8,000 Points. Renews every 24 hours for 7 consecutive days."),
                  _buildPolicyTile("3. 2-Hour Activity Tier Progression",
                      "Starts at 1,000 Points per 2 hours for the first 7 days. If inactive after 7 days, drops to 500 Points per 2 hours. As activity grows, rewards climb up to 180,000 Points per 2 hours."),
                  _buildPolicyTile("4. Crown Seat Task (24h Renewal)",
                      "Sit on the Crown Seat (Host Seat) for 1 hour (60 mins) AND send or receive at least 600 Coins in gifts to claim daily bonus points."),
                  _buildPolicyTile("5. Exchange Rate",
                      "10,000 Points = \$1.00 USD."),
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
    required bool isFullyVerifiedHost,
    required int userCoins,
  }) {
    final String liveClockStr = _formatDurationHms(totalTodaySeconds);
    final bool isCounting = isFullyVerifiedHost && isLiveOnMicNow;

    Color borderCol = const Color(0xFFFACC15);
    Color iconCol = const Color(0xFFFACC15);
    String stateTag = "2H";
    if (!isFullyVerifiedHost) {
      borderCol = Colors.white30;
      iconCol = Colors.white60;
      stateTag = "LOCK";
    } else if (isCounting) {
      borderCol = const Color(0xFF4ADE80);
      iconCol = const Color(0xFF4ADE80);
      stateTag = "LIVE";
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () {
          if (isFullyVerifiedHost && !isCounting) {
            _navigateToRoom(userCoins);
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

        final String todayKey = _getTodayDateKey();
        final int userCoins = (userData['coins'] as num?)?.toInt() ?? 0;

        final String facePhotoUrl =

(userData['facePhotoUrl'] ?? '').toString().trim();
        final bool isFaceVerified =
            userData['isFaceVerified'] == true && facePhotoUrl.isNotEmpty;
        final bool isProfileReady = _isProfileComplete(userData);
        final bool isFullyVerifiedHost = isFaceVerified && isProfileReady;

        String lastTaskDate = "";
        if (userData['lastTaskDate'] != null) {
          lastTaskDate = userData['lastTaskDate'].toString();
        }
        final bool isNewDay = lastTaskDate != todayKey;

        String lastMicDate = "";
        if (userData['lastMicDate'] != null) {
          lastMicDate = userData['lastMicDate'].toString();
        }
        final bool isNewMicDay = lastMicDate != todayKey;

        int todayPoints = (userData['todayTaskPoints'] as num?)?.toInt() ?? 0;
        if (isNewDay) {
          todayPoints = 0;
        }
        final int weekPoints =
            (userData['weekTaskPoints'] as num?)?.toInt() ?? 0;

        int rawMicMinutes =
            (userData['todayMicMinutes'] as num?)?.toInt() ?? 0;
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

        _latestIsVerified = isFullyVerifiedHost;
        _latestIsOnMic = isLiveOnMicNow;
        _latestIsCrownSeat = isOnCrownNow;

        final int extraUnsyncedSeconds = _sessionLiveSeconds % 60;
        final int totalTodaySeconds = isFullyVerifiedHost
            ? ((rawMicMinutes * 60) + extraUnsyncedSeconds)
            : 0;
        final int micMinutes = totalTodaySeconds ~/ 60;

        int rawCrownMinutes =
            (userData['todayCrownMinutes'] as num?)?.toInt() ?? 0;
        if (rawCrownMinutes == 0) {
          rawCrownMinutes = rawMicMinutes;
        }
        if (isNewMicDay) {
          rawCrownMinutes = 0;
        }
        int crownMinutes = isFullyVerifiedHost
            ? (isOnCrownNow
                ? max(rawCrownMinutes, micMinutes)
                : rawCrownMinutes)
            : 0;

        int rawCrownGiftCoins =
            (userData['todayGiftCoins'] as num?)?.toInt() ?? 0;
        if (rawCrownGiftCoins == 0) {
          rawCrownGiftCoins =
              (userData['todayPoints'] as num?)?.toInt() ?? 0;
        }
        if (isNewMicDay) {
          rawCrownGiftCoins = 0;
        }
        int crownGiftCoins = isFullyVerifiedHost ? rawCrownGiftCoins : 0;

        int giftIncomeLast7Days =
            (userData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
        if (giftIncomeLast7Days == 0) {
          giftIncomeLast7Days = (userData['points'] as num?)?.toInt() ?? 0;
        }

        int daysSinceStart = 1;
        if (userData['hostVerifiedDate'] != null) {
          final parsedStart =
              DateTime.tryParse(userData['hostVerifiedDate'].toString());
          if (parsedStart != null) {
            daysSinceStart =
                DateTime.now().difference(parsedStart).inDays + 1;
          }
        }

        final int consecutiveDays =
            (userData['consecutiveHostDays'] as num?)?.toInt() ?? 0;

final tierInfo = _resolveTwoHourTier(
          giftIncome7Days: giftIncomeLast7Days,
          daysSinceStart: daysSinceStart,
        );
        final int currentTwoHourReward = tierInfo['currentReward'] as int;
        final String currentLevel = tierInfo['currentLevel'].toString();
        final int stillNeed = tierInfo['stillNeed'] as int;

        Map claimedKeys = {};
        if (userData['claimedTaskKeys'] is Map) {
          claimedKeys = userData['claimedTaskKeys'] as Map;
        }

        final int wealthExp = (userData['wealthExp'] as num?)?.toInt() ?? 0;

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
                isFullyVerifiedHost: isFullyVerifiedHost,
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
                isFullyVerifiedHost: isFullyVerifiedHost,
              ),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      todayKey: todayKey,
                      isNewDay: isNewDay,
                      isFaceVerified: isFaceVerified,
                      isProfileReady: isProfileReady,
                      isFullyVerifiedHost: isFullyVerifiedHost,
                      totalTodaySeconds: totalTodaySeconds,
                      isLiveOnMicNow: isLiveOnMicNow,
                      micMinutes: micMinutes,
                      crownMinutes: crownMinutes,
                      crownGiftCoins: crownGiftCoins,
                      consecutiveDays: consecutiveDays,
                      giftIncomeLast7Days: giftIncomeLast7Days,

currentTwoHourReward: currentTwoHourReward,
                      currentLevel: currentLevel,
                      stillNeed: stillNeed,
                      claimedKeys: claimedKeys,
                    ),
                    _buildDailyTab(
                      userCoins: userCoins,
                      todayKey: todayKey,
                      isNewDay: isNewDay,
                      isFullyVerifiedHost: isFullyVerifiedHost,
                      micMinutes: micMinutes,
                      wealthExp: wealthExp,
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
  }

  Widget _buildTopHeaderCard({
    required int todayPoints,
    required int weekPoints,
    required int totalTodaySeconds,
    required bool isLiveOnMicNow,
    required bool isFullyVerifiedHost,
  }) {
    final double goalProgress = (totalTodaySeconds / 7200.0).clamp(0.0, 1.0);
    final bool isCounting = isFullyVerifiedHost && isLiveOnMicNow;

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
              Row(
                children: [
                  const Icon(Icons.schedule,
                      color: Color(0xFF5C564D), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _getFormattedEatTime(),
                    style: const TextStyle(
                        color: Color(0xFF5C564D), fontSize: 11),
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
    required bool isProfileReady,
    required bool isFullyVerifiedHost,
  }) {
    String statusTitle = "Face Liveness Verification Required";
    String statusSubtitle =
        "Complete 3-Step Face Scan (Eye Blink, Mouth & Head Turn) + Profile to start timer.";
    Color cardBorderColor = const Color(0xFFF59E0B);
    Color iconBg = const Color(0xFFFEF3C7);
    Color iconColor = const Color(0xFFD97706);

    String btnText = "Verify";
    Color btnBg = const Color(0xFFFACC15);
    Color btnFg = const Color(0xFF1A1A1A);
    VoidCallback? btnAction = () => _openFaceVerificationFlow(userData);

    if (isFullyVerifiedHost) {
      statusTitle = "Biometric Face & Host Active ✓";
      statusSubtitle =
          "Eye, Mouth & Head verified. Top-right live mic timer is active.";
      cardBorderColor = const Color(0xFF107C41);
      iconBg = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF107C41);
      btnText = "Verified";
      btnBg = const Color(0xFF107C41);
      btnFg = Colors.white;
      btnAction = null;
    } else if (isFaceVerified) {
      statusTitle = "Complete Profile Details";
      statusSubtitle =
          "Face Liveness verified! Fill out your Profile info to unlock task timer.";
      btnText = "Complete";
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
    required String todayKey,
    required bool isNewDay,
    required bool isFaceVerified,
    required bool isProfileReady,
    required bool isFullyVerifiedHost,
    required int totalTodaySeconds,
    required bool isLiveOnMicNow,
    required int micMinutes,
    required int crownMinutes,
    required int crownGiftCoins,
    required int consecutiveDays,
    required int giftIncomeLast7Days,
    required int currentTwoHourReward,
    required String currentLevel,
    required int stillNeed,
    required Map claimedKeys,
  }) {
    final bool isFixed2HrDone = micMinutes >= 120;
    final String fixed2HrKey = "${todayKey}_fixed_2hr_8000";
    final bool isFixed2HrClaimed = claimedKeys[fixed2HrKey] == true;
    final int min2Display = micMinutes.clamp(0, 120);
    final String timer2HrText =
        _formatDurationHms(totalTodaySeconds.clamp(0, 7200));

    int streakDisplay = consecutiveDays;
    if (streakDisplay > 7) {
      streakDisplay = 7;
    }

    final String tier2HrKey = "${todayKey}_tier_2hr_salary";
    final bool isTier2HrClaimed = claimedKeys[tier2HrKey] == true;

    final bool isCrownDone = crownMinutes >= 60 && crownGiftCoins >= 600;
    final String crownKey = "${todayKey}_crown_1hr_600";
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
          isProfileReady: isProfileReady,
          isFullyVerifiedHost: isFullyVerifiedHost,
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "7-Day Consecutive Daily Salary (24h)",
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
          title: "On mic for 2 hours daily (7-Day Streak)",
          subtitle:
              "Timer: $timer2HrText ($min2Display / 120 mins) • Renews every 24h",
          reward: 8000,
          isVerified: isFullyVerifiedHost,
          isCompleted: isFixed2HrDone,
          isClaimed: isFixed2HrClaimed,
          onGo: () => _navigateToRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: fixed2HrKey,
            pointsAmount: 8000,
            taskTitle: "7-Day Daily 2h Base Salary",
            isNewDay: isNewDay,
            incrementStreak: true,
          ),
        ),

        const SizedBox(height: 10),

        _buildTaskActionCard(
          icon: Icons.trending_up,

title: "2-Hour Activity Tier Reward ($currentLevel)",
          subtitle:
              "Timer: $timer2HrText ($min2Display / 120 mins) • Starter 1,000 -> 180,000",
          reward: currentTwoHourReward,
          isVerified: isFullyVerifiedHost,
          isCompleted: isFixed2HrDone,
          isClaimed: isTier2HrClaimed,
          onGo: () => _navigateToRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: tier2HrKey,
            pointsAmount: currentTwoHourReward,
            taskTitle: "2-Hour Activity Tier ($currentLevel)",
            isNewDay: isNewDay,
          ),
        ),

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
                  Text("$currentTwoHourReward Pts / 2h",
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
          reward: 2500,
          isVerified: isFullyVerifiedHost,
          isCompleted: isCrownDone,
          isClaimed: isCrownClaimed,
          onGo: () => _navigateToRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: crownKey,
            pointsAmount: 2500,
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
    required String todayKey,
    required bool isNewDay,
    required bool isFullyVerifiedHost,
    required int micMinutes,
    required int wealthExp,
    required Map claimedKeys,
  }) {
    final bool stayDone = micMinutes >= 10;
    final String stayKey = "${todayKey}_daily_stay_10m";
    final bool stayClaimed = claimedKeys[stayKey] == true;

    final bool gift500Done = wealthExp >= 500;
    final String gift500Key = "${todayKey}_daily_wealth_500";
    final bool gift500Claimed = claimedKeys[gift500Key] == true;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildTaskActionCard(
          icon: Icons.headset_mic,
          title: "Stay on room mic for 10 minutes",
          subtitle: "Progress: ${micMinutes.clamp(0, 10)} / 10 mins",
          reward: 200,
          isVerified: isFullyVerifiedHost,
          isCompleted: stayDone,
          isClaimed: stayClaimed,
          onGo: () => _navigateToRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: stayKey,
            pointsAmount: 200,
            taskTitle: "Daily 10m Room Mic",
            isNewDay: isNewDay,
          ),
        ),
        const SizedBox(height: 10),
        _buildTaskActionCard(
          icon: Icons.card_giftcard,
          title: "Send gifts worth 500+ Coins",
          subtitle: "Progress: ${wealthExp.clamp(0, 500)} / 500 Coins",
          reward: 300,
          isVerified: true,
          isCompleted: gift500Done,
          isClaimed: gift500Claimed,
          onGo: () => _navigateToRoom(userCoins),
          onClaim: () => _claimReward(
            claimKey: gift500Key,
            pointsAmount: 300,
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
    required int reward,
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
                    const Icon(Icons.stars,
                        color: Color(0xFFD49B42), size: 13),
                    const SizedBox(width: 4),
                    Text("$reward Pts",
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

// ============================================================================
// 3-STEP REAL-TIME BIOMETRIC FACE LIVENESS DIALOG
// Step 1: Eye Blink (ዓይን መጨፈንና መግለጥ)
// Step 2: Mouth Movement (አፍ መክፈት ወይም ፈገግ ማለት)
// Step 3: Head Movement (ራስን ወደ ግራና ቀኝ ማዞር)
// ============================================================================
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

  bool _isCameraReady = false;
  bool _isProcessingFrame = false;
  bool _isUploading = false;
  bool _faceDetected = false;

  // 3 Liveness challenge flags
  bool _sawEyesOpen = false;
  bool _sawEyesClosed = false;
  int _closedEyeFrames = 0;
  bool _eyeVerified = false;

  bool _mouthVerified = false;

  bool _turnedHeadLeft = false;
  bool _turnedHeadRight = false;
  bool _headVerified = false;

  double _progress = 0.0;
  String _statusText = "Initializing Front Camera...";

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
    _initFrontCamera();
  }

  @override
  void dispose() {
    _disposeCameraAndDetector();
    super.dispose();
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

  Future<void> _initFrontCamera() async {
    try {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        if (!mounted) return;
        setState(() {
          _statusText =
              "Camera permission is required. Please allow camera access.";
        });
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
        if (!mounted) return;
        setState(() {
          _statusText = "No front camera found on this device.";
        });
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
        _statusText = "Step 1/3: Blink your eyes (ዓይንዎን ይጨፍኑና ይግለጡ)";
      });

      await controller.startImageStream(_onCameraFrame);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = "Camera start error: $e";
      });
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
          _faceDetected = false;
          _statusText = "Position your face inside the circle (ፊትዎን ክቡ ውስጥ ያድርጉ)";
        });
        _isProcessingFrame = false;
        return;
      }

      final Face face = faces.first;
      _faceDetected = true;

      // STEP 1: EYE BLINK DETECTION (ዓይን መጨፈንና መግለጥ)
      if (!_eyeVerified) {
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

      // STEP 2: MOUTH MOVEMENT DETECTION (አፍ መክፈት ወይም ፈገግ ማለት)
      if (_eyeVerified && !_mouthVerified) {
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

      // STEP 3: HEAD TURN LEFT & RIGHT DETECTION (ራስን ወደ ግራና ቀኝ ማዞር)
      if (_eyeVerified && _mouthVerified && !_headVerified) {
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
      if (_eyeVerified) completedSteps += 1;
      if (_mouthVerified) completedSteps += 1;
      if (_headVerified) completedSteps += 1;

      String nextInstruction = "";
      if (!_eyeVerified) {
        nextInstruction =
            "Step 1/3: Blink your eyes (ዓይንዎን ይጨፍኑና ይግለጡ)";
      } else if (!_mouthVerified) {
        nextInstruction =
            "Step 2/3: Open your mouth or smile (አፍዎን ይክፈቱ ወይም ፈገግ ይበሉ)";
      } else if (!_headVerified) {
        if (!_turnedHeadLeft && !_turnedHeadRight) {
          nextInstruction =
              "Step 3/3: Turn your head Left & Right (ራስዎን ወደ ግራና ቀኝ ያዙሩ)";
        } else if (!_turnedHeadLeft) {
          nextInstruction =
              "Step 3/3: Now turn head Left (አሁን ራስዎን ወደ ግራ ያዙሩ)";
        } else {
          nextInstruction =
              "Step 3/3: Now turn head Right (አሁን ራስዎን ወደ ቀኝ ያዙሩ)";
        }
      } else {
        nextInstruction = "All 3 Biometric Checks Passed! Saving...";
      }

      setState(() {
        _progress = completedSteps / 3.0;
        _statusText = nextInstruction;
      });

      if (_eyeVerified && _mouthVerified && _headVerified) {
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
      _statusText = "Capturing & saving verified face photo...";
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _statusText = "Save error: $e";
      });
    }
  }

  Widget _buildStepChip(String label, bool done, bool active) {
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
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
        : (_faceDetected ? const Color(0xFFFACC15) : Colors.redAccent);

    return AlertDialog(
      backgroundColor: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Center(
        child: Text(
          "3-Step Face Verification",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 Step Status Pills (Eye, Mouth, Head)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStepChip("1. ዓይን (Eye)", _eyeVerified, !_eyeVerified),
              _buildStepChip("2. አፍ (Mouth)", _mouthVerified,
                  _eyeVerified && !_mouthVerified),
              _buildStepChip("3. ራስ (Head)", _headVerified,
                  _eyeVerified && _mouthVerified && !_headVerified),
            ],
          ),
          const SizedBox(height: 14),
          // Live Circular Front Camera Preview
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: ringColor, width: 4),
            ),
            child: ClipOval(
              child: (_isCameraReady && _cameraController != null)
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(

width: _cameraController!.value.previewSize?.height ??
                            190,
                        height:
                            _cameraController!.value.previewSize?.width ?? 190,
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
          const SizedBox(height: 10),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
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
