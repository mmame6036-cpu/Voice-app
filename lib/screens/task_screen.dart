import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? _user = FirebaseAuth.instance.currentUser;

  // የሰዓት ደሞዝ እርከኖች
  final List<int> _hourlyTiers = const [
    5000,
    8500,
    16000,
    21000,
    43000,
    75000,
    150000,
    300000,
    700000,
    1500000,
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

  // ሽልማት ወደ ተጠቃሚው አካውንት (Points) ማስገቢያ ፈንክሽን
  Future<void> _claimReward(String taskId, int pointsAmount) async {
    if (_user == null) return;
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_user!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        transaction.update(userRef, {
          'points': FieldValue.increment(pointsAmount),
          'charmExp': FieldValue.increment(pointsAmount),
          'todayTaskPoints': FieldValue.increment(pointsAmount),
          'weekTaskPoints': FieldValue.increment(pointsAmount),
          'tasks.$taskId': true,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("+$pointsAmount Points successfully added to wallet!"),
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
    }
  }

  // የህጎች መግለጫ (Policy Dialog)
  void _showPolicyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                  color: Color(0xFF3E2723),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildPolicyTile("1. Exchange Rate", "1 USD = 10,000 Points"),
                  _buildPolicyTile("2. Revenue Share", "Standard Gifts: 70% | Lucky Gifts: 4%"),
                  _buildPolicyTile("3. Daily Base Salary",
                      "• On mic 1 hour (60 min) = 5,000 Points\n• On mic 2 hours (120 min) = 5,000 Points"),
                  _buildPolicyTile("4. First Week Bonus",

"New hosts earn 50,000 Points daily for 1 hr mic time without gift targets."),
                  _buildPolicyTile("5. Weekly Reward",
                      "Hit weekly targets to earn exclusive 7-day Avatar Frames and Luxury Car entries."),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4E342E))),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _user?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFEB), // ነጣ ያለ የሽሮ ከለር
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3E2723), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Task Center",
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text(
                "Please log in to view tasks",
                style: TextStyle(color: Colors.black54),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final userData = (snapshot.hasData && snapshot.data!.exists)
                    ? snapshot.data!.data() as Map<String, dynamic>
                    : <String, dynamic>{};

                final int todayPoints = (userData['todayTaskPoints'] as num?)?.toInt() ?? 0;
                final int weekPoints = (userData['weekTaskPoints'] as num?)?.toInt() ?? 0;

                final int giftIncomeLast7Days = (userData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
                final int micMinutes = (userData['todayMicMinutes'] as num?)?.toInt() ?? 0;

                // የሰዓት ደሞዝ ደረጃ
                final int tierIndex = ((userData['hostTierIndex'] as num?)?.toInt() ?? 0)
                    .clamp(0, _hourlyTiers.length - 1);
                final int currentHourlyIncome = _hourlyTiers[tierIndex];

                // አንተ ባስቀመጥከው መሰረት የዒላማ ስሌት
                const int nextTierRequirement = 24000;
                final int stillNeed = (nextTierRequirement - giftIncomeLast7Days)
                    .clamp(0, nextTierRequirement);

                final Map<String, dynamic> completedTasks =
                    (userData['tasks'] as Map<String, dynamic>?) ?? {};

                return Column(
                  children: [
                    // 1. Top Rewards Header Card
                    _buildTopHeaderCard(
                      todayPoints: todayPoints,
                      weekPoints: weekPoints,
                    ),

                    // 2. Host & Daily Tabs
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

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
                        unselectedLabelColor: const Color(0xFF6D5446),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        tabs: const [
                          Tab(text: "Host"),
                          Tab(text: "Daily"),
                        ],
                      ),
                    ),

                    // 3. Tab Contents
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHostTab(
                            micMinutes: micMinutes,
                            giftIncomeLast7Days: giftIncomeLast7Days,
                            currentHourlyIncome: currentHourlyIncome,
                            stillNeed: stillNeed,
                            completedTasks: completedTasks,
                          ),
                          _buildDailyTab(completedTasks),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // 1. የላይኛው ገቢ ማጠቃለያ ካርድ
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
                      color: Color(0xFF3E2723),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.schedule, color: Color(0xFF6D5446), size: 14),
                  SizedBox(width: 4),
                  Text(
                    "22:20:16 (UTC+8)",
                    style: TextStyle(color: Color(0xFF6D5446), fontSize: 11),
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
                      style: TextStyle(color: Color(0xFF795548), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$todayPoints Pts",
                      style: const TextStyle(
                        color: Color(0xFF3E2723),
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
                      style: TextStyle(color: Color(0xFF795548), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$weekPoints Pts",
                      style: const TextStyle(
                        color: Color(0xFF3E2723),
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

  // TAB 1: Host Tasks Tab
  Widget _buildHostTab({
    required int micMinutes,
    required int giftIncomeLast7Days,
    required int currentHourlyIncome,
    required int stillNeed,
    required Map<String, dynamic> completedTasks,
  }) {
    final bool is1HrDone = micMinutes >= 60;
    final bool is2HrDone = micMinutes >= 120;
    final bool is1HrClaimed = completedTasks['on_mic_1hr'] == true;
    final bool is2HrClaimed = completedTasks['on_mic_2hr'] == true;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Today's base salary Section
        const Text(
          "Today's base salary",
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // 1 Hour Mic Card
        _buildBaseSalaryCard(
          title: "On mic for 1 hour",
          currentMin: micMinutes.clamp(0, 60),
          targetMin: 60,
          reward: 5000,
          isCompleted: is1HrDone,
          isClaimed: is1HrClaimed,
          onClaim: () => _claimReward('on_mic_1hr', 5000),
        ),

        const SizedBox(height: 10),

        // 2 Hours Mic Card
        _buildBaseSalaryCard(
          title: "On mic for 2 hours",
          currentMin: micMinutes.clamp(0, 120),
          targetMin: 120,
          reward: 5000,
          isCompleted: is2HrDone,
          isClaimed: is2HrClaimed,
          onClaim: () => _claimReward('on_mic_2hr', 5000),
        ),

        const SizedBox(height: 12),

        // Hourly Income Box
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
                  Text("Gifts (past 7 days): $giftIncomeLast7Days",
                      style: const TextStyle(fontSize: 11.5, color: Colors.black87, fontWeight: FontWeight.w600)),
                  Text("Hourly income: $currentHourlyIncome/h",
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF8D6E63), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Upgrade to", style: TextStyle(color: Colors.black54, fontSize: 11)),
                  GestureDetector(

onTap: _showPolicyDialog,
                    child: const Text("Rules >",
                        style: TextStyle(color: Color(0xFF8D6E63), fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _hourlyTiers.map((t) => _buildTierPill("$t/h")).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("still need ", style: TextStyle(color: Colors.black54, fontSize: 11.5)),
                  const Icon(Icons.stars, color: Color(0xFFD49B42), size: 13),
                  const SizedBox(width: 4),
                  Text("$stillNeed",
                      style: const TextStyle(color: Color(0xFFD49B42), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Weekly Host Task Section
        const Text(
          "Weekly host task",
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
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
              const Text("Gift income this week: 0",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 4),
              const Text("Still need to reach the next level: 24000.00",
                  style: TextStyle(fontSize: 11, color: Colors.black45)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSpecialReward(Icons.military_tech, "Frame (x7d)"),
                  _buildSpecialReward(Icons.directions_car, "Car (x7d)"),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Today's tasks (Gift Tasks)
        const Text(
          "Today's tasks",
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildGiftTaskCard("Receive gift: Hello", "0/1 item", 80, completedTasks['task_hello'] == true),
        _buildGiftTaskCard("Receive gift: Piano Music", "0/1 item", 1000, completedTasks['task_piano'] == true),
        _buildGiftTaskCard("Receive gift: Money Tree", "0/1 item", 3000, completedTasks['task_tree'] == true),
        _buildGiftTaskCard("Receive gift: Rose cruise", "0/1 item", 30000, completedTasks['task_cruise'] == true),
      ],
    );
  }

  // TAB 2: Daily Tab
  Widget _buildDailyTab(Map<String, dynamic> completedTasks) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildGiftTaskCard("Stay in a room for 10 minutes", "0/10 min", 200, completedTasks['daily_stay'] == true),
        _buildGiftTaskCard("Send 1 gift in any room", "0/1 item", 300, completedTasks['daily_send'] == true),
        _buildGiftTaskCard("Spend 10,000 coins in rooms", "0/10000", 500, completedTasks['daily_spend'] == true),
      ],
    );
  }

// የደሞዝ ካርድ መስሪያ
  Widget _buildBaseSalaryCard({
    required String title,
    required int currentMin,
    required int targetMin,
    required int reward,
    required bool isCompleted,
    required bool isClaimed,
    required VoidCallback onClaim,
  }) {
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
            child: const Icon(Icons.mic, color: Color(0xFF8D6E63), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723))),
                const SizedBox(height: 2),
                Text("($currentMin/$targetMin mins)", style: const TextStyle(color: Colors.black45, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFD49B42), size: 13),
                    const SizedBox(width: 4),
                    Text("$reward Pts", style: const TextStyle(color: Color(0xFFD49B42), fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isClaimed
                  ? Colors.black12
                  : (isCompleted ? const Color(0xFF4A3528) : const Color(0xFF8D6E63)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            onPressed: isClaimed ? null : (isCompleted ? onClaim : null),
            child: Text(
              isClaimed ? "Claimed" : (isCompleted ? "Claim" : "To finish"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
            ),
          ),
        ],
      ),
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
        style: const TextStyle(color: Color(0xFF4E342E), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSpecialReward(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF5EFEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDD0C2)),
          ),
          child: Icon(icon, color: const Color(0xFF8D6E63), size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
      ],
    );
  }

  Widget _buildGiftTaskCard(String title, String progress, int reward, bool isCompleted) {
    return Container(

margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2D6C5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Color(0xFF8D6E63), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF3E2723))),
                const SizedBox(height: 2),
                Text(progress, style: const TextStyle(color: Colors.black45, fontSize: 10.5)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFD49B42), size: 12),
                    const SizedBox(width: 3),
                    Text("$reward Pts", style: const TextStyle(color: Color(0xFFD49B42), fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.black12 : const Color(0xFF8D6E63),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              elevation: 0,
            ),
            onPressed: isCompleted ? null : () {},
            child: Text(isCompleted ? "Claimed" : "To finish", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
