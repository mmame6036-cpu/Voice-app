import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VipPrivilegeItem {
  final String label;
  final IconData icon;
  final bool isUnlocked;

  const VipPrivilegeItem({
    required this.label,
    required this.icon,
    this.isUnlocked = true,
  });
}

class VipLevelSpec {
  final int level;
  final String name;
  final int priceCoins;
  final int dailyClaimCoins;
  final int durationDays;
  final int unlockedCount;
  final List<String> frameAssetCandidates;
  final List<Color> headerGradient;
  final Color accentColor;
  final Color badgeColor;
  final List<VipPrivilegeItem> privileges;

  const VipLevelSpec({
    required this.level,
    required this.name,
    required this.priceCoins,
    required this.dailyClaimCoins,
    required this.durationDays,
    required this.unlockedCount,
    required this.frameAssetCandidates,
    required this.headerGradient,
    required this.accentColor,
    required this.badgeColor,
    required this.privileges,
  });
}

const List<VipLevelSpec> kVipClubLevels = [
  VipLevelSpec(
    level: 1,
    name: "VIP1",
    priceCoins: 51000,
    dailyClaimCoins: 2000,
    durationDays: 30,
    unlockedCount: 11,
    frameAssetCandidates: [
      "assets/vip_frames/assets vip_frames vip1.jpg",
      "assets/vip_frames/vip1.jpg",
      "assets/vip_frames/vip1.png",
    ],
    headerGradient: [Color(0xFF9E6B55), Color(0xFF5C3A2B), Color(0xFF231712)],
    accentColor: Color(0xFFE7A98B),
    badgeColor: Color(0xFFB87A60),
    privileges: [
      VipPrivilegeItem(label: "Daily Coins", icon: Icons.monetization_on_rounded),
      VipPrivilegeItem(label: "Room Bullet Screen", icon: Icons.subtitles_rounded),
      VipPrivilegeItem(label: "More Admin", icon: Icons.manage_accounts_rounded),
      VipPrivilegeItem(label: "Greeting Limit", icon: Icons.chat_bubble_rounded),
      VipPrivilegeItem(label: "People Following", icon: Icons.person_add_alt_1_rounded),
      VipPrivilegeItem(label: "VIP Badge", icon: Icons.military_tech_rounded),
      VipPrivilegeItem(label: "Online User", icon: Icons.vertical_align_top_rounded),
      VipPrivilegeItem(label: "Entry Tag", icon: Icons.workspace_premium_rounded),
      VipPrivilegeItem(label: "Profile Card", icon: Icons.badge_rounded),
      VipPrivilegeItem(label: "Floral Frame", icon: Icons.local_florist_rounded),
      VipPrivilegeItem(label: "Gift Discount", icon: Icons.card_giftcard_rounded),
    ],
  ),
  VipLevelSpec(
    level: 2,
    name: "VIP2",
    priceCoins: 96000,
    dailyClaimCoins: 3500,
    durationDays: 30,
    unlockedCount: 12,
    frameAssetCandidates: [
      "assets/vip_frames/assets vip_frames vip2.jpg",
      "assets/vip_frames/vip2.jpg",
      "assets/vip_frames/vip2.png",
    ],
    headerGradient: [Color(0xFF5271A8), Color(0xFF2E436E), Color(0xFF141E33)],
    accentColor: Color(0xFF93C5FD),
    badgeColor: Color(0xFF3B82F6),
    privileges: [
      VipPrivilegeItem(label: "Daily Coins", icon: Icons.monetization_on_rounded),
      VipPrivilegeItem(label: "Room Bullet Screen", icon: Icons.subtitles_rounded),
      VipPrivilegeItem(label: "More Admin", icon: Icons.manage_accounts_rounded),
      VipPrivilegeItem(label: "Greeting Limit", icon: Icons.chat_bubble_rounded),
      VipPrivilegeItem(label: "People Following", icon: Icons.person_add_alt_1_rounded),
      VipPrivilegeItem(label: "VIP Badge", icon: Icons.military_tech_rounded),
      VipPrivilegeItem(label: "Online User", icon: Icons.vertical_align_top_rounded),
      VipPrivilegeItem(label: "Entry Tag", icon: Icons.workspace_premium_rounded),
      VipPrivilegeItem(label: "Entrance Effect", icon: Icons.auto_awesome_rounded),
      VipPrivilegeItem(label: "Profile Card", icon: Icons.badge_rounded),

VipPrivilegeItem(label: "Floral Frame", icon: Icons.local_florist_rounded),
      VipPrivilegeItem(label: "Priority Mic", icon: Icons.mic_rounded),
    ],
  ),
  VipLevelSpec(
    level: 3,
    name: "VIP3",
    priceCoins: 240000,
    dailyClaimCoins: 8500,
    durationDays: 30,
    unlockedCount: 16,
    frameAssetCandidates: [
      "assets/vip_frames/assets vip_frames vip3.jpg",
      "assets/vip_frames/vip3.jpg",
      "assets/vip_frames/vip3.png",
    ],
    headerGradient: [Color(0xFF2E8B57), Color(0xFF1A5636), Color(0xFF0D2B1B)],
    accentColor: Color(0xFF6EE7B7),
    badgeColor: Color(0xFF10B981),
    privileges: [
      VipPrivilegeItem(label: "Customer Support", icon: Icons.support_agent_rounded),
      VipPrivilegeItem(label: "Daily Coins", icon: Icons.monetization_on_rounded),
      VipPrivilegeItem(label: "Global Entry Tag", icon: Icons.public_rounded),
      VipPrivilegeItem(label: "Global Bullet Screen", icon: Icons.campaign_rounded),
      VipPrivilegeItem(label: "Room Bullet Screen", icon: Icons.subtitles_rounded),
      VipPrivilegeItem(label: "More Admin", icon: Icons.manage_accounts_rounded),
      VipPrivilegeItem(label: "Greeting Limit", icon: Icons.chat_bubble_rounded),
      VipPrivilegeItem(label: "People Following", icon: Icons.person_add_alt_1_rounded),
      VipPrivilegeItem(label: "VIP Badge", icon: Icons.military_tech_rounded),
      VipPrivilegeItem(label: "Emerald Rose Frame", icon: Icons.local_florist_rounded),
      VipPrivilegeItem(label: "Entrance Effect", icon: Icons.auto_awesome_rounded),
      VipPrivilegeItem(label: "Profile Card", icon: Icons.badge_rounded),
      VipPrivilegeItem(label: "Online User", icon: Icons.vertical_align_top_rounded),
      VipPrivilegeItem(label: "Colored Name", icon: Icons.color_lens_rounded),
      VipPrivilegeItem(label: "VIP Gift Pack", icon: Icons.redeem_rounded),
      VipPrivilegeItem(label: "Room Boost", icon: Icons.bolt_rounded),
    ],
  ),
  VipLevelSpec(
    level: 4,
    name: "VIP4",
    priceCoins: 750000,
    dailyClaimCoins: 26000,
    durationDays: 30,
    unlockedCount: 18,
    frameAssetCandidates: [
      "assets/vip_frames/assets vip_frames vip4.jpg",
      "assets/vip_frames/vip4.jpg",
      "assets/vip_frames/vip4.png",
    ],
    headerGradient: [Color(0xFFC89B54), Color(0xFF7D5D2B), Color(0xFF2E220F)],
    accentColor: Color(0xFFFDE68A),
    badgeColor: Color(0xFFF59E0B),
    privileges: [
      VipPrivilegeItem(label: "Anti-Kick out", icon: Icons.gpp_good_rounded),
      VipPrivilegeItem(label: "Customer Support", icon: Icons.support_agent_rounded),
      VipPrivilegeItem(label: "Daily Coins", icon: Icons.monetization_on_rounded),
      VipPrivilegeItem(label: "Global Entry Tag", icon: Icons.public_rounded),
      VipPrivilegeItem(label: "Global Bullet Screen", icon: Icons.campaign_rounded),
      VipPrivilegeItem(label: "Room Bullet Screen", icon: Icons.subtitles_rounded),
      VipPrivilegeItem(label: "More Admin", icon: Icons.manage_accounts_rounded),
      VipPrivilegeItem(label: "Greeting Limit", icon: Icons.chat_bubble_rounded),
      VipPrivilegeItem(label: "People Following", icon: Icons.person_add_alt_1_rounded),
      VipPrivilegeItem(label: "VIP Badge", icon: Icons.military_tech_rounded),
      VipPrivilegeItem(label: "Golden Rose Frame", icon: Icons.local_florist_rounded),
      VipPrivilegeItem(label: "Entrance Effect", icon: Icons.auto_awesome_rounded),
      VipPrivilegeItem(label: "Profile Card", icon: Icons.badge_rounded),
      VipPrivilegeItem(label: "Online User", icon: Icons.vertical_align_top_rounded),
      VipPrivilegeItem(label: "Colored Name", icon: Icons.color_lens_rounded),
      VipPrivilegeItem(label: "VIP Gift Pack", icon: Icons.redeem_rounded),
      VipPrivilegeItem(label: "Room Boost", icon: Icons.bolt_rounded),

VipPrivilegeItem(label: "Custom Bubble", icon: Icons.forum_rounded),
    ],
  ),
  VipLevelSpec(
    level: 5,
    name: "VIP5",
    priceCoins: 2400000,
    dailyClaimCoins: 83000,
    durationDays: 30,
    unlockedCount: 19,
    frameAssetCandidates: [
      "assets/vip_frames/assets vip_frames vip5.jpg",
      "assets/vip_frames/vip5.jpg",
      "assets/vip_frames/vip5.png",
    ],
    headerGradient: [Color(0xFFB83A3A), Color(0xFF6E1E1E), Color(0xFF290A0A)],
    accentColor: Color(0xFFFCA5A5),
    badgeColor: Color(0xFFEF4444),
    privileges: [
      VipPrivilegeItem(label: "Anti-Kick out", icon: Icons.gpp_good_rounded),
      VipPrivilegeItem(label: "Mystery Man", icon: Icons.masks_rounded),
      VipPrivilegeItem(label: "Customer Support", icon: Icons.support_agent_rounded),
      VipPrivilegeItem(label: "Daily Coins", icon: Icons.monetization_on_rounded),
      VipPrivilegeItem(label: "Global Entry Tag", icon: Icons.public_rounded),
      VipPrivilegeItem(label: "Global Bullet Screen", icon: Icons.campaign_rounded),
      VipPrivilegeItem(label: "Room Bullet Screen", icon: Icons.subtitles_rounded),
      VipPrivilegeItem(label: "More Admin", icon: Icons.manage_accounts_rounded),
      VipPrivilegeItem(label: "Greeting Limit", icon: Icons.chat_bubble_rounded),
      VipPrivilegeItem(label: "People Following", icon: Icons.person_add_alt_1_rounded),
      VipPrivilegeItem(label: "VIP Badge", icon: Icons.military_tech_rounded),
      VipPrivilegeItem(label: "Crimson Rose Frame", icon: Icons.local_florist_rounded),
      VipPrivilegeItem(label: "Entrance Effect", icon: Icons.auto_awesome_rounded),
      VipPrivilegeItem(label: "Profile Card", icon: Icons.badge_rounded),
      VipPrivilegeItem(label: "Online User", icon: Icons.vertical_align_top_rounded),
      VipPrivilegeItem(label: "Colored Name", icon: Icons.color_lens_rounded),
      VipPrivilegeItem(label: "VIP Gift Pack", icon: Icons.redeem_rounded),
      VipPrivilegeItem(label: "Room Boost", icon: Icons.bolt_rounded),
      VipPrivilegeItem(label: "Custom Bubble", icon: Icons.forum_rounded),
    ],
  ),
  VipLevelSpec(
    level: 6,
    name: "VIP6",
    priceCoins: 5400000,
    dailyClaimCoins: 185000,
    durationDays: 30,
    unlockedCount: 19,
    frameAssetCandidates: [
      "assets/vip_frames/assets vip_frames vip6.jpg",
      "assets/vip_frames/vip6.jpg",
      "assets/vip_frames/vip6.png",
    ],
    headerGradient: [Color(0xFF6D35A8), Color(0xFF3E1C66), Color(0xFF1A0B2E)],
    accentColor: Color(0xFFD8B4FE),
    badgeColor: Color(0xFFA855F7),
    privileges: [
      VipPrivilegeItem(label: "Anti-Kick out", icon: Icons.gpp_good_rounded),
      VipPrivilegeItem(label: "Mystery Man", icon: Icons.masks_rounded),
      VipPrivilegeItem(label: "Customer Support", icon: Icons.support_agent_rounded),
      VipPrivilegeItem(label: "Daily Coins", icon: Icons.monetization_on_rounded),
      VipPrivilegeItem(label: "Global Entry Tag", icon: Icons.public_rounded),
      VipPrivilegeItem(label: "Global Bullet Screen", icon: Icons.campaign_rounded),
      VipPrivilegeItem(label: "Room Bullet Screen", icon: Icons.subtitles_rounded),
      VipPrivilegeItem(label: "More Admin", icon: Icons.manage_accounts_rounded),
      VipPrivilegeItem(label: "Greeting Limit", icon: Icons.chat_bubble_rounded),
      VipPrivilegeItem(label: "People Following", icon: Icons.person_add_alt_1_rounded),
      VipPrivilegeItem(label: "VIP Badge", icon: Icons.military_tech_rounded),
      VipPrivilegeItem(label: "Imperial Floral Frame", icon: Icons.local_florist_rounded),
      VipPrivilegeItem(label: "Entrance Effect", icon: Icons.auto_awesome_rounded),
      VipPrivilegeItem(label: "Profile Card", icon: Icons.badge_rounded),
      VipPrivilegeItem(label: "Online User", icon: Icons.vertical_align_top_rounded),

VipPrivilegeItem(label: "Colored Name", icon: Icons.color_lens_rounded),
      VipPrivilegeItem(label: "VIP Gift Pack", icon: Icons.redeem_rounded),
      VipPrivilegeItem(label: "Room Boost", icon: Icons.bolt_rounded),
      VipPrivilegeItem(label: "Custom Bubble", icon: Icons.forum_rounded),
    ],
  ),
];

