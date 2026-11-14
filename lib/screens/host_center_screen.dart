import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'points_wallet_screen.dart';

class HostCenterScreen extends StatefulWidget {
  const HostCenterScreen({super.key});

  @override
  State<HostCenterScreen> createState() => _HostCenterScreenState();
}

class _HostCenterScreenState extends State<HostCenterScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _agencyInputController = TextEditingController();
  bool _isJoining = false;
  bool _isClaimingReward = false;
  int _selectedRecordTab = 0;

  static const List _hostPolicyTiers = [
    {"level": "S", "req": 50000000, "reward": 180000, "maxHours": 2},
    {"level": "A", "req": 20000000, "reward": 90000, "maxHours": 2},
    {"level": "B", "req": 10000000, "reward": 75000, "maxHours": 2},
    {"level": "C", "req": 7000000, "reward": 54000, "maxHours": 2},
    {"level": "D", "req": 4000000, "reward": 43000, "maxHours": 2},
    {"level": "E", "req": 2000000, "reward": 27000, "maxHours": 2},
    {"level": "F", "req": 1200000, "reward": 18000, "maxHours": 2},
    {"level": "G", "req": 900000, "reward": 13500, "maxHours": 2},
    {"level": "H", "req": 300000, "reward": 5000, "maxHours": 2},
    {"level": "I", "req": 150000, "reward": 3000, "maxHours": 2},
    {"level": "J", "req": 50000, "reward": 1200, "maxHours": 2},
    {"level": "K", "req": 24000, "reward": 600, "maxHours": 2},
    {"level": "L", "req": 0, "reward": 500, "maxHours": 2},
  ];

  @override
  void dispose() {
    _agencyInputController.dispose();
    super.dispose();
  }

  String _getTodayDateKey() {
    final now = DateTime.now();
    final String y = now.year.toString();
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  String _getFormattedShortDate() {
    final now = DateTime.now();
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    return "$m.$d - $m.$d";
  }

  String _getFormattedTime() {
    final now = DateTime.now();
    final String h = now.hour.toString().padLeft(2, '0');
    final String min = now.minute.toString().padLeft(2, '0');
    return "$h:$min (EAT)";
  }

  Map<String, dynamic> _calculateTier(int giftIncome7Days) {
    for (int i = 0; i < _hostPolicyTiers.length; i++) {
      final tier = _hostPolicyTiers[i];
      final req = tier['req'] as int;
      if (giftIncome7Days >= req) {
        final currentReward = tier['reward'] as int;
        if (i == 0) {
          return {
            "currentReward": currentReward,
            "nextReward": currentReward,
            "nextReq": req,
            "stillNeed": 0,
            "progress": 1.0,
            "level": tier['level'],
          };
        }
        final higherTier = _hostPolicyTiers[i - 1];
        final nextReq = higherTier['req'] as int;
        final nextReward = higherTier['reward'] as int;
        final stillNeed = (nextReq - giftIncome7Days).clamp(0, nextReq);
        final base = req;
        int span = nextReq - base;
        if (span <= 0) {
          span = 1;
        }
        final double progress = ((giftIncome7Days - base) / span).clamp(0.0, 1.0);
        return {
          "currentReward": currentReward,
          "nextReward": nextReward,
          "nextReq": nextReq,
          "stillNeed": stillNeed,
          "progress": progress,
          "level": tier['level'],
        };
      }
    }

    return {
      "currentReward": 0,
      "nextReward": 600,
      "nextReq": 24000,
      "stillNeed": (24000 - giftIncome7Days).clamp(0, 24000),
      "progress": (giftIncome7Days / 24000.0).clamp(0.0, 1.0),
      "level": "None",
    };
  }

  Future<void> _claimDailyMicReward({
    required int liveMinutesToday,
    required int currentHourlyIncome,
    required String currentLevel,
    required String lastClaimDate,
  }) async {
    final user = currentUser;
    if (user == null) return;

final String todayKey = _getTodayDateKey();
    if (lastClaimDate == todayKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Today's mic reward has already been claimed.")),
      );
      return;
    }

    if (liveMinutesToday < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimum 60 mic minutes required today to claim.")),
      );
      return;
    }

    int qualifiedHours = liveMinutesToday ~/ 60;
    if (qualifiedHours > 2) {
      qualifiedHours = 2;
    }

    int rewardPoints = currentHourlyIncome * qualifiedHours;
    if (currentLevel == "L") {
      if (qualifiedHours == 1) {
        rewardPoints = 2000;
      } else {
        rewardPoints = 3000;
      }
    }

    setState(() => _isClaimingReward = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final hostRef = FirebaseFirestore.instance.collection('hosts').doc(user.uid);
      final recordRef = hostRef.collection('live_records').doc(todayKey);

      batch.set(
        userRef,
        {
          'points': FieldValue.increment(rewardPoints),
          'lastMicClaimDate': todayKey,
        },
        SetOptions(merge: true),
      );

      batch.set(
        hostRef,
        {
          'baseSalaryPoints': FieldValue.increment(rewardPoints),
          'lastMicClaimDate': todayKey,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        recordRef,
        {
          'startTime': todayKey,
          'endTime': _getFormattedTime(),
          'durationMinutes': liveMinutesToday,
          'pointsEarned': rewardPoints,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Claimed +$rewardPoints Base Salary Points!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Claim failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaimingReward = false);
    }
  }

  void _showPolicyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAF7F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
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
            const SizedBox(height: 14),
            const Text(
              "Host Policy & Hourly Reward Rules",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,

borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2D6C5)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "New Host First Week Base Salary",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E342E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Income Requirement: None\n"
                          "• On mic for 1 hour: 2,000 Points\n"
                          "• On mic for 2 hours: 3,000 Points\n"
                          "Maximum 2 hours daily up to 35,000 Points in the first week.",
                          style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Ordinary Host Hourly Reward Table",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2D6C5)),
                    ),
                    child: Table(
                      border: TableBorder.all(color: const Color(0xFFEFE6DE)),
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF5EFEB)),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text("Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text("Income (7d)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text("Reward /h", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text("Max Daily", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        ..._hostPolicyTiers.map((t) {
                          String reqLabel = "${t['req']}";
                          if (t['req'] == 0) {
                            reqLabel = "No Target";
                          }
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text("${t['level']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              Padding(

padding: const EdgeInsets.all(8),
                                child: Text(reqLabel, style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text("${t['reward']} /h", style: const TextStyle(fontSize: 11, color: Color(0xFFD49B42), fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text("${t['maxHours']} Hours", style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2D6C5)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rules & Requirements",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E342E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "1. 1 USD = 10,000 Points.\n"
                          "2. On mic duration must be continuous for at least 15 minutes to count.\n"
                          "3. Host must join an active agency to request withdrawals.\n"
                          "4. First withdrawal requires Level K; subsequent payouts require Level J.\n"
                          "5. Multiple accounts on a single device or IP are strictly prohibited.",
                          style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinAgencyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          VoidCallback? submitAction = () async {
            final inputId = _agencyInputController.text.trim();
            if (inputId.isEmpty) return;

            setDialogState(() => _isJoining = true);

            try {
              final agencyDoc = await FirebaseFirestore.instance
                  .collection('agencies')
                  .doc(inputId)
                  .get();

              if (!agencyDoc.exists) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Agency ID not found.")),
                  );
                }
                setDialogState(() => _isJoining = false);
                return;
              }

              final agencyData = agencyDoc.data() ?? {};
              String agencyName = inputId;
              if (agencyData['name'] != null) {
                agencyName = agencyData['name'].toString();
              }

              await FirebaseFirestore.instance
                  .collection('hosts')
                  .doc(currentUser!.uid)
                  .set({
                'agencyId': inputId,
                'agencyName': agencyName,
                'status': 'active',
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .set({
                'agencyId': inputId,
                'agencyName': agencyName,
              }, SetOptions(merge: true));

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Successfully linked to agency!")),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            } finally {
              setDialogState(() => _isJoining = false);
            }
          };

          Widget submitChild = const Text(
            "Submit",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          );

          if (_isJoining) {
            submitAction = null;
            submitChild = const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            );
          }

          return AlertDialog(
            backgroundColor: const Color(0xFFFAF7F2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              "Join Agency",
              style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter the Agency ID provided by your agency manager to link your host account.",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _agencyInputController,
                  style: const TextStyle(color: Color(0xFF3E2723)),
                  decoration: InputDecoration(
                    hintText: "e.g. AG_1001",
                    hintStyle: const TextStyle(color: Colors.black38),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2D6C5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2D6C5)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A3528),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: submitAction,
                child: submitChild,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWithdrawDialog(int points, String currentLevel, bool isLinked) {
    final double usdValue = points / 10000.0;
    bool isLevelEligible = true;
    if (currentLevel == "None") {
      isLevelEligible = false;
    } else if (currentLevel == "L") {
      isLevelEligible = false;
    }

    bool canWithdraw = false;
    if (isLinked) {
      if (isLevelEligible) {
        canWithdraw = true;
      }
    }

String statusText = "Withdrawal locked: Must join an agency first.";
    Color statusColor = const Color(0xFFD32F2F);
    if (isLinked) {
      if (canWithdraw) {
        statusText = "Host Tier: Level $currentLevel (Eligible)";
        statusColor = const Color(0xFF107C41);
      } else {
        statusText = "Host Tier: Level $currentLevel (Requires Level K or higher)";
      }
    }

    Color btnColor = Colors.black26;
    VoidCallback? btnAction;
    if (canWithdraw) {
      btnColor = const Color(0xFF4A3528);
      btnAction = () {
        Navigator.pop(ctx);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PointsWalletScreen()),
        );
      };
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFFAF7F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Withdraw Earnings",
              style: TextStyle(color: Color(0xFF3E2723), fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Available Balance: $points Points (\$${usdValue.toStringAsFixed(2)} USD)",
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D6C5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Color(0xFFD49B42)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Telebirr / CBE / Abyssinia / Awash / Binance Pay",
                      style: TextStyle(color: Color(0xFF3E2723), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: btnAction,
                child: const Text(
                  "Proceed to Points Wallet",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5EFEB),
        body: Center(
          child: Text("Please sign in first.", style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return Scaffold(

backgroundColor: const Color(0xFFF5EFEB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3E2723), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Host Center",
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, userSnapshot) {
          Map<String, dynamic> userData = {};
          if (userSnapshot.hasData) {
            if (userSnapshot.data!.exists) {
              final raw = userSnapshot.data!.data();
              if (raw is Map<String, dynamic>) {
                userData = raw;
              }
            }
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('hosts').doc(currentUser!.uid).snapshots(),
            builder: (context, hostSnapshot) {
              Map<String, dynamic> hostData = {};
              if (hostSnapshot.hasData) {
                if (hostSnapshot.data!.exists) {
                  final raw = hostSnapshot.data!.data();
                  if (raw is Map<String, dynamic>) {
                    hostData = raw;
                  }
                }
              }

              String userName = "Host";
              if (userData['name'] != null) {
                userName = userData['name'].toString();
              } else if (userData['displayName'] != null) {
                userName = userData['displayName'].toString();
              }

              String userNumericId = "100000";
              if (userData['numericId'] != null) {
                userNumericId = userData['numericId'].toString();
              } else if (userData['id'] != null) {
                userNumericId = userData['id'].toString();
              }

              String avatarUrl = "";
              if (userData['avatarUrl'] != null) {
                avatarUrl = userData['avatarUrl'].toString();
              } else if (userData['avatar'] != null) {
                avatarUrl = userData['avatar'].toString();
              } else if (userData['photoURL'] != null) {
                avatarUrl = userData['photoURL'].toString();
              }

              String agencyName = "";
              if (hostData['agencyName'] != null) {
                agencyName = hostData['agencyName'].toString();
              } else if (userData['agencyName'] != null) {
                agencyName = userData['agencyName'].toString();
              }

              String agencyId = "";
              if (hostData['agencyId'] != null) {
                agencyId = hostData['agencyId'].toString();
              } else if (userData['agencyId'] != null) {
                agencyId = userData['agencyId'].toString();
              }
              final bool isLinked = agencyId.isNotEmpty;

              int giftIncome7Days = (hostData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
              if (giftIncome7Days == 0) {
                giftIncome7Days = (userData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
              }

              int liveMinutesToday = (hostData['liveDurationMinutesToday'] as num?)?.toInt() ?? 0;
              if (liveMinutesToday == 0) {
                liveMinutesToday = (userData['todayMicMinutes'] as num?)?.toInt() ?? 0;
              }

              String lastClaimDate = "";
              if (userData['lastMicClaimDate'] != null) {
                lastClaimDate = userData['lastMicClaimDate'].toString();
              } else if (hostData['lastMicClaimDate'] != null) {
                lastClaimDate = hostData['lastMicClaimDate'].toString();
              }

final tierCalc = _calculateTier(giftIncome7Days);
              final int currentHourlyIncome = tierCalc['currentReward'] as int;
              final int nextHourlyIncome = tierCalc['nextReward'] as int;
              final int stillNeed = tierCalc['stillNeed'] as int;
              final double tierProgress = tierCalc['progress'] as double;
              final String currentLevel = tierCalc['level'] as String;

              int giftPoints = (hostData['giftPoints'] as num?)?.toInt() ?? 0;
              if (giftPoints == 0) {
                giftPoints = (userData['points'] as num?)?.toInt() ?? 0;
              }
              final int baseSalaryPoints = (hostData['baseSalaryPoints'] as num?)?.toInt() ?? 0;
              final int invitationPoints = (hostData['invitationPoints'] as num?)?.toInt() ?? 0;
              int taskPoints = (hostData['taskPoints'] as num?)?.toInt() ?? 0;
              if (taskPoints == 0) {
                taskPoints = (userData['todayTaskPoints'] as num?)?.toInt() ?? 0;
              }
              final int otherPoints = (hostData['otherPoints'] as num?)?.toInt() ?? 0;
              final int totalPoints = giftPoints + baseSalaryPoints + invitationPoints + taskPoints + otherPoints;

              DecorationImage? avatarDeco;
              Widget? avatarChild = const Icon(Icons.person, color: Color(0xFF8D6E63), size: 30);
              if (avatarUrl.isNotEmpty) {
                avatarDeco = DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover);
                avatarChild = null;
              }

              VoidCallback? agencyTap = _showJoinAgencyDialog;
              String agencyLabel = "Agency: Tap to Join";
              Color agencyColor = const Color(0xFFD32F2F);
              if (isLinked) {
                agencyTap = null;
                agencyLabel = "Agency: $agencyName";
                agencyColor = const Color(0xFF8D6E63);
              }

              final bool alreadyClaimedToday = lastClaimDate == _getTodayDateKey();
              bool canClaimMic = false;
              if (liveMinutesToday >= 60) {
                if (!alreadyClaimedToday) {
                  canClaimMic = true;
                }
              }

              String claimBtnText = "60m Required";
              Color claimBtnBg = Colors.black12;
              Color claimBtnTextCol = Colors.black45;
              VoidCallback? claimBtnAction;

              if (alreadyClaimedToday) {
                claimBtnText = "Claimed Today";
                claimBtnBg = const Color(0xFFE8F5E9);
                claimBtnTextCol = const Color(0xFF107C41);
              } else if (canClaimMic) {
                claimBtnText = "Claim Reward";
                claimBtnBg = const Color(0xFF107C41);
                claimBtnTextCol = Colors.white;
                if (!_isClaimingReward) {
                  claimBtnAction = () => _claimDailyMicReward(
                        liveMinutesToday: liveMinutesToday,
                        currentHourlyIncome: currentHourlyIncome,
                        currentLevel: currentLevel,
                        lastClaimDate: lastClaimDate,
                      );
                }
              }

              Color tab0Color = Colors.black38;
              Color tab1Color = Colors.black38;
              if (_selectedRecordTab == 0) {
                tab0Color = const Color(0xFF3E2723);
              } else {
                tab1Color = const Color(0xFF3E2723);
              }

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // 1. Header Profile & Agency Bar
                  Row(
                    children: [

Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFDDD0C2), width: 1.5),
                          image: avatarDeco,
                        ),
                        child: avatarChild,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Color(0xFF3E2723),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD49B42),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    currentLevel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "ID: $userNumericId",
                              style: const TextStyle(color: Colors.black45, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: agencyTap,
                              child: Text(
                                agencyLabel,
                                style: TextStyle(
                                  color: agencyColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getFormattedTime(),
                            style: const TextStyle(color: Colors.black45, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _showWithdrawDialog(totalPoints, currentLevel, isLinked),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

decoration: BoxDecoration(
                                color: const Color(0xFF4A3528),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                "Withdraw",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Income & Hourly Tier Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2D6C5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Gift income (Last 7 days)", style: TextStyle(color: Colors.black45, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  "$giftIncome7Days",
                                  style: const TextStyle(
                                    color: Color(0xFF3E2723),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("Hourly income", style: TextStyle(color: Colors.black45, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  "$currentHourlyIncome /h",
                                  style: const TextStyle(
                                    color: Color(0xFFD49B42),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Still need $stillNeed points to reach $nextHourlyIncome /h",
                                style: const TextStyle(color: Colors.black54, fontSize: 11.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(

onTap: _showPolicyDialog,
                              child: const Text(
                                "Rules >",
                                style: TextStyle(
                                  color: Color(0xFF8D6E63),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EFEB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: tierProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFD49B42),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("$currentHourlyIncome /h", style: const TextStyle(color: Colors.black38, fontSize: 10)),
                            Text("$nextHourlyIncome /h", style: const TextStyle(color: Colors.black38, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Points Overview Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2D6C5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Color(0xFF8D6E63)),
                            const SizedBox(width: 6),
                            Text(
                              _getFormattedShortDate(),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF3E2723), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              "Total Income",
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),

),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PointsWalletScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2D6C5)),
                              ),
                              child: const Text(
                                "Wallet >",
                                style: TextStyle(color: Color(0xFF3E2723), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 4. Points Source 6-Grid Breakdown
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.25,
                    children: [
                      _buildSourceCard("Total Points", "$totalPoints"),
                      _buildSourceCard("Gifts", "$giftPoints"),
                      _buildSourceCard("Base Salary", "$baseSalaryPoints"),
                      _buildSourceCard("Invitation", "$invitationPoints"),
                      _buildSourceCard("Tasks", "$taskPoints"),
                      _buildSourceCard("Other", "$otherPoints"),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 5. Work Detail Summary Card with Daily Claim
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
                            const Text(
                              "Work Detail",
                              style: TextStyle(
                                color: Color(0xFF3E2723),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: claimBtnAction,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: claimBtnBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  claimBtnText,

style: TextStyle(
                                    color: claimBtnTextCol,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFF8D6E63), size: 20),
                            const SizedBox(width: 8),
                            const Text("Live Duration", style: TextStyle(color: Colors.black54, fontSize: 12)),
                            const Spacer(),
                            Text(
                              "$liveMinutesToday mins",
                              style: const TextStyle(
                                color: Color(0xFF3E2723),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 6. Bottom Tabs: Today's live record & Daily Statistics
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedRecordTab = 0),
                        child: Text(
                          "Today's live record",
                          style: TextStyle(
                            color: tab0Color,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => setState(() => _selectedRecordTab = 1),
                        child: Text(
                          "Daily Statistics",
                          style: TextStyle(
                            color: tab1Color,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_selectedRecordTab == 1)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2D6C5)),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow("Current Host Tier", "Level $currentLevel"),
                          const Divider(color: Color(0xFFEFE6DE)),
                          _buildStatRow("Hourly Reward Rate", "$currentHourlyIncome Points / h"),
                          const Divider(color: Color(0xFFEFE6DE)),
                          _buildStatRow("Today Qualified Minutes", "$liveMinutesToday / 120 mins"),
                          const Divider(color: Color(0xFFEFE6DE)),
                          _buildStatRow("Estimated USD Value", "\$${(totalPoints / 10000.0).toStringAsFixed(2)} USD"),
                        ],
                      ),
                    )
                  else
                    StreamBuilder<QuerySnapshot>(

stream: FirebaseFirestore.instance
                          .collection('hosts')
                          .doc(currentUser!.uid)
                          .collection('live_records')
                          .orderBy('createdAt', descending: true)
                          .limit(10)
                          .snapshots(),
                      builder: (context, recordSnapshot) {
                        List records = [];
                        if (recordSnapshot.hasData) {
                          records = recordSnapshot.data!.docs;
                        }

                        if (records.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Icon(Icons.receipt_long, color: Colors.black26, size: 36),
                                SizedBox(height: 6),
                                Text("No streaming records today", style: TextStyle(color: Colors.black38, fontSize: 11)),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: records.map((doc) {
                            final raw = doc.data();
                            final Map<String, dynamic> data = raw is Map<String, dynamic> ? raw : {};
                            String start = "00:00";
                            if (data['startTime'] != null) {
                              start = data['startTime'].toString();
                            }
                            String end = "00:00";
                            if (data['endTime'] != null) {
                              end = data['endTime'].toString();
                            }
                            final duration = (data['durationMinutes'] ?? 0).toString();
                            final earned = (data['pointsEarned'] ?? 0).toString();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2D6C5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("$start - $end", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3E2723))),
                                      const SizedBox(height: 2),
                                      Text("Duration: $duration mins", style: const TextStyle(color: Colors.black45, fontSize: 10.5)),
                                    ],
                                  ),
                                  Text(
                                    "+$earned Pts",
                                    style: const TextStyle(
                                      color: Color(0xFFD49B42),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: const TextStyle(color: Color(0xFF3E2723), fontSize: 12.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSourceCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2D6C5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 10.5), maxLines: 1),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF3E2723),
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
