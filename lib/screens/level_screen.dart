import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vip_screen.dart';

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

  final List<Map<String, dynamic>> _levelTiers = const [
    {"range": "Lv.1-9", "min": 1, "max": 9, "tag": 1, "hasMedal": false},
    {"range": "Lv.10-19", "min": 10, "max": 19, "tag": 10, "hasMedal": true},
    {"range": "Lv.20-29", "min": 20, "max": 29, "tag": 20, "hasMedal": true},
    {"range": "Lv.30-39", "min": 30, "max": 39, "tag": 30, "hasMedal": true},
    {"range": "Lv.40-49", "min": 40, "max": 49, "tag": 40, "hasMedal": true},
    {"range": "Lv.50-59", "min": 50, "max": 59, "tag": 50, "hasMedal": true},
    {"range": "Lv.60-69", "min": 60, "max": 69, "tag": 60, "hasMedal": true},
    {"range": "Lv.70-79", "min": 70, "max": 79, "tag": 70, "hasMedal": true},
    {"range": "Lv.80-89", "min": 80, "max": 89, "tag": 80, "hasMedal": true},
    {"range": "Lv.90-99", "min": 90, "max": 99, "tag": 90, "hasMedal": true},
  ];

  ImageProvider? _resolveAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null) return null;
    final String clean = avatarUrl.trim();
    if (clean.isEmpty) return null;
    if (clean.startsWith('data:image')) {
      try {
        final int commaIdx = clean.indexOf(',');
        if (commaIdx != -1) {
          final Uint8List bytes = base64Decode(clean.substring(commaIdx + 1));
          return MemoryImage(bytes);
        }
      } catch (_) {
        return null;
      }
    }
    if (clean.startsWith('http')) {
      return NetworkImage(clean);
    }
    return null;
  }

  int _computeLevelFromExp(int exp, int storedLevel) {
    final int safeExp = exp < 0 ? 0 : exp;
    final int computed = ((safeExp ~/ 5000) + 1).clamp(1, 99);
    if (computed > storedLevel) return computed;
    return storedLevel.clamp(1, 99);
  }

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
          return const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 36);
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
                final Map<String, dynamic> userData =
                    (snapshot.hasData && snapshot.data!.exists)
                        ? (snapshot.data!.data() as Map<String, dynamic>? ?? {})
                        : <String, dynamic>{};

                String fallbackName = "User";
                if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
                  fallbackName = _user!.displayName!;
                }

                final String name = (userData['name'] ??
                        userData['nickname'] ??
                        userData['displayName'] ??
                        fallbackName)
                    .toString();

                final String avatarUrl = (userData['avatarUrl'] ??
                        userData['photoURL'] ??
                        userData['avatar'] ??
                        _user?.photoURL ??
                        "")
                    .toString();

                final int numericId =
                    (userData['numericId'] as num?)?.toInt() ?? 0;

                final int wealthExp = (userData['wealthExp'] as num?)?.toInt() ?? 0;
                final int storedWealthLvl =
                    (userData['wealthLevel'] as num?)?.toInt() ?? 1;
                final int wealthLevel =
                    _computeLevelFromExp(wealthExp, storedWealthLvl);

                int charmExp = (userData['charmExp'] as num?)?.toInt() ?? 0;
                final int pts = (userData['points'] as num?)?.toInt() ?? 0;
                final int recPts =
                    (userData['receivedGiftPoints'] as num?)?.toInt() ?? 0;
                if (pts > charmExp) charmExp = pts;
                if (recPts > charmExp) charmExp = recPts;

                final int storedCharmLvl =
                    (userData['charmLevel'] as num?)?.toInt() ?? 1;
                final int charmLevel =
                    _computeLevelFromExp(charmExp, storedCharmLvl);

                final int vipLevel =
                    (userData['vipLevel'] as num?)?.toInt() ?? 0;
                final int activeVipFrame =
                    (userData['activeVipFrameLevel'] as num?)?.toInt() ??
                        vipLevel;
                final Timestamp? vipExpiresAt =
                    userData['vipExpiresAt'] as Timestamp?;
                bool isVipActive = false;
                if (vipLevel > 0) {
                  if (vipExpiresAt == null) {
                    isVipActive = true;
                  } else if (vipExpiresAt.toDate().isAfter(DateTime.now())) {
                    isVipActive = true;
                  }
                }
                final int effectiveFrameLevel =
                    isVipActive ? activeVipFrame : 0;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContent(
                      isWealth: true,
                      name: name,
                      numericId: numericId,
                      avatarUrl: avatarUrl,
                      activeFrameLevel: effectiveFrameLevel,
                      level: wealthLevel,
                      currentValue: wealthExp,
                      subDescription: "Wealth level is based on total coins recharged.",
                    ),
                    _buildContent(
                      isWealth: false,
                      name: name,
                      numericId: numericId,
                      avatarUrl: avatarUrl,
                      activeFrameLevel: effectiveFrameLevel,
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
    required int numericId,
    required String avatarUrl,
    required int activeFrameLevel,
    required int level,
    required int currentValue,
    required String subDescription,
  }) {
    final int nextLevel = level < 99 ? level + 1 : 99;
    final int currentLevelFloor = (level - 1) * 5000;
    final int targetExpForNext = nextLevel * 5000;
    final int span = (targetExpForNext - currentLevelFloor).clamp(1, 999999999);
    final int earnedInCurrentLevel =
        (currentValue - currentLevelFloor).clamp(0, span);
    final int neededForUpgrade =
        (targetExpForNext - currentValue).clamp(0, targetExpForNext);
    final double progress = level >= 99
        ? 1.0
        : (earnedInCurrentLevel / span).clamp(0.0, 1.0);

    final String valueLabel = isWealth ? "Wealth Value" : "Charm Value";
    final String tagTitle = isWealth ? "Wealth Tag" : "Charm Tag";
    final String unitLabel = isWealth ? "coins" : "points";
    final Color tagColor =
        isWealth ? const Color(0xFF29B6F6) : const Color(0xFFFF8A65);

    final ImageProvider? avatarImg = _resolveAvatarProvider(avatarUrl);

    final Widget plainAvatar = Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
        image: avatarImg != null
            ? DecorationImage(image: avatarImg, fit: BoxFit.cover)
            : null,
      ),
      child: avatarImg == null
          ? const Icon(Icons.person, color: Colors.white70, size: 32)
          : null,
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            activeFrameLevel > 0
                ? VipAvatarFrame(
                    vipLevel: activeFrameLevel,
                    size: 58,
                    showBadge: false,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF261E29),
                      backgroundImage: avatarImg,
                      child: avatarImg == null
                          ? const Icon(Icons.person,
                              color: Colors.white70, size: 30)
                          : null,
                    ),
                  )
                : plainAvatar,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                  if (numericId != 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      "ID: $numericId",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
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
        ..._levelTiers.map((tier) {
          final String range = tier['range'] as String;
          final int minLv = tier['min'] as int;
          final int maxLv = tier['max'] as int;
          final int tagNum = tier['tag'] as int;
          final bool hasMedal = tier['hasMedal'] as bool;
          final bool isCurrentRange = level >= minLv && level <= maxLv;

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      range,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrentRange) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tagColor, width: 1),
                        ),
                        child: Text(
                          "Current",
                          style: TextStyle(
                            color: tagColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181318),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrentRange
                          ? tagColor.withOpacity(0.6)
                          : Colors.white.withOpacity(0.06),
                      width: isCurrentRange ? 1.4 : 1,
                    ),
                  ),
                  child: hasMedal
                      ? Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tagTitle,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: tagColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isWealth
                                              ? Icons.shield
                                              : Icons.favorite,
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
                              Text(
                                tagTitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
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
