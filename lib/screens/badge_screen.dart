import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final Color badgeColor;
  final int requiredValue;
  final String requirementKey;

  const BadgeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.badgeColor,
    required this.requiredValue,
    required this.requirementKey,
  });
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color cardBg = Colors.white;
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color borderColor = Color(0xFFE2D6C5);
  static const Color buttonDark = Color(0xFF4A3528);

  final List<String> _badgeCategories = const [
    "Achievement",
    "Wealth",
    "Activity",
    "Honor",
  ];

  final List<BadgeItem> _allBadges = const [
    // Achievement Badges
    BadgeItem(
      id: "ach_first_gift",
      name: "First Gift",
      category: "Achievement",
      description: "Send your first gift in any voice room.",
      icon: Icons.card_giftcard,
      badgeColor: Color(0xFFE91E63),
      requiredValue: 1,
      requirementKey: "totalGiftsSent",
    ),
    BadgeItem(
      id: "ach_star_host",
      name: "Star Host",
      category: "Achievement",
      description: "Reach 120 live mic minutes as host.",
      icon: Icons.mic,
      badgeColor: Color(0xFF9C27B0),
      requiredValue: 120,
      requirementKey: "todayMicMinutes",
    ),
    BadgeItem(
      id: "ach_big_winner",
      name: "Lucky Winner",
      category: "Achievement",
      description: "Trigger a Lucky Gift multiplier win.",
      icon: Icons.casino,
      badgeColor: Color(0xFFFF9800),
      requiredValue: 1,
      requirementKey: "luckyWinsCount",
    ),
    BadgeItem(
      id: "ach_popular_room",
      name: "Party Host",
      category: "Achievement",
      description: "Host 30 seated members in your room.",
      icon: Icons.groups,
      badgeColor: Color(0xFF00BCD4),
      requiredValue: 30,
      requirementKey: "maxRoomUsers",
    ),

    // Wealth Badges
    BadgeItem(
      id: "w_bronze_tycoon",
      name: "Bronze Tycoon",
      category: "Wealth",
      description: "Accumulate 10,000 Wealth EXP.",
      icon: Icons.shield,
      badgeColor: Color(0xFF8D6E63),
      requiredValue: 10000,
      requirementKey: "wealthExp",
    ),
    BadgeItem(
      id: "w_silver_patron",
      name: "Silver Patron",
      category: "Wealth",
      description: "Accumulate 50,000 Wealth EXP.",
      icon: Icons.shield,
      badgeColor: Color(0xFF90A4AE),
      requiredValue: 50000,
      requirementKey: "wealthExp",
    ),
    BadgeItem(
      id: "w_golden_emperor",
      name: "Golden Emperor",
      category: "Wealth",
      description: "Accumulate 200,000 Wealth EXP.",
      icon: Icons.workspace_premium,
      badgeColor: Color(0xFFFFD700),
      requiredValue: 200000,
      requirementKey: "wealthExp",
    ),
    BadgeItem(
      id: "w_diamond_legend",
      name: "Diamond Legend",
      category: "Wealth",
      description: "Accumulate 1,000,000 Wealth EXP.",
      icon: Icons.diamond,
      badgeColor: Color(0xFF00E5FF),
      requiredValue: 1000000,
      requirementKey: "wealthExp",
    ),

// Activity Badges
    BadgeItem(
      id: "act_daily_login",
      name: "Faithful Fan",
      category: "Activity",
      description: "Stay in active voice rooms for 30 minutes.",
      icon: Icons.access_time_filled,
      badgeColor: Color(0xFF4CAF50),
      requiredValue: 30,
      requirementKey: "todayMicMinutes",
    ),
    BadgeItem(
      id: "act_task_master",
      name: "Task Master",
      category: "Activity",
      description: "Earn 5,000 points from Task Center.",
      icon: Icons.task_alt,
      badgeColor: Color(0xFF009688),
      requiredValue: 5000,
      requirementKey: "todayTaskPoints",
    ),
    BadgeItem(
      id: "act_gift_enthusiast",
      name: "Super Supporter",
      category: "Activity",
      description: "Spend 20,000 coins in rooms.",
      icon: Icons.monetization_on,
      badgeColor: Color(0xFFFF5722),
      requiredValue: 20000,
      requirementKey: "wealthExp",
    ),
    BadgeItem(
      id: "act_socialite",
      name: "Room Socialite",
      category: "Activity",
      description: "Join official agency team as host.",
      icon: Icons.domain,
      badgeColor: Color(0xFF3F51B5),
      requiredValue: 1,
      requirementKey: "hasAgency",
    ),

    // Honor Badges
    BadgeItem(
      id: "hon_charm_ambassador",
      name: "Charm Star",
      category: "Honor",
      description: "Reach 50,000 Charm EXP.",
      icon: Icons.favorite,
      badgeColor: Color(0xFFFF4081),
      requiredValue: 50000,
      requirementKey: "charmExp",
    ),
    BadgeItem(
      id: "hon_supreme_voice",
      name: "Supreme Voice",
      category: "Honor",
      description: "Reach Level 10 Charm Level.",
      icon: Icons.military_tech,
      badgeColor: Color(0xFF7C4DFF),
      requiredValue: 10,
      requirementKey: "charmLevel",
    ),
    BadgeItem(
      id: "hon_top_merchant",
      name: "Merchant Icon",
      category: "Honor",
      description: "Upgrade seller status in Coin Seller Hub.",
      icon: Icons.storefront,
      badgeColor: Color(0xFFD49B42),
      requiredValue: 1,
      requirementKey: "isSeller",
    ),
    BadgeItem(
      id: "hon_crown_ruler",
      name: "Crown Monarch",
      category: "Honor",
      description: "Unlock supreme server privileges at Level 99.",
      icon: Icons.workspace_premium,
      badgeColor: Color(0xFFFFD700),
      requiredValue: 99,
      requirementKey: "wealthLevel",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _badgeCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBrown,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _checkIsUnlocked(BadgeItem badge, Map<String, dynamic> userData) {
    final manualUnlocked = (userData['unlockedBadges'] as List?) ?? [];
    if (manualUnlocked.contains(badge.id)) return true;

    if (badge.requirementKey == "hasAgency") {
      final agencyId = (userData['agencyId'] ?? "").toString();
      return agencyId.isNotEmpty;
    }

    if (badge.requirementKey == "isSeller") {
      final role = (userData['sellerLevel'] ?? userData['role'] ?? "").toString();
      return role.isNotEmpty;
    }

    final int userValue = (userData[badge.requirementKey] as num?)?.toInt() ?? 0;
    return userValue >= badge.requiredValue;
  }

  Future<void> _toggleWearBadge(String badgeId, String currentEquippedBadge) async {
    if (_currentUser == null) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

try {
      if (currentEquippedBadge == badgeId) {
        await userRef.set({'equippedBadge': ""}, SetOptions(merge: true));
        _showToast("Badge unequipped.");
      } else {
        await userRef.set({'equippedBadge': badgeId}, SetOptions(merge: true));
        _showToast("Badge equipped successfully!");
      }
    } catch (e) {
      _showToast("Error updating badge: $e");
    }
  }

  void _showBadgeDetailModal(BadgeItem badge, bool isUnlocked, bool isEquipped) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 18),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? badge.badgeColor.withOpacity(0.18) : Colors.black12,
                border: Border.all(
                  color: isUnlocked ? badge.badgeColor : Colors.black26,
                  width: 2,
                ),
              ),
              child: Icon(
                badge.icon,
                color: isUnlocked ? badge.badgeColor : Colors.black38,
                size: 38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle : Icons.lock,
                    color: isUnlocked ? const Color(0xFF107C41) : Colors.black45,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlocked ? "Status: Unlocked" : "Status: Locked",
                    style: TextStyle(
                      color: isUnlocked ? const Color(0xFF107C41) : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isUnlocked)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEquipped ? const Color(0xFFD32F2F) : buttonDark,

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleWearBadge(badge.id, isEquipped ? badge.id : "");
                  },
                  child: Text(
                    isEquipped ? "Unequip Badge" : "Wear Badge",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
    final String uid = _currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryBrown, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Medals & Badges",
          style: TextStyle(
            color: primaryBrown,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : null,
        builder: (context, snapshot) {
          final userData = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final String equippedBadgeId = userData['equippedBadge'] ?? "";

          int unlockedTotal = 0;
          for (final b in _allBadges) {
            if (_checkIsUnlocked(b, userData)) {
              unlockedTotal++;
            }
          }

          return Column(
            children: [
              // 1. Summary Header Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: const Center(
                        child: Icon(Icons.military_tech, color: accentGold, size: 30),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "My Badges Collection",
                            style: TextStyle(
                              color: primaryBrown,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Unlocked: $unlockedTotal / ${_allBadges.length}",
                            style: const TextStyle(color: Colors.black45, fontSize: 12),
                          ),
                        ],

),
                    ),
                    if (equippedBadgeId.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF107C41),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Active",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 2. Tabs Selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DFD8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: buttonDark,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6D5446),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  tabs: _badgeCategories.map((cat) => Tab(text: cat)).toList(),
                ),
              ),

              const SizedBox(height: 6),

              // 3. Tab Grid View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _badgeCategories.map((cat) {
                    final categoryBadges = _allBadges.where((b) => b.category == cat).toList();
                    return _buildBadgeGrid(categoryBadges, userData, equippedBadgeId);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgeGrid(
    List<BadgeItem> badges,
    Map<String, dynamic> userData,
    String equippedBadgeId,
  ) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, idx) {
        final badge = badges[idx];
        final bool isUnlocked = _checkIsUnlocked(badge, userData);
        final bool isEquipped = equippedBadgeId == badge.id;

        return GestureDetector(
          onTap: () => _showBadgeDetailModal(badge, isUnlocked, isEquipped),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEquipped
                    ? accentGold
                    : (isUnlocked ? borderColor : Colors.black12),
                width: isEquipped ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,

children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? badge.badgeColor.withOpacity(0.14)
                            : bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnlocked
                              ? badge.badgeColor.withOpacity(0.6)
                              : borderColor,
                        ),
                      ),
                      child: Icon(
                        badge.icon,
                        color: isUnlocked ? badge.badgeColor : Colors.black26,
                        size: 30,
                      ),
                    ),
                    if (!isUnlocked)
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.lock, color: Colors.black45, size: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  badge.name,
                  style: TextStyle(
                    color: isUnlocked ? primaryBrown : Colors.black45,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isUnlocked ? "Unlocked" : "Locked",
                  style: TextStyle(
                    color: isUnlocked ? const Color(0xFF107C41) : Colors.black38,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: isUnlocked
                      ? () => _toggleWearBadge(badge.id, equippedBadgeId)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isEquipped
                          ? accentGold
                          : (isUnlocked ? buttonDark : Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isEquipped ? "Wearing" : (isUnlocked ? "Wear" : "Locked"),
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.black38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
