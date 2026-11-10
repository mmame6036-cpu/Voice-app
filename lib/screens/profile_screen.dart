import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'wallet_screen.dart';
import 'points_wallet_screen.dart';
import 'store_screen.dart';
import 'invitation_screen.dart';
import 'backpack_screen.dart';
import 'level_screen.dart';
import 'task_screen.dart';
import 'badge_screen.dart';
import 'host_center_screen.dart';
import 'agency_screen.dart';
import 'coin_seller_screen.dart';
import 'support_screen.dart';
import '../widgets/lucky_island_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final int currentCoins;
  final Function(int)? onCoinsUpdated;

  const ProfileScreen({
    super.key,
    this.currentCoins = 0,
    this.onCoinsUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late int _coins;

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
  }

  void _updateCoins(int newAmount) {
    setState(() => _coins = newAmount);
    widget.onCoinsUpdated?.call(newAmount);
  }

  void _copyId(String displayId) {
    Clipboard.setData(ClipboardData(text: displayId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("ID $displayId copied to clipboard"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openLuckyIsland() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LuckyIslandDialog(),
    );
  }

  void _openPointsWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PointsWalletScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : null,
        builder: (context, snapshot) {
          final userData = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final String displayName = userData['name'] ??
              userData['nickname'] ??
              _currentUser?.displayName ??
              "User";

          final int numericId = (userData['numericId'] as num?)?.toInt() ?? 0;
          final String displayId = numericId != 0
              ? numericId.toString()
              : (uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : (uid.isEmpty ? "000000" : uid));

          final int firestoreCoins = (userData['coins'] as num?)?.toInt() ?? _coins;
          final double points = (userData['diamonds'] as num?)?.toDouble() ??
              (userData['points'] as num?)?.toDouble() ??
              0.0;

          final int followedCount = (userData['followedCount'] as num?)?.toInt() ?? 0;
          final int followingCount = (userData['followingCount'] as num?)?.toInt() ?? 0;
          final int friendsCount = (userData['friendsCount'] as num?)?.toInt() ?? 0;

          final int wealthLevel = (userData['wealthLevel'] as num?)?.toInt() ?? 0;
          final int charmLevel = (userData['charmLevel'] as num?)?.toInt() ?? 0;
          final int chatLevel = (userData['chatLevel'] as num?)?.toInt() ?? 0;
          final String? agencyId = userData['agencyId'];
          final String? avatarUrl = userData['avatarUrl'];

          return SafeArea(
            child: SingleChildScrollView(

padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // 1. User Header Section
                  _buildHeaderSection(
                    name: displayName,
                    displayId: displayId,
                    avatarUrl: avatarUrl,
                    wealthLevel: wealthLevel,
                    charmLevel: charmLevel,
                    chatLevel: chatLevel,
                    hasAgency: agencyId != null && agencyId.isNotEmpty,
                    followed: followedCount,
                    following: followingCount,
                    friends: friendsCount,
                  ),
                  const SizedBox(height: 14),

                  // 2. VIP CLUB Banner
                  _buildVipClubCard(),
                  const SizedBox(height: 12),

                  // 3. COINS & POINTS Card (Tapping Points opens PointsWalletScreen)
                  _buildAssetsCard(
                    coins: firestoreCoins,
                    points: points,
                    numericId: numericId,
                  ),
                  const SizedBox(height: 14),

                  // 4. Main 8 Features Grid
                  _buildMainFeaturesGrid(coins: firestoreCoins, numericId: numericId),
                  const SizedBox(height: 14),

                  // 5. Promo Recharge Banner
                  _buildPromoRechargeBanner(coins: firestoreCoins, numericId: numericId),
                  const SizedBox(height: 14),

                  // 6. Creator & Business Section
                  _buildBusinessSection(numericId: numericId),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 1. Header Section
  Widget _buildHeaderSection({
    required String name,
    required String displayId,
    required String? avatarUrl,
    required int wealthLevel,
    required int charmLevel,
    required int chatLevel,
    required bool hasAgency,
    required int followed,
    required int following,
    required int friends,
  }) {
    return Column(
      children: [
        Row(
          children: [
            // Avatar with Frame
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDF9E), Color(0xFFF3BA2F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 36, color: Color(0xFFC7CBD1))
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Name, Badges & ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D2129),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildLevelTag(Icons.shield, "$wealthLevel", const Color(0xFF38D5C5)),
                      _buildLevelTag(Icons.arrow_upward, "$charmLevel", const Color(0xFF81D774)),
                      _buildLevelTag(Icons.auto_awesome, "$chatLevel", const Color(0xFFB57DE5)),
                      if (hasAgency)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5AB6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "AGENCY",
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _copyId(displayId),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "ID:$displayId",
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF86909C), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy, size: 11, color: Color(0xFF86909C)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFC9CDD4), size: 22),
          ],
        ),
        const SizedBox(height: 16),

        // Social Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("$followed", "Followed"),
            _buildStatItem("$following", "Following"),
            _buildStatItem("$friends", "Friends"),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelTag(IconData icon, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1D2129)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF86909C)),
        ),
      ],
    );
  }

  // 2. VIP Club Banner
  Widget _buildVipClubCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2D1D), Color(0xFF2B1D11)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [

const Icon(Icons.workspace_premium, color: Color(0xFFFFD580), size: 26),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "VIP Club",
                  style: TextStyle(color: Color(0xFFFFD580), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Upgrade to VIP and get free coins daily",
                  style: TextStyle(color: Color(0xFFD6C0B3), fontSize: 10.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFDF9E), Color(0xFFF3BA2F)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Get VIP",
              style: TextStyle(color: Color(0xFF3E2D1D), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Coins & Points Card
  Widget _buildAssetsCard({
    required int coins,
    required double points,
    required int numericId,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Coins side -> Opens Coin Wallet/Recharge
          Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalletScreen(
                    currentCoins: coins,
                    userNumericId: numericId,
                    userUid: _currentUser?.uid ?? "",
                    onCoinsRecharged: _updateCoins,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        "Coins",
                        style: TextStyle(fontSize: 12, color: Color(0xFF4E5969), fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 14, color: Color(0xFF86909C)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFB300), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "$coins",
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1D2129)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFF2F3F5)),
          const SizedBox(width: 18),

          // Points side -> Opens PointsWalletScreen
          Expanded(
            child: InkWell(
              onTap: _openPointsWallet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(

children: [
                      Text(
                        "Points",
                        style: TextStyle(fontSize: 12, color: Color(0xFF4E5969), fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 14, color: Color(0xFF86909C)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFF7E22CE), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        points.toInt().toString(),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Main 8 Features Grid
  Widget _buildMainFeaturesGrid({required int coins, required int numericId}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 4,
        childAspectRatio: 0.9,
        children: [
          _buildItemTile(
            icon: Icons.account_balance_wallet,
            color: const Color(0xFFFFA940),
            label: "Recharge",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WalletScreen(
                  currentCoins: coins,
                  userNumericId: numericId,
                  userUid: _currentUser?.uid ?? "",
                  onCoinsRecharged: _updateCoins,
                ),
              ),
            ),
          ),
          _buildItemTile(
            icon: Icons.storefront,
            color: const Color(0xFFFF4D4F),
            label: "Store",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreScreen(
                  userCoins: coins,
                  userNumericId: numericId,
                  onCoinsDeducted: _updateCoins,
                ),
              ),
            ),
          ),
          _buildItemTile(
            icon: Icons.mark_email_unread,
            color: const Color(0xFFFF7A45),
            label: "Invitation",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationScreen())),
          ),
          _buildItemTile(
            icon: Icons.backpack,
            color: const Color(0xFF40A9FF),
            label: "Backpack",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackpackScreen())),
          ),
          _buildItemTile(
            icon: Icons.landscape,
            color: const Color(0xFF73D13D),
            label: "Lucky Island",
            onTap: _openLuckyIsland,
          ),
          _buildItemTile(
            icon: Icons.military_tech,
            color: const Color(0xFF9254DE),
            label: "Level",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelScreen())),
          ),
          _buildItemTile(
            icon: Icons.event_available,

color: const Color(0xFF36CFC9),
            label: "Task",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskScreen())),
          ),
          _buildItemTile(
            icon: Icons.verified_user,
            color: const Color(0xFFFFC53D),
            label: "Badge",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgeScreen())),
          ),
        ],
      ),
    );
  }

  // 5. Promo Carousel Banner
  Widget _buildPromoRechargeBanner({required int coins, required int numericId}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletScreen(
            currentCoins: coins,
            userNumericId: numericId,
            userUid: _currentUser?.uid ?? "",
            onCoinsRecharged: _updateCoins,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2A54), Color(0xFFFF6B6B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2A54).withOpacity(0.24),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "UP TO 60% OFF",
                  style: TextStyle(color: Color(0xFFFFE58F), fontWeight: FontWeight.bold, fontSize: 11),
                ),
                SizedBox(height: 2),
                Text(
                  "COIN RECHARGE",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            Icon(Icons.savings, color: Color(0xFFFFE58F), size: 48),
          ],
        ),
      ),
    );
  }

  // 6. Creator & Business Section
  Widget _buildBusinessSection({required int numericId}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItemTile(
            icon: Icons.stars_rounded,
            color: const Color(0xFF7E22CE),
            label: "Points Wallet",
            onTap: _openPointsWallet,
          ),
          _buildItemTile(
            icon: Icons.person_pin,
            color: const Color(0xFF13C2C2),
            label: "Host Center",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostCenterScreen())),
          ),
          _buildItemTile(
            icon: Icons.business_center,
            color: const Color(0xFF1890FF),
            label: "Agency",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AgencyScreen(userNumericId: numericId)),
            ),
          ),
          _buildItemTile(
            icon: Icons.currency_exchange,

color: const Color(0xFF52C41A),
            label: "Coin Seller",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinSellerScreen())),
          ),
          _buildItemTile(
            icon: Icons.support_agent,
            color: const Color(0xFF722ED1),
            label: "Support",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E5969),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
