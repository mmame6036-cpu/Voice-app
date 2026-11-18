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
import 'account_settings_screen.dart';
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

  void _openAccountSettings({
    required String currentName,
    required String? avatarUrl,
    required int numericId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountSettingsScreen(
          currentName: currentName,
          currentAvatarUrl: avatarUrl,
          numericId: numericId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = "";
    if (_currentUser != null) {
      uid = _currentUser!.uid;
    }

    Stream? userStream;
    if (uid.isNotEmpty) {
      userStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: StreamBuilder(
        stream: userStream,
        builder: (context, snapshot) {
          DocumentSnapshot? docSnap;
          if (snapshot.hasData) {
            docSnap = snapshot.data as DocumentSnapshot?;
          }

          Object? rawData;
          if (docSnap != null) {
            if (docSnap.exists) {
              rawData = docSnap.data();
            }
          }
          final Map userData = rawData is Map ? rawData : {};

          String fallbackName = "User";
          if (_currentUser != null) {
            if (_currentUser!.displayName != null) {
              if (_currentUser!.displayName!.isNotEmpty) {
                fallbackName = _currentUser!.displayName!;
              }
            }
          }

          final String displayName =
              (userData['name'] ?? userData['nickname'] ?? fallbackName)
                  .toString();

          final int numericId = (userData['numericId'] as num?)?.toInt() ?? 0;
          String displayId = "000000";
          if (numericId != 0) {
            displayId = numericId.toString();
          } else if (uid.length >= 6) {
            displayId = uid.substring(0, 6).toUpperCase();
          } else if (uid.isNotEmpty) {
            displayId = uid;
          }

final int firestoreCoins =
              (userData['coins'] as num?)?.toInt() ?? _coins;
          final double points = (userData['diamonds'] as num?)?.toDouble() ??
              (userData['points'] as num?)?.toDouble() ??
              0.0;

          final int followedCount =
              (userData['followedCount'] as num?)?.toInt() ?? 0;
          final int followingCount =
              (userData['followingCount'] as num?)?.toInt() ?? 0;
          final int friendsCount =
              (userData['friendsCount'] as num?)?.toInt() ?? 0;

          final int wealthLevel =
              (userData['wealthLevel'] as num?)?.toInt() ?? 0;
          final int charmLevel =
              (userData['charmLevel'] as num?)?.toInt() ?? 0;
          final int chatLevel = (userData['chatLevel'] as num?)?.toInt() ?? 0;
          final String? agencyId = userData['agencyId']?.toString();
          final String? avatarUrl = userData['avatarUrl']?.toString();

          bool hasAgency = false;
          if (agencyId != null) {
            if (agencyId.isNotEmpty) {
              hasAgency = true;
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. የላይኛው Mint-Teal Gradient ክፍል (Profile + Stats + VIP)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 14,
                    16,
                    14,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFC2ECE3),
                        Color(0xFFE3F6F2),
                        Color(0xFFF3F5F7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildHeaderSection(
                        name: displayName,
                        displayId: displayId,
                        numericId: numericId,
                        avatarUrl: avatarUrl,
                        wealthLevel: wealthLevel,
                        charmLevel: charmLevel,
                        chatLevel: chatLevel,
                        hasAgency: hasAgency,
                        followed: followedCount,
                        following: followingCount,
                        friends: friendsCount,
                      ),
                      const SizedBox(height: 16),
                      _buildVipClubCard(),
                    ],
                  ),
                ),

                // 2. COINS & POINTS Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _buildAssetsCard(
                    coins: firestoreCoins,
                    points: points,
                    numericId: numericId,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Main 8 Features Grid (ጉልት እና ባለ 3D መልክ)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _buildMainFeaturesGrid(
                    coins: firestoreCoins,
                    numericId: numericId,
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Promo Recharge Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _buildPromoRechargeBanner(
                    coins: firestoreCoins,
                    numericId: numericId,
                  ),
                ),
                const SizedBox(height: 12),

// 5. Creator, Business & Settings Section (እንደ Hala ደማቅ Teal)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _buildBusinessSection(
                    numericId: numericId,
                    currentName: displayName,
                    avatarUrl: avatarUrl,
                  ),
                ),
                const SizedBox(height: 28),
              ],
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
    required int numericId,
    required String? avatarUrl,
    required int wealthLevel,
    required int charmLevel,
    required int chatLevel,
    required bool hasAgency,
    required int followed,
    required int following,
    required int friends,
  }) {
    ImageProvider? avatarImg;
    Widget? avatarPlaceholder = const Icon(
      Icons.person_rounded,
      size: 40,
      color: Colors.white,
    );

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarImg = NetworkImage(avatarUrl);
      avatarPlaceholder = null;
    }

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openAccountSettings(
            currentName: name,
            avatarUrl: avatarUrl,
            numericId: numericId,
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF9B87B5),
                  backgroundImage: avatarImg,
                  child: avatarPlaceholder,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildLevelTag(Icons.shield, "$wealthLevel",
                            const Color(0xFF14B8A6)),
                        _buildLevelTag(Icons.arrow_upward, "$charmLevel",
                            const Color(0xFF22C55E)),
                        _buildLevelTag(Icons.auto_awesome, "$chatLevel",
                            const Color(0xFF9333EA)),
                        if (hasAgency)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(

"AGENCY",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _copyId(displayId),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "ID:$displayId",
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy_rounded,
                              size: 14, color: Color(0xFF475569)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF475569), size: 28),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("$followed", "Followed"),
            Container(height: 22, width: 1, color: Colors.black12),
            _buildStatItem("$following", "Following"),
            Container(height: 22, width: 1, color: Colors.black12),
            _buildStatItem("$friends", "Friends"),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelTag(IconData icon, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 2.5),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
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
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569)),
        ),
      ],
    );
  }

  // 2. VIP Club Banner
  Widget _buildVipClubCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2D1D), Color(0xFF26190E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium,
              color: Color(0xFFFFD580), size: 32),

