import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostCenterScreen extends StatefulWidget {
  const HostCenterScreen({super.key});

  @override
  State<HostCenterScreen> createState() => _HostCenterScreenState();
}

class _HostCenterScreenState extends State<HostCenterScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _agencyInputController = TextEditingController();
  bool _isJoining = false;
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
        final span = (nextReq - base) > 0 ? (nextReq - base) : 1;
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
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text("${t['level']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(t['req'] == 0 ? "No Target" : "${t['req']}", style: const TextStyle(fontSize: 11)),
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
        builder: (context, setDialogState) => AlertDialog(
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
              onPressed: _isJoining
                  ? null
                  : () async {
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
                        final agencyName = agencyData['name'] ?? inputId;

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
                    },
              child: _isJoining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(int points, String currentLevel, bool isLinked) {
    final double usdValue = points / 10000.0;
    final bool canWithdraw = isLinked && (currentLevel != "None" && currentLevel != "L");

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
              "Available Balance: $points Points (≈ \$${usdValue.toStringAsFixed(2)} USD)",
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              isLinked
                  ? "Host Tier: Level $currentLevel"
                  : "Withdrawal locked: Must join an agency first.",
              style: TextStyle(
                color: canWithdraw ? const Color(0xFF107C41) : const Color(0xFFD32F2F),
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
                      "Local Transfer (Telebirr / CBE Bank)",
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
                  backgroundColor: canWithdraw ? const Color(0xFF4A3528) : Colors.black26,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: canWithdraw
                    ? () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Withdrawal request submitted.")),
                        );
                      }
                    : null,
                child: const Text("Request Payout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          final userData = (userSnapshot.hasData && userSnapshot.data!.exists)
              ? userSnapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('hosts').doc(currentUser!.uid).snapshots(),
            builder: (context, hostSnapshot) {
              final hostData = (hostSnapshot.hasData && hostSnapshot.data!.exists)
                  ? hostSnapshot.data!.data() as Map<String, dynamic>
                  : <String, dynamic>{};

              final String userName = userData['name'] ?? userData['displayName'] ?? "Host";
              final String userNumericId = (userData['numericId'] ?? userData['id'] ?? "1753925").toString();
              final String avatarUrl = userData['avatar'] ?? userData['photoURL'] ?? "";

              final String agencyName = hostData['agencyName'] ?? userData['agencyName'] ?? "KEDIR FAMS";
              final String agencyId = hostData['agencyId'] ?? userData['agencyId'] ?? "";
              final bool isLinked = agencyId.isNotEmpty;

              final int giftIncome7Days = (hostData['giftIncomeLast7Days'] as num?)?.toInt() ??
                  (userData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
              final int liveMinutesToday = (hostData['liveDurationMinutesToday'] as num?)?.toInt() ??
                  (userData['todayMicMinutes'] as num?)?.toInt() ?? 0;

              final tierCalc = _calculateTier(giftIncome7Days);
              final int currentHourlyIncome = tierCalc['currentReward'] as int;
              final int nextHourlyIncome = tierCalc['nextReward'] as int;
              final int stillNeed = tierCalc['stillNeed'] as int;
              final double tierProgress = tierCalc['progress'] as double;
              final String currentLevel = tierCalc['level'] as String;

              final int giftPoints = (hostData['giftPoints'] as num?)?.toInt() ??
                  (userData['points'] as num?)?.toInt() ?? 0;
              final int baseSalaryPoints = (hostData['baseSalaryPoints'] as num?)?.toInt() ?? 0;
              final int invitationPoints = (hostData['invitationPoints'] as num?)?.toInt() ?? 0;
              final int taskPoints = (hostData['taskPoints'] as num?)?.toInt() ??
                  (userData['todayTaskPoints'] as num?)?.toInt() ?? 0;
              final int otherPoints = (hostData['otherPoints'] as num?)?.toInt() ?? 0;
              final int totalPoints = giftPoints + baseSalaryPoints + invitationPoints + taskPoints + otherPoints;

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
                          image: avatarUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF8D6E63), size: 30)
                            : null,
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
                              onTap: isLinked ? null : _showJoinAgencyDialog,
                              child: Text(
                                isLinked ? "Agency: $agencyName" : "Agency: Tap to Join",
                                style: TextStyle(
                                  color: isLinked ? const Color(0xFF8D6E63) : const Color(0xFFD32F2F),
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
                          const Text(
                            "10:44 (UTC+5:30)",
                            style: TextStyle(color: Colors.black45, fontSize: 11),
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
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Color(0xFF8D6E63)),
                            SizedBox(width: 6),
                            Text("11.11 - 11.11", style: TextStyle(fontSize: 11, color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2D6C5)),
                            ),
                            child: const Text(
                              "Consume >",
                              style: TextStyle(color: Color(0xFF3E2723), fontSize: 11, fontWeight: FontWeight.bold),
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

                  // 5. Work Detail Summary Card
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
                        const Text(
                          "Work Detail",
                          style: TextStyle(
                            color: Color(0xFF3E2723),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
                            color: _selectedRecordTab == 0 ? const Color(0xFF3E2723) : Colors.black38,
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
                            color: _selectedRecordTab == 1 ? const Color(0xFF3E2723) : Colors.black38,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Record Content
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('hosts')
                        .doc(currentUser!.uid)
                        .collection('live_records')
                        .orderBy('startTime', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, recordSnapshot) {
                      final records = recordSnapshot.hasData ? recordSnapshot.data!.docs : [];

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
                          final data = doc.data() as Map<String, dynamic>;
                          final start = data['startTime']?.toString() ?? "00:00";
                          final end = data['endTime']?.toString() ?? "00:00";
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
