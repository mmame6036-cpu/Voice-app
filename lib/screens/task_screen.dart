KEDER:
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

  // Progression tiers for hourly income
  final List<int> _hourlyTiers = [
    500,
    600,
    1200,
    3000,
    5000,
    13500,
    18000,
    27000,
    43000,
    54000,
    75000,
    90000,
    180000,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _claimReward(String taskId, int pointsAmount) async {
    if (_user == null) return;
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_user!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        transaction.update(userRef, {
          'diamonds': FieldValue.increment(pointsAmount),
          'todayTaskPoints': FieldValue.increment(pointsAmount),
          'weekTaskPoints': FieldValue.increment(pointsAmount),
          'tasks.$taskId': true,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Claimed $pointsAmount Points to your wallet!"),
            backgroundColor: const Color(0xFF00C9A7),
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

  @override
  Widget build(BuildContext context) {
    final String uid = _user?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF222B45), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Task Center",
          style: TextStyle(
            color: Color(0xFF222B45),
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
                style: TextStyle(color: Colors.black45),
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

                final int todayCoins =
                    (userData['todayTaskCoins'] as num?)?.toInt() ?? 0;
                final int todayPoints =
                    (userData['todayTaskPoints'] as num?)?.toInt() ?? 0;
                final int weekCoins =
                    (userData['weekTaskCoins'] as num?)?.toInt() ?? 0;
                final int weekPoints =
                    (userData['weekTaskPoints'] as num?)?.toInt() ?? 0;

                final int giftIncomeLast7Days =
                    (userData['giftIncomeLast7Days'] as num?)?.toInt() ?? 0;
                final int micMinutes =
                    (userData['todayMicMinutes'] as num?)?.toInt() ?? 0;

final int tierIndex =
                    ((userData['hostTierIndex'] as num?)?.toInt() ?? 0)
                        .clamp(0, _hourlyTiers.length - 1);
                final int currentHourlyIncome = _hourlyTiers[tierIndex];
                final int nextTierRequirement = 24000;
                final int stillNeed = (nextTierRequirement - giftIncomeLast7Days)
                    .clamp(0, nextTierRequirement);

                final Map<String, dynamic> completedTasks =
                    (userData['tasks'] as Map<String, dynamic>?) ?? {};

                return Column(
                  children: [
                    // 1. Task Rewards Header Card
                    _buildTopRewardsCard(
                      todayCoins: todayCoins,
                      todayPoints: todayPoints,
                      weekCoins: weekCoins,
                      weekPoints: weekPoints,
                    ),

                    // 2. Tabs Selector
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF00C9A7),
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: const Color(0xFF222B45),
                        unselectedLabelColor: Colors.black38,
                        labelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        tabs: const [
                          Tab(text: "Tasks"),
                          Tab(text: "Host Tasks"),
                          Tab(text: "Events"),
                        ],
                      ),
                    ),

                    // 3. Tab Contents
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTasksTab(completedTasks),
                          _buildHostTasksTab(
                            micMinutes: micMinutes,
                            giftIncomeLast7Days: giftIncomeLast7Days,
                            currentHourlyIncome: currentHourlyIncome,
                            stillNeed: stillNeed,
                            completedTasks: completedTasks,
                          ),
                          _buildEventsTab(completedTasks),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // Top Earnings Card
  Widget _buildTopRewardsCard({
    required int todayCoins,
    required int todayPoints,
    required int weekCoins,
    required int weekPoints,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC7EFE4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8EE3CD), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.savings, color: Color(0xFFE29E00), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Task Rewards",
                    style: TextStyle(
                      color: Color(0xFF0A6C58),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,

),
                  ),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.schedule, color: Color(0xFF0A6C58), size: 14),
                  SizedBox(width: 4),
                  Text(
                    "08:38:38 (GMT+5:30)",
                    style: TextStyle(color: Color(0xFF0A6C58), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Task Earnings",
                      style: TextStyle(color: Color(0xFF336C61), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.monetization_on, Colors.amber, "$todayCoins"),
                    const SizedBox(height: 4),
                    _buildStatRow(Icons.stars, const Color(0xFF00C9A7), "$todayPoints"),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This Week's Task Earnings",
                      style: TextStyle(color: Color(0xFF336C61), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.monetization_on, Colors.amber, "$weekCoins"),
                    const SizedBox(height: 4),
                    _buildStatRow(Icons.stars, const Color(0xFF00C9A7), "$weekPoints"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, Color color, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E3832),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // TAB 1: Tasks
  Widget _buildTasksTab(Map<String, dynamic> completedTasks) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Beginner Rewards Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF3DEC0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Beginner Rewards",
                style: TextStyle(
                  color: Color(0xFFB86200),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Complete beginner tasks to claim treasure",
                style: TextStyle(color: Color(0xFF9E7C52), fontSize: 11),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTreasureChest(1, false),
                  _buildTreasureChest(2, false),
                  _buildTreasureChest(3, false),
                ],
              ),
              const SizedBox(height: 14),
              const Center(

child: Text(
                  "2 more tasks until next reward",
                  style: TextStyle(color: Color(0xFFC76D00), fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildTaskCard(
          title: "Stay in a Room for 5 Minutes",
          rewardText: "500",
          progressText: "(3/5)",
          icon: Icons.mic,
          isCompleted: completedTasks['stay_5_min'] == true,
          onAction: () {},
        ),
        _buildTaskCard(
          title: "Follow 3 Hosts",
          rewardText: "1000",
          progressText: "(0/3)",
          icon: Icons.person_add,
          isCompleted: completedTasks['follow_3_hosts'] == true,
          onAction: () {},
        ),
      ],
    );
  }

  Widget _buildTreasureChest(int step, bool unlocked) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Icon(
            unlocked ? Icons.lock_open : Icons.lock,
            color: unlocked ? Colors.amber : Colors.black26,
            size: 22,
          ),
        ),
      ],
    );
  }

  // TAB 2: Host Tasks
  Widget _buildHostTasksTab({
    required int micMinutes,
    required int giftIncomeLast7Days,
    required int currentHourlyIncome,
    required int stillNeed,
    required Map<String, dynamic> completedTasks,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // On mic card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F3EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.settings_voice, color: Color(0xFF00C9A7), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "On mic for 2 hours",
                          style: TextStyle(
                            color: Color(0xFF222B45),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "($micMinutes/120 mins)",
                          style: const TextStyle(color: Colors.black38, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.stars, color: Color(0xFF00C9A7), size: 14),
                            SizedBox(width: 4),
                            Text(
                              "500",
                              style: TextStyle(

color: Color(0xFF00C9A7),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (micMinutes >= 120 && completedTasks['on_mic_2hr'] != true) {
                        _claimReward('on_mic_2hr', 500);
                      }
                    },
                    child: Text(
                      micMinutes >= 120 ? "Claim" : "Go",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF0F2F5)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHostSubStat("Already Claimed", "0"),
                  _buildHostSubStat("Upgrade Reward", "1200"),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHostSubStat("Gift Income (Last 7 days)", "$giftIncomeLast7Days"),
                  _buildHostSubStat("Hourly income", "$currentHourlyIncome/h"),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Upgrade to",
                          style: TextStyle(color: Colors.black45, fontSize: 11),
                        ),
                        Text(
                          "Rules >",
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTierPill("600/h"),
                          _buildTierPill("1200/h"),
                          _buildTierPill("3000/h"),
                          _buildTierPill("5000/h"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          "still need ",
                          style: TextStyle(color: Colors.black45, fontSize: 11.5),

),
                        const Icon(Icons.stars, color: Color(0xFF00C9A7), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          "$stillNeed",
                          style: const TextStyle(
                            color: Color(0xFF00C9A7),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
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
      ],
    );
  }

  Widget _buildHostSubStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Color(0xFF00C9A7), size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF222B45),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTierPill(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F3EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFF00C9A7), size: 11),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF0A6C58),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Events
  Widget _buildEventsTab(Map<String, dynamic> completedTasks) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3BA2F), Color(0xFFFFE082)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.workspace_premium, color: Color(0xFF5D4037), size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "VIP Daily Rewards",
                      style: TextStyle(
                        color: Color(0xFF222B45),
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Unlock with VIP",
                      style: TextStyle(color: Colors.black38, fontSize: 11),

),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "185,000",
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text("Go", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String rewardText,
    required String progressText,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black45, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF222B45),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(progressText, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFF00C9A7), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rewardText,
                      style: const TextStyle(
                        color: Color(0xFF00C9A7),
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.black12 : const Color(0xFF00C9A7),
              foregroundColor: isCompleted ? Colors.black38 : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),

elevation: 0,
            ),
            onPressed: isCompleted ? null : onAction,
            child: Text(
              isCompleted ? "Claimed" : "Go",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
