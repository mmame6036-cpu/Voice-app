import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // የሌቭል እርከኖች ዝርዝር (Lv.1-9 እስከ Lv.90-99)
  final List> _levelTiers = const [
    {"range": "Lv.1-9", "tag": 1, "hasMedal": false},
    {"range": "Lv.10-19", "tag": 10, "hasMedal": true},
    {"range": "Lv.20-29", "tag": 20, "hasMedal": true},
    {"range": "Lv.30-39", "tag": 30, "hasMedal": true},
    {"range": "Lv.40-49", "tag": 40, "hasMedal": true},
    {"range": "Lv.50-59", "tag": 50, "hasMedal": true},
    {"range": "Lv.60-69", "tag": 60, "hasMedal": true},
    {"range": "Lv.70-79", "tag": 70, "hasMedal": true},
    {"range": "Lv.80-89", "tag": 80, "hasMedal": true},
    {"range": "Lv.90-99", "tag": 90, "hasMedal": true},
  ];

  // ለእያንዳንዱ እርከን ሜዳሊያ የሚያምር አይከን
  Widget _buildMedalIcon(int tag, bool isWealth) {
    if (isWealth) {
      switch (tag) {
        case 10:
          return const Icon(Icons.shield, color: Color(0xFFC0C0C0), size: 28);
        case 20:
          return const Icon(Icons.shield, color: Color(0xFF4FC3F7), size: 28);
        case 30:
          return const Icon(Icons.military_tech, color: Color(0xFFBA68C8), size: 30);
        case 40:
          return const Icon(Icons.shield, color: Color(0xFF7E57C2), size: 30);
        case 50:
          return const Icon(Icons.workspace_premium, color: Color(0xFFFFB74D), size: 32);
        case 60:
          return const Icon(Icons.stars, color: Color(0xFF81C784), size: 32);
        case 70:
          return const Icon(Icons.military_tech, color: Color(0xFF29B6F6), size: 34);
        case 80:
          return const Icon(Icons.diamond, color: Color(0xFFFF4081), size: 34);
        case 90:
        default:
          return const Icon(Icons.crown, color: Color(0xFFFFD700), size: 36);
      }
    } else {
      switch (tag) {
        case 10:
          return const Icon(Icons.diamond, color: Color(0xFFFF5252), size: 28);
        case 20:
          return const Icon(Icons.star, color: Color(0xFFFFD54F), size: 28);
        case 30:
          return const Icon(Icons.local_florist, color: Color(0xFFFF4081), size: 30);
        case 40:
          return const Icon(Icons.colorize, color: Color(0xFF64B5F6), size: 30);
        case 50:
          return const Icon(Icons.military_tech, color: Color(0xFFFFB300), size: 32);
        case 60:
          return const Icon(Icons.favorite, color: Color(0xFFFF80AB), size: 32);
        case 70:
          return const Icon(Icons.auto_awesome, color: Color(0xFFCE93D8), size: 34);
        case 80:
          return const Icon(Icons.ac_unit, color: Color(0xFFE0E0E0), size: 34);
        case 90:
        default:
          return const Icon(Icons.shield, color: Color(0xFFFF8A80), size: 36);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _user?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0C090D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),

),
        centerTitle: true,
        title: SizedBox(
          width: 220,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.transparent,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.white38,
            ),
            tabs: const [
              Tab(text: "Wealth"),
              Tab(text: "Charm"),
            ],
          ),
        ),
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text("Please login first", style: TextStyle(color: Colors.white54)),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final userData = (snapshot.hasData && snapshot.data!.exists)
                    ? snapshot.data!.data() as Map<String, dynamic>
                    : <String, dynamic>{};

                final String name = userData['name'] ?? userData['displayName'] ?? "User";
                final String avatarUrl = userData['avatar'] ?? userData['photoURL'] ?? "";

                // Wealth Data
                final int wealthExp = (userData['wealthExp'] as num?)?.toInt() ?? 0;
                final int wealthLevel = (userData['wealthLevel'] as num?)?.toInt() ?? 1;

                // Charm Data
                final int charmExp = (userData['charmExp'] as num?)?.toInt() ?? (userData['points'] as num?)?.toInt() ?? 0;
                final int charmLevel = (userData['charmLevel'] as num?)?.toInt() ?? 1;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // 1. Wealth Tab Body
                    _buildContent(
                      isWealth: true,
                      name: name,
                      avatarUrl: avatarUrl,
                      level: wealthLevel,
                      currentValue: wealthExp,
                      subDescription: "Wealth level is based on total coins recharged.",
                    ),
                    // 2. Charm Tab Body
                    _buildContent(
                      isWealth: false,
                      name: name,
                      avatarUrl: avatarUrl,
                      level: charmLevel,
                      currentValue: charmExp,
                      subDescription: "Charm level is determined by points received.",
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildContent({
    required bool isWealth,
    required String name,
    required String avatarUrl,
    required int level,
    required int currentValue,
    required String subDescription,
  }) {
    // ቀጣዩን ሌቭል ለማደግ የሚያስፈልግ ስሌት
    final int nextLevel = level < 99 ? level + 1 : 99;
    final int targetExpForNext = nextLevel * 5000;
    final int neededForUpgrade = (targetExpForNext - currentValue).clamp(0, targetExpForNext);
    final double progress = targetExpForNext > 0
        ? (currentValue / targetExpForNext).clamp(0.0, 1.0)
        : 1.0;

    final String valueLabel = isWealth ? "Wealth Value" : "Char Value";
    final String unitLabel = isWealth ? "coins" : "points";
    final Color tagColor = isWealth ? const Color(0xFF29B6F6) : const Color(0xFFFF8A65);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

children: [
        // Header Section (የተጠቃሚው ፕሮፋይልና ስም)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
                image: avatarUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white70, size: 32)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Level Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isWealth ? Icons.shield : Icons.favorite,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "$level",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$valueLabel: $currentValue",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Progress Bar Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Lv.$level",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              level >= 99
                  ? "Max Level Reached"
                  : "Need $neededForUpgrade $unitLabel for the upgrade",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),

),
            Text(
              "Lv.$nextLevel",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWealth
                      ? [const Color(0xFF00E5FF), const Color(0xFF2979FF)]
                      : [const Color(0xFFFF4081), const Color(0xFFFF80AB)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),

        const SizedBox(height: 26),

        // Title and Subtitle
        Text(
          isWealth ? "Wealth Level" : "Charm Level",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subDescription,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11.5,
          ),
        ),

        const SizedBox(height: 16),

        // 10 የሌቭል እርከኖች ካርዶች (Lv.1-9 እስከ Lv.90-99)
        ..._levelTiers.map((tier) {
          final String range = tier['range'];
          final int tagNum = tier['tag'];
          final bool hasMedal = tier['hasMedal'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  range,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181318),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: hasMedal
                      ? Row(
                          children: [
                            // Wealth Tag Box
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Wealth Tag",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: tagColor,

borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isWealth ? Icons.shield : Icons.favorite,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "$tagNum",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 34,
                              width: 1,
                              color: Colors.white12,
                            ),
                            // Medal Details Box
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Medal Details",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildMedalIcon(tagNum, isWealth),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Wealth Tag",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isWealth ? Icons.shield : Icons.favorite,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(

"$tagNum",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
