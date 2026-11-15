import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // 2-hour tiered rewards: starts at 1,000 for first 7 days, drops to 500 if inactive after 7 days, grows up to 180,000
  static const List _twoHourTiers = [
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  bool _isProfileComplete(Map<String, dynamic> userData) {
    String nameVal = "";
    if (userData['name'] != null) {
      nameVal = userData['name'].toString().trim();
    }
    if (nameVal.isEmpty) {
      return false;
    }
    if (nameVal == "User") {
      return false;
    }

    String genderVal = "";
    if (userData['gender'] != null) {
      genderVal = userData['gender'].toString().trim();
    }
    if (genderVal.isEmpty) {
      return false;
    }

    int ageVal = (userData['age'] as num?)?.toInt() ?? 0;
    if (ageVal < 18) {
      return false;
    }

    String countryVal = "";
    if (userData['country'] != null) {
      countryVal = userData['country'].toString().trim();
    }
    if (countryVal.isEmpty) {
      return false;
    }

    return true;
  }

  Map<String, dynamic> _resolveTwoHourTier({
    required int giftIncome7Days,
    required int daysSinceStart,
  }) {
    // Default for first 7 days is 1,000 Pts per 2 hours; if inactive after 7 days, drops to 500 Pts per 2 hours
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

  Future<void> _openFaceVerificationFlow(Map<String, dynamic> userData) async {
    final user = _user;
    if (user == null) return;

    final bool faceAlreadyDone = userData['isFaceVerified'] == true;

    if (!faceAlreadyDone) {
      final bool? scanPassed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const _FaceBiometricDialog(),
      );

      if (scanPassed != true) {
        return;
      }

      final String todayKey = _getTodayDateKey();
      final Map<String, dynamic> faceUpdate = {
        'isFaceVerified': true,
        'faceVerifiedAt': FieldValue.serverTimestamp(),
      };
      if (userData['hostVerifiedDate'] == null) {
        faceUpdate['hostVerifiedDate'] = todayKey;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(faceUpdate, SetOptions(merge: true));
    }

    if (!mounted) return;
    _openHostProfileCompletionDialog(userData);
  }

  void _openHostProfileCompletionDialog(Map<String, dynamic> userData) {
    String initName = "";
    if (userData['name'] != null) {
      if (userData['name'].toString() != "User") {
        initName = userData['name'].toString();
      }
    }
    String initGender = "Female";
    if (userData['gender'] != null) {
      if (userData['gender'].toString().isNotEmpty) {
        initGender = userData['gender'].toString();
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
      if (userData['country'].toString().isNotEmpty) {
        initCountry = userData['country'].toString();
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

            if (nameStr.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter your full host name")),
              );
              return;
            }
            if (ageNum < 18) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Host must be 18 years or older")),
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'name': nameStr,
                  'gender': selectedGender,
                  'age': ageNum,
                  'country': countryStr,
                  'bio': bioStr,
                  'isHostProfileComplete': true,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text("Verification & Profile completed! Task timer is now active."),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            );
          }

          return AlertDialog(
            backgroundColor: const Color(0xFFFAF7F2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    "Face verified! Fill in your required profile details to activate task hour tracking:",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Text("Host Display Name *",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: "Enter real name",
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Gender *",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                          labelStyle: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
                          onSelected: (_) {
                            setDialogState(() => selectedGender = g);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const Text("Age (18+) *",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "e.g. 22",
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Country / Region *",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: countryCtrl,
                    decoration: InputDecoration(
                      hintText: "e.g. Ethiopia",
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Host Bio / Intro",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Welcome to my voice room!",
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Later", style: TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        final Map<String, dynamic> data =
            raw is Map<String, dynamic> ? raw : {};
        final rawTasks = data['claimedTaskKeys'];
        final Map<String, dynamic> claimedMap =
            rawTasks is Map<String, dynamic> ? rawTasks : {};

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
                  _buildPolicyTile("1. Face & Profile Verification",
                      "Hosts must complete Face Biometric Verification and fill out required Profile details before task hours count."),

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFEB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Task Center",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> userData = {};
          if (snapshot.hasData) {
            if (snapshot.data!.exists) {
              final raw = snapshot.data!.data();
              if (raw is Map<String, dynamic>) {
                userData = raw;
              }
            }
          }

          final String todayKey = _getTodayDateKey();
          final int userCoins = (userData['coins'] as num?)?.toInt() ?? 0;

          final bool isFaceVerified = userData['isFaceVerified'] == true;
          final bool isProfileReady = _isProfileComplete(userData);
          bool isFullyVerifiedHost = false;
          if (isFaceVerified) {
            if (isProfileReady) {
              isFullyVerifiedHost = true;
            }
          }

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

          int todayPoints =
              (userData['todayTaskPoints'] as num?)?.toInt() ?? 0;
          if (isNewDay) {
            todayPoints = 0;
          }
          final int weekPoints =
              (userData['weekTaskPoints'] as num?)?.toInt() ?? 0;

          // Task hours DO NOT count unless Face Verification + Profile are completed
          int rawMicMinutes =
              (userData['todayMicMinutes'] as num?)?.toInt() ?? 0;
          if (isNewMicDay) {
            rawMicMinutes = 0;
          }
          int micMinutes = 0;
          if (isFullyVerifiedHost) {
            micMinutes = rawMicMinutes;
          }

          // Crown seat minutes & 600 coins gift activity (renews every 24 hours)
          int rawCrownMinutes =
              (userData['todayCrownMinutes'] as num?)?.toInt() ?? 0;
          if (rawCrownMinutes == 0) {
            rawCrownMinutes = rawMicMinutes;
          }
          if (isNewMicDay) {
            rawCrownMinutes = 0;
          }
          int crownMinutes = 0;
          if (isFullyVerifiedHost) {
            crownMinutes = rawCrownMinutes;
          }

          int rawCrownGiftCoins =
              (userData['todayGiftCoins'] as num?)?.toInt() ?? 0;
          if (rawCrownGiftCoins == 0) {
            rawCrownGiftCoins =
                (userData['todayPoints'] as num?)?.toInt() ?? 0;
          }
          if (isNewMicDay) {
            rawCrownGiftCoins = 0;
          }
          int crownGiftCoins = 0;
          if (isFullyVerifiedHost) {
            crownGiftCoins = rawCrownGiftCoins;
          }

          int giftIncomeLast7Days =
              (userData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
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

          Map<String, dynamic> claimedKeys = {};
          if (userData['claimedTaskKeys'] is Map<String, dynamic>) {
            claimedKeys =
                userData['claimedTaskKeys'] as Map<String, dynamic>;
          }

          final int wealthExp =
              (userData['wealthExp'] as num?)?.toInt() ?? 0;

          return Column(
            children: [
              _buildTopHeaderCard(
                todayPoints: todayPoints,
                weekPoints: weekPoints,
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
          );
        },
      ),
    );
  }

  Widget _buildTopHeaderCard({
    required int todayPoints,
    required int weekPoints,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 14),
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
    required Map<String, dynamic> userData,
    required bool isFaceVerified,
    required bool isProfileReady,
    required bool isFullyVerifiedHost,
  }) {
    String statusTitle = "Face Verification Required";
    String statusSubtitle =
        "Task hours will not count until you complete Face Scan & Profile.";
    Color cardBorderColor = const Color(0xFFF59E0B);
    Color iconBg = const Color(0xFFFEF3C7);
    Color iconColor = const Color(0xFFD97706);

    String btnText = "Verify";
    Color btnBg = const Color(0xFFFACC15);
    Color btnFg = const Color(0xFF1A1A1A);
    VoidCallback? btnAction = () => _openFaceVerificationFlow(userData);

    if (isFullyVerifiedHost) {
      statusTitle = "Host Verified & Active";
      statusSubtitle = "Face scan and profile verified. Task timer is active.";
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
          "Face verified! Fill out your Profile info to unlock task hours.";
      btnText = "Verify";
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
    required Map<String, dynamic> userData,
    required int userCoins,
    required String todayKey,
    required bool isNewDay,
    required bool isFaceVerified,
    required bool isProfileReady,
    required bool isFullyVerifiedHost,
    required int micMinutes,
    required int crownMinutes,
    required int crownGiftCoins,
    required int consecutiveDays,
    required int giftIncomeLast7Days,
    required int currentTwoHourReward,
    required String currentLevel,
    required int stillNeed,
    required Map<String, dynamic> claimedKeys,
  }) {
    // 1. Fixed 7-day consecutive daily 2-hour salary: 8,000 Pts (renews every 24h)
    final bool isFixed2HrDone = micMinutes >= 120;
    final String fixed2HrKey = "${todayKey}_fixed_2hr_8000";
    final bool isFixed2HrClaimed = claimedKeys[fixed2HrKey] == true;
    final int min2Display = micMinutes.clamp(0, 120);

    int streakDisplay = consecutiveDays;
    if (streakDisplay > 7) {
      streakDisplay = 7;
    }

    // 2. Activity Tier 2-hour reward: starts at 1,000 for 7d, drops to 500 if inactive, grows up to 180,000
    final String tier2HrKey = "${todayKey}_tier_2hr_salary";
    final bool isTier2HrClaimed = claimedKeys[tier2HrKey] == true;

    // 3. Crown Seat Task: 1 hour (60 mins) on Crown Seat AND 600+ Coins gift sent or received (renews every 24h)
    bool isCrownDone = false;
    if (crownMinutes >= 60) {
      if (crownGiftCoins >= 600) {
        isCrownDone = true;
      }
    }
    final String crownKey = "${todayKey}_crown_1hr_600";
    final bool isCrownClaimed = claimedKeys[crownKey] == true;
    final int crownMinDisplay = crownMinutes.clamp(0, 60);
    final int crownCoinDisplay = crownGiftCoins.clamp(0, 600);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Face Verification Card directly below Host Tab
        _buildFaceVerificationBanner(
          userData: userData,
          isFaceVerified: isFaceVerified,
          isProfileReady: isProfileReady,
          isFullyVerifiedHost: isFullyVerifiedHost,
        ),

        // Section 1: 7-Day Consecutive Daily Base Salary (24h Renewal)
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
          subtitle: "Progress: $min2Display / 120 mins • Renews every 24h",
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

        // Section 2: Tiered 2-Hour Activity Reward (1,000 starter -> drops to 500 or grows to 180,000)
        _buildTaskActionCard(
          icon: Icons.trending_up,
          title: "2-Hour Activity Tier Reward ($currentLevel)",
          subtitle: "Progress: $min2Display / 120 mins • 7d Starter 1,000 -> up to 180,000",
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

        // Tier Progression Card
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

        // Section 3: Crown Seat Task (1 Hour on Crown Seat + 600 Coins Gift Sent/Received, renews every 24h)
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
    required Map<String, dynamic> claimedKeys,
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

class _FaceBiometricDialog extends StatefulWidget {
  const _FaceBiometricDialog();

  @override
  State<_FaceBiometricDialog> createState() => _FaceBiometricDialogState();
}

class _FaceBiometricDialogState extends State<_FaceBiometricDialog> {
  int _scanStep = 0;
  double _progress = 0.0;
  Timer? _scanTimer;

  static const List<String> _prompts = [
    "Position your face inside the circle",
    "Look straight at the front camera...",
    "Slowly blink your eyes to verify liveness...",
    "Face biometric scan complete!",
  ];

  void _startScan() {
    if (_scanStep > 0) return;
    setState(() {
      _scanStep = 1;
      _progress = 0.25;
    });

_scanTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_scanStep == 1) {
          _scanStep = 2;
          _progress = 0.65;
        } else if (_scanStep == 2) {
          _scanStep = 3;
          _progress = 1.0;
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color ringColor = const Color(0xFFFACC15);
    if (_scanStep == 3) {
      ringColor = const Color(0xFF107C41);
    }

    VoidCallback? startAction = _startScan;
    String buttonLabel = "Start Face Scan";
    if (_scanStep > 0) {
      startAction = null;
      buttonLabel = "Scanning...";
    }
    if (_scanStep == 3) {
      buttonLabel = "Verified!";
    }

    return AlertDialog(
      backgroundColor: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Center(
        child: Text(
          "Face Biometric Verification",
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
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: ringColor, width: 4),
            ),
            child: Center(
              child: Icon(
                Icons.face_retouching_natural,
                size: 72,
                color: ringColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.black12,
            color: ringColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            _prompts[_scanStep],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFACC15),
            foregroundColor: const Color(0xFF1A1A1A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: startAction,
          child: Text(
            buttonLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
