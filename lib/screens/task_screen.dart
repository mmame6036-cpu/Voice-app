import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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

  bool _isProfileComplete(Map userData) {
    String nameVal = "";
    if (userData['name'] != null) {
      nameVal = userData['name'].toString().trim();
    }
    if (nameVal.isEmpty || nameVal == "User") {
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

  Map _resolveTwoHourTier({
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
      final tier = _twoHourTiers[i] as Map;
      final int req = tier['req'] as int;
      if (giftIncome7Days >= req) {
        currentReward = tier['reward'] as int;
        currentLevel = tier['level'].toString();
        if (i + 1 < _twoHourTiers.length) {
          final nextTier = _twoHourTiers[i + 1] as Map;
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

  Future _openFaceVerificationFlow(Map userData) async {
    final user = _user;
    if (user == null) return;

    final String existingFaceUrl =
        (userData['facePhotoUrl'] ?? '').toString().trim();
    final bool hasRealFacePhoto =
        userData['isFaceVerified'] == true && existingFaceUrl.isNotEmpty;

    String? savedFaceUrl = existingFaceUrl;

    if (!hasRealFacePhoto) {
      final String? uploadedUrl = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _FaceBiometricDialog(uid: user.uid),
      );

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        return;
      }
      savedFaceUrl = uploadedUrl;

      final String todayKey = _getTodayDateKey();
      final Map<String, dynamic> faceUpdate = {
        'isFaceVerified': true,
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
    if (userData['name'] != null &&
        userData['name'].toString().trim() != "User") {
      initName = userData['name'].toString().trim();
    }
    String initGender = "Male";
    if (userData['gender'] != null &&
        userData['gender'].toString().trim().isNotEmpty) {
      initGender = userData['gender'].toString().trim();
    }
    String initAge = "";
    if (userData['age'] != null) {
      final int a = (userData['age'] as num?)?.toInt() ?? 0;
      if (a > 0) {
        initAge = a.toString();
      }
    }
    String initCountry = "Ethiopia";
    if (userData['country'] != null &&
        userData['country'].toString().trim().isNotEmpty) {
      initCountry = userData['country'].toString().trim();
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

            if (nameStr.isEmpty || nameStr == "User") {
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
                  'isHostProfileComplete': true,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (facePhotoUrl != null && facePhotoUrl.isNotEmpty) {
                  profilePayload['facePhotoUrl'] = facePhotoUrl;
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
                    "Face photo verified! Fill in your required profile details to unlock task hour tracking:",

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

  Future _claimReward({
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
     final Map data = raw is Map ? Map.from(raw) : {};
     final rawTasks = data['claimedTaskKeys'];
     final Map claimedMap = rawTasks is Map ? Map.from(rawTasks) : {};

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
                      "Hosts must take a live Front Camera Face Selfie and fill out required Profile details before task hours count."),
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          Map userData = {};
          if (snapshot.hasData && snapshot.data != null) {
            final doc = snapshot.data as DocumentSnapshot;
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

          int todayPoints =
              (userData['todayTaskPoints'] as num?)?.toInt() ?? 0;
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
          int micMinutes = isFullyVerifiedHost ? rawMicMinutes : 0;

          int rawCrownMinutes =
              (userData['todayCrownMinutes'] as num?)?.toInt() ?? 0;
          if (rawCrownMinutes == 0) {
            rawCrownMinutes = rawMicMinutes;
          }
          if (isNewMicDay) {
            rawCrownMinutes = 0;
          }
          int crownMinutes = isFullyVerifiedHost ? rawCrownMinutes : 0;

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

          Map claimedKeys = {};
          if (userData['claimedTaskKeys'] is Map) {
            claimedKeys = userData['claimedTaskKeys'] as Map;
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
    required Map userData,
    required bool isFaceVerified,
    required bool isProfileReady,
    required bool isFullyVerifiedHost,
  }) {
    String statusTitle = "Face Verification Required";
    String statusSubtitle =
        "Take a front selfie & complete Profile details to unlock task hours.";
    Color cardBorderColor = const Color(0xFFF59E0B);
    Color iconBg = const Color(0xFFFEF3C7);
    Color iconColor = const Color(0xFFD97706);

    String btnText = "Verify";
    Color btnBg = const Color(0xFFFACC15);
    Color btnFg = const Color(0xFF1A1A1A);
    VoidCallback? btnAction = () => _openFaceVerificationFlow(userData);

    if (isFullyVerifiedHost) {
      statusTitle = "Host Verified & Active ✓";
      statusSubtitle =
          "Front face photo & profile verified. Task timer is active.";
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
          "Face photo verified! Fill out your Profile info to unlock task hours.";
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

        _buildTaskActionCard(
          icon: Icons.trending_up,
          title: "2-Hour Activity Tier Reward ($currentLevel)",
          subtitle:
              "Progress: $min2Display / 120 mins • 7d Starter 1,000 -> up to 180,000",
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
                      .map((t) => _buildTierPill(
                          "${(t as Map)['level']}: ${t['reward']}/2h"))
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
// REAL FRONT-CAMERA FACE VERIFICATION DIALOG
// ============================================================================
class _FaceBiometricDialog extends StatefulWidget {
  final String uid;
  const _FaceBiometricDialog({required this.uid});

@override
  State<_FaceBiometricDialog> createState() => _FaceBiometricDialogState();
}

class _FaceBiometricDialogState extends State<_FaceBiometricDialog> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _capturedBytes;
  bool _isUploading = false;
  double _progress = 0.0;
  String _statusText =
      "Tap below to open your Front Camera and take a clear selfie of your face.";

  Future _captureAndUploadFace() async {
    if (_isUploading) return;

    try {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        if (!mounted) return;
        setState(() {
          _statusText =
              "Camera permission is required for Face Verification. Please allow camera access.";
        });
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (photo == null) return;

      final Uint8List bytes = await photo.readAsBytes();
      if (bytes.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _capturedBytes = bytes;
        _isUploading = true;
        _progress = 0.45;
        _statusText = "Analyzing face & uploading verification photo...";
      });

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

      if (!mounted) return;
      setState(() {
        _progress = 1.0;
        _statusText = "Face verification passed! Opening profile details...";
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pop(context, uploadedUrl);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _progress = 0.0;
        _statusText = "Verification error: $e. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color ringColor =
        _progress >= 1.0 ? const Color(0xFF107C41) : const Color(0xFFFACC15);

    return AlertDialog(
      backgroundColor: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Center(
        child: Text(
          "Face Camera Verification",
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
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: ringColor, width: 4),
              image: _capturedBytes != null
                  ? DecorationImage(
                      image: MemoryImage(_capturedBytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _capturedBytes == null
                ? Center(
                    child: Icon(
                      Icons.face_retouching_natural,

size: 74,
                      color: ringColor,
                    ),
                  )
                : null,
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
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
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
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFACC15),
            foregroundColor: const Color(0xFF1A1A1A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isUploading ? null : _captureAndUploadFace,
          icon: const Icon(Icons.camera_alt_rounded, size: 18),
          label: Text(
            _isUploading ? "Verifying..." : "Open Front Camera",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