class _AssetFrameImage extends StatefulWidget {
  final List<String> candidates;
  final double width;
  final double height;
  final Widget fallback;

  const _AssetFrameImage({
    required this.candidates,
    required this.width,
    required this.height,
    required this.fallback,
  });

  @override
  State<_AssetFrameImage> createState() => _AssetFrameImageState();
}

class _AssetFrameImageState extends State<_AssetFrameImage> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _AssetFrameImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidates.join('|') != widget.candidates.join('|')) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.candidates.length) {
      return widget.fallback;
    }
    final String path = widget.candidates[_index];
    return Image.asset(
      path,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, __a) {
        if (_index + 1 < widget.candidates.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _index += 1;
              });
            }
          });
        }
        return widget.fallback;
      },
    );
  }
}

class VipAvatarFrame extends StatefulWidget {
  final Widget child;
  final int vipLevel;
  final double size;
  final bool showBadge;

  const VipAvatarFrame({
    super.key,
    required this.child,
    required this.vipLevel,
    this.size = 64,
    this.showBadge = false,
  });

  @override
  State<VipAvatarFrame> createState() => _VipAvatarFrameState();
}

class _VipAvatarFrameState extends State<VipAvatarFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  VipLevelSpec _getSpec(int lvl) {
    final int idx = (lvl - 1).clamp(0, kVipClubLevels.length - 1);
    return kVipClubLevels[idx];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vipLevel <= 0) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipOval(child: widget.child),
      );
    }

    final spec = _getSpec(widget.vipLevel);
    final double outerSize = widget.size * 1.45;
    final double avatarDiameter = widget.size * 0.84;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double t = _controller.value;
          final double angle = t * 2 * pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(outerSize, outerSize),
                painter: _VipFloralOrbitPainter(
                  progress: t,
                  primaryColor: spec.badgeColor,
                  secondaryColor: spec.accentColor,
                ),
              ),
              Container(
                width: avatarDiameter + 6,
                height: avatarDiameter + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(

transform: GradientRotation(angle),
                    colors: [
                      Colors.white,
                      spec.accentColor,
                      const Color(0xFFFACC15),
                      spec.badgeColor,
                      Colors.white,
                    ],
                  ),
                ),
              ),
              Container(
                width: avatarDiameter,
                height: avatarDiameter,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1A1A1A),
                ),
                child: ClipOval(child: widget.child),
              ),
              IgnorePointer(
                child: _AssetFrameImage(
                  candidates: spec.frameAssetCandidates,
                  width: outerSize,
                  height: outerSize,
                  fallback: const SizedBox.shrink(),
                ),
              ),
              if (widget.showBadge)
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [spec.badgeColor, spec.accentColor],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      spec.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VipFloralOrbitPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _VipFloralOrbitPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double baseRadius = size.width * 0.38;
    final double rot = progress * 2 * pi;

    final Paint orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        transform: GradientRotation(rot),
        colors: [
          Colors.transparent,
          secondaryColor,
          const Color(0xFFFACC15),
          primaryColor,
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawCircle(center, baseRadius, orbitPaint);

    const int flowerCount = 8;
    for (int i = 0; i < flowerCount; i++) {
      final double theta = rot + (i * (2 * pi / flowerCount));
      final double wave = sin(progress * 4 * pi + i) * 2.2;
      final double r = baseRadius + wave;
      final Offset pos = Offset(
        center.dx + cos(theta) * r,
        center.dy + sin(theta) * r,
      );

      final Color petalColor =
          (i % 2 == 0) ? const Color(0xFFE11D48) : secondaryColor;

      final Paint petalPaint = Paint()..color = petalColor;
      for (int p = 0; p < 5; p++) {
        final double pAngle = theta * 2 + (p * (2 * pi / 5));
        final Offset pOffset = Offset(
          pos.dx + cos(pAngle) * 2.4,
          pos.dy + sin(pAngle) * 2.4,
        );
        canvas.drawCircle(pOffset, 2.0, petalPaint);
      }

      final Paint corePaint = Paint()..color = const Color(0xFFFEF08A);
      canvas.drawCircle(pos, 1.3, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VipFloralOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

@override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  bool _isPurchasing = false;
  bool _isClaiming = false;

  String _getEatCycleKey() {
    final shifted = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 3))
        .add(const Duration(hours: 3));
    final String y = shifted.year.toString();
    final String m = shifted.month.toString().padLeft(2, '0');
    final String d = shifted.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  void _selectLevel(int newIndex) {
    if (newIndex < 0 || newIndex >= kVipClubLevels.length) return;
    setState(() {
      _selectedIndex = newIndex;
    });
  }

  Future<void> _purchaseVip({
    required VipLevelSpec spec,
    required int currentCoins,
    required int activeVipLevel,
    required Timestamp? vipExpiresAt,
  }) async {
    final user = _user;
    if (user == null) return;
    if (_isPurchasing) return;

    if (currentCoins < spec.priceCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Insufficient coins! You need ${spec.priceCoins} Coins for ${spec.name}."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final txRef =
          FirebaseFirestore.instance.collection('coin_transactions').doc();

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) return;

        final data = snap.data() ?? <String, dynamic>{};
        final int latestCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (latestCoins < spec.priceCoins) {
          throw Exception("insufficient_coins");
        }

        final now = DateTime.now();
        DateTime baseDate = now;
        if (vipExpiresAt != null) {
          final exp = vipExpiresAt.toDate();
          if (exp.isAfter(now) && activeVipLevel == spec.level) {
            baseDate = exp;
          }
        }
        final DateTime newExpiry =
            baseDate.add(Duration(days: spec.durationDays));

        tx.set(
          userRef,
          {
            'coins': FieldValue.increment(-spec.priceCoins),
            'wealthExp': FieldValue.increment(spec.priceCoins),
            'vipLevel': max(activeVipLevel, spec.level),
            'activeVipFrameLevel': spec.level,
            'vipExpiresAt': Timestamp.fromDate(newExpiry),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        tx.set(txRef, {
          'userUid': user.uid,
          'type': 'VIP_PURCHASE',
          'vipLevel': spec.level,
          'coinsSpent': spec.priceCoins,
          'durationDays': spec.durationDays,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${spec.name} Activated! Claim ${spec.dailyClaimCoins} coins daily."),
            backgroundColor: const Color(0xFF107C41),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final String msg = e.toString().contains("insufficient_coins")
            ? "Insufficient coins!"
            : "Purchase failed: $e";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _claimDailyVipCoins({
    required VipLevelSpec spec,
    required String cycleKey,
  }) async {
    final user = _user;
    if (user == null) return;
    if (_isClaiming) return;

    setState(() => _isClaiming = true);

try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final String claimField = "vipDailyClaim_${cycleKey}_v${spec.level}";

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) return;

        final data = snap.data() ?? <String, dynamic>{};
        if (data[claimField] == true) return;

        tx.set(
          userRef,
          {
            'coins': FieldValue.increment(spec.dailyClaimCoins),
            claimField: true,
          },
          SetOptions(merge: true),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "+${spec.dailyClaimCoins} Daily VIP Coins claimed to your wallet!"),
            backgroundColor: const Color(0xFF107C41),
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  void _showVipRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1917),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "VIP Club Rules",
          style: TextStyle(
              color: Color(0xFFF3D098),
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "1. Each VIP tier lasts for 30 Days from activation.\n"
              "2. Active VIP members can claim daily bonus coins every 24 hours.\n"
              "3. Activating a VIP tier unlocks its animated floral avatar frame, VIP badge, entry tag, and room privileges.",
              style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Color(0xFFF3D098))),
          ),
        ],
      ),
    );
  }

  Widget _buildVipCrestEmblem(VipLevelSpec spec) {
    return SizedBox(
      width: 72,
      height: 72,
      child: _AssetFrameImage(
        candidates: spec.frameAssetCandidates,
        width: 72,
        height: 72,
        fallback: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                spec.accentColor,
                spec.badgeColor,
              ],
            ),
            border: Border.all(color: Colors.white, width: 2.2),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _user?.uid ?? "";

    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF12100E),
        body: Center(
          child: Text("Please log in to view VIP Club",
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> userData =
            (snapshot.hasData && snapshot.data!.exists)
                ? (snapshot.data!.data() as Map<String, dynamic>? ?? {})
                : {};

final int currentCoins = (userData['coins'] as num?)?.toInt() ?? 0;
        final int activeVipLevel =
            (userData['vipLevel'] as num?)?.toInt() ?? 0;
        final Timestamp? vipExpiresAt = userData['vipExpiresAt'] as Timestamp?;
        final String displayName =
            (userData['name'] ?? userData['nickname'] ?? 'VIP Member')
                .toString();
        final String avatarUrl =
            (userData['avatarUrl'] ?? userData['photoURL'] ?? '').toString();

        final VipLevelSpec spec = kVipClubLevels[_selectedIndex];
        final bool isThisLevelActive = activeVipLevel >= spec.level &&
            vipExpiresAt != null &&
            vipExpiresAt.toDate().isAfter(DateTime.now());

        final String cycleKey = _getEatCycleKey();
        final bool dailyClaimed =
            userData["vipDailyClaim_${cycleKey}_v${spec.level}"] == true;

        String statusSubtext = "${spec.name} Not Activated";
        String cardBottomNote = "You have not purchased ${spec.name} yet";
        if (isThisLevelActive) {
          final int daysLeft =
              vipExpiresAt.toDate().difference(DateTime.now()).inDays + 1;
          statusSubtext = "${spec.name} Active ($daysLeft days left)";
          cardBottomNote =
              "You have unlocked ${spec.name} privileges & animated frame";
        }

        final String prevLabel = _selectedIndex > 0
            ? kVipClubLevels[_selectedIndex - 1].name
            : "";
        final String nextLabel = _selectedIndex < kVipClubLevels.length - 1
            ? kVipClubLevels[_selectedIndex + 1].name
            : "";

        return Scaffold(
          backgroundColor: const Color(0xFF11100E),
          body: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: spec.headerGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              "VIP Club",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.help_outline_rounded,
                                  color: Colors.white, size: 22),
                              onPressed: _showVipRulesDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 18),

padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.11),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.28),
                                width: 1.1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 12,
                                  bottom: -6,
                                  child: Text(
                                    spec.name,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.07),
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        VipAvatarFrame(
                                          vipLevel: spec.level,
                                          size: 46,
                                          child: avatarUrl.isNotEmpty
                                              ? Image.network(avatarUrl,
                                                  fit: BoxFit.cover)
                                              : Container(
                                                  color:
                                                      const Color(0xFF3E2723),
                                                  child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 26),
                                                ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                statusSubtext,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.80),

fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildVipCrestEmblem(spec),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      cardBottomNote,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.92),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_selectedIndex > 0)
                            Positioned(
                              left: 6,
                              child: GestureDetector(
                                onTap: () => _selectLevel(_selectedIndex - 1),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.black54,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          if (_selectedIndex < kVipClubLevels.length - 1)
                            Positioned(
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _selectLevel(_selectedIndex + 1),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.black54,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    color: _selectedIndex > 0
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.transparent,
                                  ),
                                ),

Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    color: _selectedIndex <
                                            kVipClubLevels.length - 1
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: GestureDetector(
                                    onTap: _selectedIndex > 0
                                        ? () =>
                                            _selectLevel(_selectedIndex - 1)
                                        : null,
                                    child: Text(
                                      prevLabel,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  spec.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: GestureDetector(
                                    onTap: _selectedIndex <
                                            kVipClubLevels.length - 1
                                        ? () =>
                                            _selectLevel(_selectedIndex + 1)
                                        : null,
                                    child: Text(
                                      nextLabel,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Expanded(

child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF11100E),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond,
                              color: Color(0xFFF3D098), size: 12),
                          const SizedBox(width: 8),
                          const Text(
                            "VIP Privileges",
                            style: TextStyle(
                              color: Color(0xFFF3D098),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.diamond,
                              color: Color(0xFFF3D098), size: 12),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "(${spec.unlockedCount}/19)",
                        style: const TextStyle(
                          color: Color(0xFFC4A878),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          itemCount: spec.privileges.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemBuilder: (context, idx) {
                            final item = spec.privileges[idx];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1E1A16),
                                    border: Border.all(
                                      color: const Color(0xFF4A3B28),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: const Color(0xFFF3C677),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(

color: Color(0xFFE7D7BE),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B1815),
                  border: Border(
                    top: BorderSide(color: Color(0xFF2E2822), width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Icon(Icons.monetization_on_rounded,
                                  color: Color(0xFFFACC15), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                "${spec.priceCoins}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                " / ${spec.durationDays}Days",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Claim ${spec.dailyClaimCoins} coins daily",
                            style: const TextStyle(
                              color: Color(0xFFD6C2A3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (isThisLevelActive && !dailyClaimed)
                        GestureDetector(
                          onTap: _isClaiming
                              ? null
                              : () => _claimDailyVipCoins(
                                    spec: spec,
                                    cycleKey: cycleKey,
                                  ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Text(

"Claim Daily",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _isPurchasing
                              ? null
                              : () => _purchaseVip(
                                    spec: spec,
                                    currentCoins: currentCoins,
                                    activeVipLevel: activeVipLevel,
                                    vipExpiresAt: vipExpiresAt,
                                  ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBE3B5), Color(0xFFE4B86B)],
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: _isPurchasing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF3E2723),
                                    ),
                                  )
                                : Text(
                                    isThisLevelActive ? "Renew" : "Purchase",
                                    style: const TextStyle(
                                      color: Color(0xFF3E2723),
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