const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "VIP Club",
                  style: TextStyle(
                      color: Color(0xFFFFE099),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  "Upgrade to VIP and get free coins daily",
                  style: TextStyle(
                      color: Color(0xFFE5D3C5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFDF9E), Color(0xFFF3BA2F)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Get VIP",
              style: TextStyle(
                  color: Color(0xFF2B1D10),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900),
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
    String currentUid = "";
    if (_currentUser != null) {
      currentUid = _currentUser!.uid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalletScreen(
                    currentCoins: coins,
                    userNumericId: numericId,
                    userUid: currentUid,
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
                        style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded,
                          color: Color(0xFFF59E0B), size: 26),
                      const SizedBox(width: 7),
                      Text(
                        "$coins",
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                ],

),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 18),
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
                        style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Color(0xFF14B8A6), size: 26),
                      const SizedBox(width: 7),
                      Text(
                        points.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF14B8A6)),
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

  // 4. Main 8 Features Grid (ጉልት እና 3D መልክ ያላቸው አዶዎች)
  Widget _buildMainFeaturesGrid({required int coins, required int numericId}) {
    String currentUid = "";
    if (_currentUser != null) {
      currentUid = _currentUser!.uid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 6,
        childAspectRatio: 0.88,
        children: [
          _buildBoldFeatureTile(
            icon: Icons.account_balance_wallet_rounded,
            colors: const [Color(0xFFFFB703), Color(0xFFFB8500)],
            label: "Recharge",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WalletScreen(
                  currentCoins: coins,
                  userNumericId: numericId,
                  userUid: currentUid,
                  onCoinsRecharged: _updateCoins,
                ),
              ),
            ),
          ),
          _buildBoldFeatureTile(
            icon: Icons.storefront_rounded,
            colors: const [Color(0xFFFF5A5F), Color(0xFFE01E37)],
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
          _buildBoldFeatureTile(
            icon: Icons.mark_email_unread_rounded,
            colors: const [Color(0xFFFF758F), Color(0xFFC9184A)],
            label: "Invitation",
            onTap: () => Navigator.push(context,

MaterialPageRoute(builder: (_) => const InvitationScreen())),
          ),
          _buildBoldFeatureTile(
            icon: Icons.backpack_rounded,
            colors: const [Color(0xFF4CC9F0), Color(0xFF3A86FF)],
            label: "Backpack",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BackpackScreen())),
          ),
          _buildBoldFeatureTile(
            icon: Icons.beach_access_rounded,
            colors: const [Color(0xFF52B788), Color(0xFF2D6A4F)],
            label: "Lucky Island",
            onTap: _openLuckyIsland,
          ),
          _buildBoldFeatureTile(
            icon: Icons.military_tech_rounded,
            colors: const [Color(0xFFB5179E), Color(0xFF7209B7)],
            label: "Level",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LevelScreen())),
          ),
          _buildBoldFeatureTile(
            icon: Icons.event_available_rounded,
            colors: const [Color(0xFF2EC4B6), Color(0xFF0096C7)],
            label: "Task",
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TaskScreen())),
          ),
          _buildBoldFeatureTile(
            icon: Icons.verified_rounded,
            colors: const [Color(0xFFFF9E00), Color(0xFFFF6D00)],
            label: "Badge",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BadgeScreen())),
          ),
        ],
      ),
    );
  }

  // 5. Promo Carousel Banner
  Widget _buildPromoRechargeBanner(
      {required int coins, required int numericId}) {
    String currentUid = "";
    if (_currentUser != null) {
      currentUid = _currentUser!.uid;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletScreen(
            currentCoins: coins,
            userNumericId: numericId,
            userUid: currentUid,
            onCoinsRecharged: _updateCoins,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 94,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF233C), Color(0xFFD90429)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF233C).withOpacity(0.28),
              blurRadius: 10,
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
                  style: TextStyle(
                      color: Color(0xFFFFE58F),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 11.5),
                ),
                SizedBox(height: 3),
                Text(
                  "COIN RECHARGE",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 19),
                ),
              ],
            ),
            Icon(Icons.savings_rounded, color: Color(0xFFFFD166), size: 46),
          ],
        ),
      ),
    );
  }

  // 6. Creator, Business & Settings Section (ልክ እንደ Hala ደማቅ Teal)

