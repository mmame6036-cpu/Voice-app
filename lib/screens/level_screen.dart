import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/level_helper.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? _user = FirebaseAuth.instance.currentUser;

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

  @override
  Widget build(BuildContext context) {
    final String uid = _user?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF141226),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B38),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Level Center",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "Wealth Level"),
            Tab(text: "Charm Level"),
          ],
        ),
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text(
                "Please login first",
                style: TextStyle(color: Colors.white54),
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

                final int wealthExp = (userData['wealthExp'] as num?)?.toInt() ?? 0;
                final int charmExp = (userData['charmExp'] as num?)?.toInt() ?? 0;

                final wealthProgress = LevelHelper.getLevelProgress(wealthExp);
                final charmProgress = LevelHelper.getLevelProgress(charmExp);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLevelBody(
                      title: "Wealth Level",
                      accentColor: const Color(0xFFFFD700),
                      icon: Icons.shield,
                      levelInfo: wealthProgress,
                      howToEarn:
                          "Send gifts in voice rooms to increase your Wealth Level (1 Coin spent = 1 EXP).",
                    ),
                    _buildLevelBody(
                      title: "Charm Level",
                      accentColor: const Color(0xFFFF4081),
                      icon: Icons.favorite,
                      levelInfo: charmProgress,
                      howToEarn:
                          "Receive gifts and diamonds to increase your Charm Level (1 Diamond received = 1 EXP).",
                    ),
                  ],
                );
              },
            ),
    );
  }

Widget _buildLevelBody({
    required String title,
    required Color accentColor,
    required IconData icon,
    required Map<String, dynamic> levelInfo,
    required String howToEarn,
  }) {
    final int level = levelInfo['level'] as int;
    final int currentExp = levelInfo['currentExp'] as int;
    final int neededExp = levelInfo['neededExp'] as int;
    final double progress = levelInfo['progress'] as double;
    final int totalExp = (levelInfo['totalExp'] as int?) ?? currentExp;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.2), const Color(0xFF1E1B38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: accentColor, size: 26),
                        const SizedBox(height: 2),
                        Text(
                          "Lv.$level",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "$title  Lv.$level",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Total EXP: $totalExp",
                  style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.5),
                            blurRadius: 6,

),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$currentExp EXP",
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      level >= 99
                          ? "MAX LEVEL"
                          : "Lv.${level + 1} Goal ($neededExp EXP)",
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    howToEarn,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.stars, color: Color(0xFFFFD700), size: 18),
              SizedBox(width: 8),
              Text(
                "Level Privileges (1 - 99)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, idx) {
              final unlockLevels = [5, 15, 30, 50, 75, 99];
              final unlockTitles = [
                "Exclusive Badge",
                "Entrance Banner",
                "Chat Bubble",
                "Animated Avatar Frame",
                "Special Sound FX",
                "Supreme Emperor Title",
              ];

              final reqLevel = unlockLevels[idx];
              final isUnlocked = level >= reqLevel;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? accentColor.withOpacity(0.12)
                      : const Color(0xFF1E1B38),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnlocked
                        ? accentColor.withOpacity(0.6)
                        : Colors.white10,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnlocked ? Icons.check_circle : Icons.lock_outline,

color: isUnlocked ? accentColor : Colors.white38,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unlockTitles[idx],
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white60,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUnlocked ? "Unlocked" : "Unlock at Lv.$reqLevel",
                      style: TextStyle(
                        color: isUnlocked ? accentColor : Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
