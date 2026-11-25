import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  final TextEditingController _bindCodeController = TextEditingController();
  bool _isBindingCode = false;
  bool _isJoiningCampaign = false;

  static const int _perInviteReward = 2000;
  static const int _inviteeWelcomeBonus = 500;
  static const int _sprintTargetCount = 5;
  static const int _sprintBonusPoints = 5000;
  static const String _inviteBaseUrl = "https://nilevoiceapp.web.app/invite";

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color cardBg = Colors.white;
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color borderColor = Color(0xFFE2D6C5);
  static const Color buttonDark = Color(0xFF4A3528);
  static const Color successGreen = Color(0xFF107C41);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _bindCodeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _getTodayDateKey() {
    final eatNow = DateTime.now().toUtc().add(const Duration(hours: 6));
    final String y = eatNow.year.toString();
    final String m = eatNow.month.toString().padLeft(2, '0');
    final String d = eatNow.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  String _buildInviteLink(String code) {
    return "$_inviteBaseUrl?ref=$code";
  }

  String _buildShareMessage(String code) {
    final link = _buildInviteLink(code);
    return "Join me on Nile Voice! Use my Invitation Code: $code or open: $link";
  }

  void _copyText(String text, String toastMessage) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          toastMessage,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBrown,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _extractNumericCode(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.contains("ref=")) {
      final parts = trimmed.split("ref=");
      if (parts.length > 1) {
        final m = RegExp(r'\d+').firstMatch(parts[1]);
        if (m != null) {
          return m.group(0) ?? "";
        }
      }
    }
    final match = RegExp(r'\d+').firstMatch(trimmed);
    if (match != null) {
      return match.group(0) ?? "";
    }
    return trimmed;
  }

  Future<void> _submitReferralCode({
    required String myCode,
    required String existingReferredBy,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    if (_isBindingCode) return;

    if (existingReferredBy.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already linked an invitation code."),
          backgroundColor: primaryBrown,
        ),
      );
      return;
    }

    final cleanCode = _extractNumericCode(_bindCodeController.text);
    if (cleanCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid invitation code or link."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (cleanCode == myCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot use your own invitation code."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isBindingCode = true;
    });

    try {
      final int? numericTarget = int.tryParse(cleanCode);
      QuerySnapshot inviterQuery;

      if (numericTarget != null) {
        inviterQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('numericId', isEqualTo: numericTarget)
            .limit(1)
            .get();
      } else {
        inviterQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: cleanCode)
            .limit(1)
            .get();
      }

      if (inviterQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invitation code not found. Please check again."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final inviterDoc = inviterQuery.docs.first;
      final String inviterUid = inviterDoc.id;

      if (inviterUid == user.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You cannot refer yourself."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final inviterData =
          inviterDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final String inviterName =
          (inviterData['name'] ?? inviterData['nickname'] ?? 'Friend')
              .toString();

      final todayKey = _getTodayDateKey();
      final myRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final inviterRef =
          FirebaseFirestore.instance.collection('users').doc(inviterUid);
      final inviterTxRef =
          FirebaseFirestore.instance.collection('point_transactions').doc();
      final myTxRef =
          FirebaseFirestore.instance.collection('point_transactions').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final mySnap = await transaction.get(myRef);
        final inviterSnap = await transaction.get(inviterRef);

        if (!mySnap.exists) {
          throw Exception("User profile not found");
        }
        if (!inviterSnap.exists) {
          throw Exception("Inviter profile not found");
        }

        final myMap = mySnap.data() ?? <String, dynamic>{};
        final alreadyBound =
            (myMap['referredByCode'] ?? myMap['referredByUid'] ?? '')
                .toString()
                .trim();
        if (alreadyBound.isNotEmpty) {
          throw Exception("already_bound");
        }

        final String myName =
            (myMap['name'] ?? myMap['nickname'] ?? 'User').toString();

        // Update invitee (current user) with referrer & welcome bonus
        transaction.set(
          myRef,
          {
            'referredByUid': inviterUid,
            'referredByCode': cleanCode,
            'referredByName': inviterName,
            'referredAt': FieldValue.serverTimestamp(),
            'points': FieldValue.increment(_inviteeWelcomeBonus),
            'charmExp': FieldValue.increment(_inviteeWelcomeBonus),
            'todayTaskPoints': FieldValue.increment(_inviteeWelcomeBonus),
            'weekTaskPoints': FieldValue.increment(_inviteeWelcomeBonus),
            'lastTaskDate': todayKey,
          },
          SetOptions(merge: true),
        );

        // Credit inviter with +2,000 Points
        transaction.set(
          inviterRef,
          {
            'points': FieldValue.increment(_perInviteReward),
            'charmExp': FieldValue.increment(_perInviteReward),
            'todayTaskPoints': FieldValue.increment(_perInviteReward),
            'weekTaskPoints': FieldValue.increment(_perInviteReward),
            'referralCount': FieldValue.increment(1),
            'referralPointsEarned': FieldValue.increment(_perInviteReward),
            'lastTaskDate': todayKey,
          },
          SetOptions(merge: true),
        );

        // Transaction logs for both users
        transaction.set(inviterTxRef, {
          'userUid': inviterUid,
          'senderUid': user.uid,
          'type': 'REFERRAL_REWARD',
          'taskTitle': "Invited Friend ($myName)",
          'points': _perInviteReward,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.set(myTxRef, {
          'userUid': user.uid,
          'senderUid': inviterUid,
          'type': 'REFERRAL_WELCOME_BONUS',
          'taskTitle': "Used Invite Code ($cleanCode)",
          'points': _inviteeWelcomeBonus,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      _bindCodeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Code linked to $inviterName! You earned +$_inviteeWelcomeBonus Pts and they earned +$_perInviteReward Pts!",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().contains("already_bound")
          ? "You have already linked an invitation code."
          : "Could not link code: $e";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(color: Colors.white)),
            backgroundColor: primaryBrown,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBindingCode = false;
        });
      }
    }
  }

  void _showShareDialog(String code) {
    final String inviteLink = _buildInviteLink(code);
    final String shareMsg = _buildShareMessage(code);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
            const SizedBox(height: 16),
            const Text(
              "Invite Friends & Earn Points",
              style: TextStyle(
                color: primaryBrown,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Share your invitation code or link. Earn +2,000 Points for every friend who signs up and enters your code!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "My Invitation Code",
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      Text(
                        code,
                        style: const TextStyle(
                          color: primaryBrown,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _copyText(code, "Invitation code ($code) copied!");
                    },
                    child: const Text(
                      "Copy Code",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Invitation Link",
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          inviteLink,
                          style: const TextStyle(
                            color: successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _copyText(
                        shareMsg,
                        "Invitation link & message copied! Paste to share.",
                      );
                    },
                    child: const Text(
                      "Copy Link",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCampaignAction({
    required String campaignTitle,
    required bool isEnrolled,
    required int invitedCount,
    required bool isBonusClaimed,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    if (_isJoiningCampaign) return;

    setState(() {
      _isJoiningCampaign = true;
    });

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      if (!isEnrolled) {
        await userRef.set({
          'enrolledCampaigns': FieldValue.arrayUnion([campaignTitle]),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Joined sprint! Invite 5 friends using your code to unlock +5,000 Bonus Points.",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: primaryBrown,
            ),
          );
        }
        return;
      }

      if (invitedCount < _sprintTargetCount) {
        if (mounted) {
          final remaining = _sprintTargetCount - invitedCount;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Invite $remaining more friend(s) to claim the +$_sprintBonusPoints Pts Sprint Bonus!",
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: primaryBrown,
            ),
          );
        }
        return;
      }

      if (isBonusClaimed) return;

      final todayKey = _getTodayDateKey();
      final txRef =
          FirebaseFirestore.instance.collection('point_transactions').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(userRef);
        final claimedList = (snap.data()?['claimedCampaigns'] as List?) ?? [];
        if (claimedList.contains(campaignTitle)) {
          throw Exception("already_claimed");
        }

        transaction.set(
          userRef,
          {
            'points': FieldValue.increment(_sprintBonusPoints),
            'charmExp': FieldValue.increment(_sprintBonusPoints),
            'todayTaskPoints': FieldValue.increment(_sprintBonusPoints),
            'weekTaskPoints': FieldValue.increment(_sprintBonusPoints),
            'lastTaskDate': todayKey,
            'claimedCampaigns': FieldValue.arrayUnion([campaignTitle]),
          },
          SetOptions(merge: true),
        );

        transaction.set(txRef, {
          'userUid': user.uid,
          'senderUid': 'SYSTEM_CAMPAIGN',
          'type': 'CAMPAIGN_BONUS',
          'taskTitle': "$campaignTitle (5 Friends Milestone)",
          'points': _sprintBonusPoints,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Sprint Milestone Complete! +5,000 Bonus Points added to your wallet!",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Action failed: $e",
                style: const TextStyle(color: Colors.white)),
            backgroundColor: primaryBrown,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningCampaign = false;
        });
      }
    }
  }

  Future<void> _toggleFestivalReminder(
      String festivalName, bool currentlySet) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      if (currentlySet) {
        await userRef.set({
          'campaignReminders': FieldValue.arrayRemove([festivalName]),
        }, SetOptions(merge: true));
      } else {
        await userRef.set({
          'campaignReminders': FieldValue.arrayUnion([festivalName]),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlySet
                  ? "Reminder removed for $festivalName"
                  : "Reminder saved for $festivalName ✓",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: currentlySet ? primaryBrown : successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
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
          "Invitation Center",
          style: TextStyle(
            color: primaryBrown,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBrown,
          unselectedLabelColor: Colors.black45,
          indicatorColor: accentGold,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: "In Progress"),
            Tab(text: "Upcoming"),
            Tab(text: "Ended"),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          final userData = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final String myCode =
              (userData['numericId'] ?? userData['id'] ?? "100001").toString();
          final String referredByCode =
              (userData['referredByCode'] ?? '').toString().trim();
          final String referredByName =
              (userData['referredByName'] ?? '').toString().trim();
          final List enrolledList =
              (userData['enrolledCampaigns'] as List?) ?? [];
          final List claimedList =
              (userData['claimedCampaigns'] as List?) ?? [];
          final List reminderList =
              (userData['campaignReminders'] as List?) ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: uid.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('users')
                    .where('referredByUid', isEqualTo: uid)
                    .snapshots()
                : null,
            builder: (context, referralsSnap) {
              final List<QueryDocumentSnapshot> invitedDocs =
                  referralsSnap.hasData ? referralsSnap.data!.docs : [];
              final int invitedCount = invitedDocs.length;
              final int totalReferralPoints = invitedCount * _perInviteReward;

              return Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInProgressTab(
                          myCode: myCode,
                          referredByCode: referredByCode,
                          referredByName: referredByName,
                          enrolledList: enrolledList,
                          claimedList: claimedList,
                          invitedDocs: invitedDocs,
                          invitedCount: invitedCount,
                          totalReferralPoints: totalReferralPoints,
                        ),
                        _buildUpcomingTab(reminderList: reminderList),
                        _buildEndedTab(),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: cardBg,
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF4E6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Invitation Code:",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: primaryBrown,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  myCode,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: accentGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _copyText(
                                      myCode, "Invitation code copied!"),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: buttonDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Copy",
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
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: successGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => _showShareDialog(myCode),
                              child: const Text(
                                "Share Invitation",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInProgressTab({
    required String myCode,
    required String referredByCode,
    required String referredByName,
    required List enrolledList,
    required List claimedList,
    required List<QueryDocumentSnapshot> invitedDocs,
    required int invitedCount,
    required int totalReferralPoints,
  }) {
    const String campaignName = "New Host Referral Sprint";
    final bool isEnrolled = enrolledList.contains(campaignName);
    final bool isSprintClaimed = claimedList.contains(campaignName);
    final bool isSprintReady = invitedCount >= _sprintTargetCount;

    String sprintBtnLabel = "Join Sprint";
    Color sprintBtnColor = buttonDark;
    VoidCallback? sprintAction = () => _handleCampaignAction(
          campaignTitle: campaignName,
          isEnrolled: isEnrolled,
          invitedCount: invitedCount,
          isBonusClaimed: isSprintClaimed,
        );

    if (isSprintClaimed) {
      sprintBtnLabel = "Bonus Claimed ✓";
      sprintBtnColor = Colors.black26;
      sprintAction = null;
    } else if (isEnrolled && isSprintReady) {
      sprintBtnLabel = "Claim +5,000 Pts Bonus";
      sprintBtnColor = successGreen;
    } else if (isEnrolled) {
      sprintBtnLabel =
          "In Progress ($invitedCount / $_sprintTargetCount Invited)";
      sprintBtnColor = const Color(0xFF6D5446);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. MY REFERRAL SUMMARY STATS CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A3528), Color(0xFF3E2723)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.groups_rounded, color: accentGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "My Referral Earnings (+2,000 Pts / Friend)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Invited Friends",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$invitedCount",
                              style: const TextStyle(
                                color: accentGold,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Earned Points",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$totalReferralPoints Pts",
                              style: const TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. ENTER INVITATION CODE CARD (FOR NEW USERS)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: referredByCode.isNotEmpty
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: successGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Referral Code Linked ✓",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryBrown,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              referredByName.isNotEmpty
                                  ? "Invited by $referredByName (Code: $referredByCode)"
                                  : "Invited by Code: $referredByCode",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Enter Friend's Invitation Code",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Enter the code or link shared by your friend to get +500 Welcome Points (and grant them +2,000 Points).",
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _bindCodeController,
                              decoration: InputDecoration(
                                hintText: "Enter code (e.g. 100083)",
                                hintStyle: const TextStyle(fontSize: 12.5),
                                filled: true,
                                fillColor: bgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: borderColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: successGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isBindingCode
                                  ? null
                                  : () => _submitReferralCode(
                                        myCode: myCode,
                                        existingReferredBy: referredByCode,
                                      ),
                              child: _isBindingCode
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Claim",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 14),

          // 3. CAMPAIGN SPRINT CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      campaignName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryBrown,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Active",
                        style: TextStyle(
                          color: successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Invite 5 friends using your code to unlock an extra +5,000 Points milestone bonus!",
                  style: TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (invitedCount / _sprintTargetCount).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: bgColor,
                    color: successGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progress: ${invitedCount.clamp(0, _sprintTargetCount)} / $_sprintTargetCount Friends",
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: primaryBrown),
                    ),
                    const Text(
                      "+5,000 Pts Bonus",
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: accentGold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sprintBtnColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: sprintAction,
                    child: Text(
                      sprintBtnLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. MY INVITED FRIENDS LIST
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "My Invited Friends ($invitedCount)",
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: primaryBrown,
                  ),
                ),
                const SizedBox(height: 10),
                if (invitedDocs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        "No friends invited yet. Share your code below to start earning!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invitedDocs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: borderColor),
                    itemBuilder: (_, idx) {
                      final fData = invitedDocs[idx].data()
                              as Map<String, dynamic>? ??
                          <String, dynamic>{};
                      final String fName =
                          (fData['name'] ?? fData['nickname'] ?? 'User')
                              .toString();
                      final String fNumId =
                          (fData['numericId'] ?? fData['id'] ?? '')
                              .toString();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: bgColor,
                          child: Text(
                            fName.isNotEmpty ? fName[0].toUpperCase() : "U",
                            style: const TextStyle(
                              color: primaryBrown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          fName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: primaryBrown,
                          ),
                        ),
                        subtitle: Text(
                          fNumId.isNotEmpty ? "ID: $fNumId" : "Registered Member",
                          style: const TextStyle(
                              fontSize: 11.5, color: Colors.black54),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "+2,000 Pts",
                            style: TextStyle(
                              color: successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab({required List reminderList}) {
    const String festivalTitle = "Golden Star Gifting Festival";
    final bool isReminderSet = reminderList.contains(festivalTitle);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  festivalTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryBrown,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Coming Soon",
                    style: TextStyle(
                      color: accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Starts next Monday: Extra 10% cash rebate on lucky gifts",
              style: TextStyle(fontSize: 11.5, color: Colors.black45),
            ),
            const SizedBox(height: 14),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFFBF4E6),
                border: Border.all(color: borderColor),
              ),
              child: const Center(
                child: Icon(Icons.stars, color: accentGold, size: 44),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReminderSet ? successGreen : cardBg,
                  side: BorderSide(
                      color: isReminderSet ? successGreen : borderColor),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () =>
                    _toggleFestivalReminder(festivalTitle, isReminderSet),
                child: Text(
                  isReminderSet ? "Reminder Set ✓" : "Set Reminder",
                  style: TextStyle(
                    color: isReminderSet ? Colors.white : primaryBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndedTab() {
    return const Center(
      child: Text(
        "No expired campaigns at this time.",
        style: TextStyle(color: Colors.black45, fontSize: 13),
      ),
    );
  }
}