Widget _buildBusinessSection({
    required int numericId,
    required String currentName,
    required String? avatarUrl,
  }) {
    final List<Widget> items = [
      _buildTealServiceTile(
        icon: Icons.stars_rounded,
        label: "Points Wallet",
        onTap: _openPointsWallet,
      ),
      _buildTealServiceTile(
        icon: Icons.record_voice_over_rounded,
        label: "Host Center",
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HostCenterScreen())),
      ),
      _buildTealServiceTile(
        icon: Icons.business_center_rounded,
        label: "Agency",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AgencyScreen(userNumericId: numericId)),
        ),
      ),
      _buildTealServiceTile(
        icon: Icons.currency_exchange_rounded,
        label: "Coin Seller",
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CoinSellerScreen())),
      ),
      _buildTealServiceTile(
        icon: Icons.headset_mic_rounded,
        label: "Support",
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SupportScreen())),
      ),
      _buildTealServiceTile(
        icon: Icons.settings_rounded,
        label: "Settings",
        onTap: () => _openAccountSettings(
          currentName: currentName,
          avatarUrl: avatarUrl,
          numericId: numericId,
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 6,
        childAspectRatio: 0.9,
        children: items,
      ),
    );
  }

  Widget _buildBoldFeatureTile({
    required IconData icon,
    required List<Color> colors,
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(0.32),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTealServiceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,

child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF14B8A6),
            size: 34,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
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
