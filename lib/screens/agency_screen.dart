import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgencyScreen extends StatefulWidget {
  final int userNumericId;

  const AgencyScreen({
    super.key,
    this.userNumericId = 0,
  });

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _hostIdController = TextEditingController();
  final TextEditingController _payoutAccountController = TextEditingController();
  bool _isLoading = false;
  bool _isCreatingAgency = false;
  String _selectedPayoutMethod = "Binance Pay (USDT)";

  static const double _agencyCommissionRate = 0.15;
  static const int _pointsPerUsd = 10000;

  static const Color shiroBg = Color(0xFFF7F4EB);
  static const Color shiroCard = Color(0xFFEFE9DA);
  static const Color whiteCard = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF5C564D);
  static const Color accentBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color accentGreen = Color(0xFF107C41);
  static const Color borderShiro = Color(0xFFDDD4C2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _agencyNameController.dispose();
    _hostIdController.dispose();
    _payoutAccountController.dispose();
    super.dispose();
  }

  void _copyAgencyId(String agencyId) {
    Clipboard.setData(ClipboardData(text: agencyId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Agency ID $agencyId copied to clipboard")),
    );
  }

  Future<void> _addHostToAgency(String agencyId, String agencyName) async {
    final enteredId = int.tryParse(_hostIdController.text.trim());
    if (enteredId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid Numeric User ID")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('numericId', isEqualTo: enteredId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("User not found with this ID"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final targetUserDoc = userQuery.docs.first;
      final targetData = targetUserDoc.data();

      String existingAgency = "";
      if (targetData['agencyId'] != null) {
        existingAgency = targetData['agencyId'].toString();
      }

      if (existingAgency.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This user already belongs to an agency"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      batch.update(targetUserDoc.reference, {
        'agencyId': agencyId,
        'agencyName': agencyName,
        'isHost': true,
        'joinedAgencyAt': FieldValue.serverTimestamp(),
      });

      final hostRef =
          FirebaseFirestore.instance.collection('hosts').doc(targetUserDoc.id);

batch.set(
        hostRef,
        {
          'agencyId': agencyId,
          'agencyName': agencyName,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final agencyRef =
          FirebaseFirestore.instance.collection('agencies').doc(agencyId);
      batch.update(agencyRef, {
        'totalHosts': FieldValue.increment(1),
      });

      await batch.commit();

      _hostIdController.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Host successfully added to your agency!"),
            backgroundColor: accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add host: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeHostFromAgency(
      String agencyId, String hostUid, String hostName) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(hostUid);
      final hostRef =
          FirebaseFirestore.instance.collection('hosts').doc(hostUid);
      final agencyRef =
          FirebaseFirestore.instance.collection('agencies').doc(agencyId);

      batch.update(userRef, {
        'agencyId': '',
        'agencyName': '',
        'isHost': false,
      });

      batch.set(
        hostRef,
        {
          'agencyId': '',
          'agencyName': '',
          'status': 'removed',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.update(agencyRef, {
        'totalHosts': FieldValue.increment(-1),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$hostName removed from agency")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error removing host: $e")),
        );
      }
    }
  }

  void _showAddHostDialog(String agencyId, String agencyName) {
    showDialog(
      context: context,
      builder: (ctx) {
        VoidCallback? addAction = () => _addHostToAgency(agencyId, agencyName);
        if (_isLoading) {
          addAction = null;
        }

        return AlertDialog(
          backgroundColor: shiroBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: borderShiro, width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: accentBrown, size: 22),
              SizedBox(width: 8),
              Text(
                "Recruit New Host",
                style: TextStyle(
                  color: textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter Host's User Numeric ID:",
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(

color: whiteCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderShiro),
                ),
                child: TextField(
                  controller: _hostIdController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: textBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: "e.g. 100058",
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: addAction,
              child: const Text(
                "Add Host",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAgencyPayoutDialog({
    required String agencyId,
    required String agencyName,
    required int availableCommissionPoints,
    required double availableCommissionUsd,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          String accountHint = "Enter Binance Pay ID";
          if (_selectedPayoutMethod == "Telebirr") {
            accountHint = "Enter Telebirr Phone (+251...)";
          } else if (_selectedPayoutMethod == "CBE Bank") {
            accountHint = "Enter CBE Account (1000...)";
          }

          return AlertDialog(
            backgroundColor: shiroBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: borderShiro, width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: accentGold, size: 24),
                SizedBox(width: 8),
                Text(
                  "Agency Profit Payout",
                  style: TextStyle(
                    color: textBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Available: \$${availableCommissionUsd.toStringAsFixed(2)} USD ($availableCommissionPoints Pts)",
                  style: const TextStyle(
                    color: accentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Select Payment Method:",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [

"Binance Pay (USDT)",
                    "Telebirr",
                    "CBE Bank",
                  ].map((method) {
                    final bool isSelected = _selectedPayoutMethod == method;
                    Color chipBg = whiteCard;
                    Color chipText = textBlack;
                    if (isSelected) {
                      chipBg = accentBrown;
                      chipText = Colors.white;
                    }
                    return ChoiceChip(
                      label: Text(method),
                      selected: isSelected,
                      selectedColor: accentBrown,
                      backgroundColor: chipBg,
                      labelStyle: TextStyle(
                        color: chipText,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        setDialogState(() => _selectedPayoutMethod = method);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Account Details:",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: whiteCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderShiro),
                  ),
                  child: TextField(
                    controller: _payoutAccountController,
                    style: const TextStyle(
                      color: textBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: accountHint,
                      hintStyle:
                          const TextStyle(color: Colors.black38, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final accountVal = _payoutAccountController.text.trim();
                  if (accountVal.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please enter account details")),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  String currencyCode = "USDT";
                  if (_selectedPayoutMethod != "Binance Pay (USDT)") {
                    currencyCode = "ETB";
                  }

                  final batch = FirebaseFirestore.instance.batch();
                  final requestRef = FirebaseFirestore.instance
                      .collection('withdraw_requests')
                      .doc();

                  batch.set(requestRef, {

'requestId': requestRef.id,
                    'userUid': _currentUser!.uid,
                    'uid': _currentUser!.uid,
                    'userNumericId': widget.userNumericId,
                    'userName': "$agencyName (Agency)",
                    'agencyId': agencyId,
                    'points': availableCommissionPoints,
                    'usdAmount': availableCommissionUsd,
                    'method': _selectedPayoutMethod,
                    'currency': currencyCode,
                    'account': accountVal,
                    'accountDetails': accountVal,
                    'type': 'AGENCY_COMMISSION',
                    'status': 'PENDING',
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  final agencyRef = FirebaseFirestore.instance
                      .collection('agencies')
                      .doc(agencyId);
                  batch.update(agencyRef, {
                    'withdrawnCommissionPoints':
                        FieldValue.increment(availableCommissionPoints),
                  });

                  await batch.commit();
                  _payoutAccountController.clear();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Agency payout request submitted for review!"),
                        backgroundColor: accentGreen,
                      ),
                    );
                  }
                },
                child: const Text(
                  "Submit Payout",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: shiroBg,
        body: Center(
          child: Text("Please login first", style: TextStyle(color: textBlack)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agencies')
          .where('ownerUid', isEqualTo: user.uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: shiroBg,
            body: Center(
              child: CircularProgressIndicator(color: accentBrown),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return _buildCreateAgencyPrompt();
        }

        final agencyDoc = snapshot.data!.docs.first;
        final rawAgency = agencyDoc.data();
        final Map<String, dynamic> agencyData =
            rawAgency is Map<String, dynamic> ? rawAgency : {};
        final agencyId = agencyDoc.id;

        String agencyName = "My Agency";
        if (agencyData['name'] != null) {
          agencyName = agencyData['name'].toString();
        }

        final int withdrawnPoints =
            (agencyData['withdrawnCommissionPoints'] as num?)?.toInt() ?? 0;
        final int bonusCommissionPoints =
            (agencyData['bonusCommissionPoints'] as num?)?.toInt() ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('agencyId', isEqualTo: agencyId)
              .snapshots(),
          builder: (context, hostsSnap) {
            List hostsList = [];
            if (hostsSnap.hasData) {
              hostsList = hostsSnap.data!.docs;
            }

            int totalHostPoints = 0;
            for (var doc in hostsList) {

final rawH = doc.data();
              final Map<String, dynamic> hData =
                  rawH is Map<String, dynamic> ? rawH : {};
              int pts = (hData['points'] as num?)?.toInt() ?? 0;
              if (pts == 0) {
                pts = (hData['diamonds'] as num?)?.toInt() ?? 0;
              }
              totalHostPoints += pts;
            }

            final int grossCommissionPoints =
                (totalHostPoints * _agencyCommissionRate).round() +
                    bonusCommissionPoints;
            int availableCommissionPoints =
                grossCommissionPoints - withdrawnPoints;
            if (availableCommissionPoints < 0) {
              availableCommissionPoints = 0;
            }

            final double commissionUsd =
                availableCommissionPoints / _pointsPerUsd;

            return Scaffold(
              backgroundColor: shiroBg,
              appBar: AppBar(
                backgroundColor: shiroCard,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: textBlack, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  agencyName,
                  style: const TextStyle(
                    color: textBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon:
                        const Icon(Icons.person_add_alt_1, color: accentBrown),
                    tooltip: "Recruit Host",
                    onPressed: () => _showAddHostDialog(agencyId, agencyName),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: accentBrown,
                  indicatorWeight: 3,
                  labelColor: textBlack,
                  unselectedLabelColor: textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "Agency Hosts"),
                    Tab(text: "Commission & Stats"),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildHostsListTab(agencyId, agencyName, hostsList),
                  _buildStatsTab(
                    agencyId: agencyId,
                    agencyName: agencyName,
                    activeHostsCount: hostsList.length,
                    totalHostPoints: totalHostPoints,
                    availableCommissionPoints: availableCommissionPoints,
                    commissionUsd: commissionUsd,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHostsListTab(
      String agencyId, String agencyName, List hosts) {
    if (hosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups_outlined, color: textMuted, size: 54),
              const SizedBox(height: 12),
              const Text(
                "No hosts in your agency yet.",
                style: TextStyle(
                  color: textBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Share Agency ID: $agencyId or tap Recruit Host below.",

textAlign: TextAlign.center,
                style: const TextStyle(color: textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBrown,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showAddHostDialog(agencyId, agencyName),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "Recruit Host",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: hosts.length,
      itemBuilder: (context, idx) {
        final doc = hosts[idx];
        final rawH = doc.data();
        final Map<String, dynamic> h =
            rawH is Map<String, dynamic> ? rawH : {};

        String name = "Host";
        if (h['name'] != null) {
          name = h['name'].toString();
        }
        final int numericId = (h['numericId'] as num?)?.toInt() ?? 0;
        int points = (h['points'] as num?)?.toInt() ?? 0;
        if (points == 0) {
          points = (h['diamonds'] as num?)?.toInt() ?? 0;
        }
        final int micMins = (h['todayMicMinutes'] as num?)?.toInt() ?? 0;

        String initialChar = "H";
        if (name.isNotEmpty) {
          initialChar = name[0].toUpperCase();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: whiteCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderShiro),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: shiroCard,
                ),
                child: Center(
                  child: Text(
                    initialChar,
                    style: const TextStyle(
                      color: textBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: textBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "ID: $numericId • Mic Today: $micMins mins",
                      style: const TextStyle(color: textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          size: 15, color: accentGold),
                      const SizedBox(width: 4),

Text(
                        "$points",
                        style: const TextStyle(
                          color: textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Host Points",
                    style: TextStyle(color: textMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.redAccent, size: 20),
                tooltip: "Remove Host",
                onPressed: () =>
                    _removeHostFromAgency(agencyId, doc.id, name),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab({
    required String agencyId,
    required String agencyName,
    required int activeHostsCount,
    required int totalHostPoints,
    required int availableCommissionPoints,
    required double commissionUsd,
  }) {
    final bool canWithdraw = commissionUsd >= 10.0;
    VoidCallback? withdrawAction;
    String withdrawBtnText = "Min. \$10 USD to Withdraw";
    Color withdrawBtnColor = Colors.black26;

    if (canWithdraw) {
      withdrawBtnText = "Withdraw Agency Profit";
      withdrawBtnColor = accentGreen;
      withdrawAction = () => _showAgencyPayoutDialog(
            agencyId: agencyId,
            agencyName: agencyName,
            availableCommissionPoints: availableCommissionPoints,
            availableCommissionUsd: commissionUsd,
          );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agency ID Copy Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: whiteCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderShiro),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Agency Invite ID (Share with Hosts)",
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      agencyId,
                      style: const TextStyle(
                        color: textBlack,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shiroCard,
                    foregroundColor: textBlack,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _copyAgencyId(agencyId),
                  icon: const Icon(Icons.copy, size: 15, color: textBlack),
                  label: const Text(
                    "Copy",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

// Commission Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: shiroCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderShiro),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Agency Net Commission (15%)",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${commissionUsd.toStringAsFixed(2)} USD",
                  style: const TextStyle(
                    color: textBlack,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Available Commission Points: $availableCommissionPoints Pts (10,000 Pts = \$1)",
                  style: const TextStyle(color: textMuted, fontSize: 11),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: withdrawBtnColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    onPressed: withdrawAction,
                    child: Text(
                      withdrawBtnText,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "Agency Performance",
            style: TextStyle(
              color: textBlack,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Active Hosts",
                  "$activeHostsCount",
                  Icons.people,
                  accentBrown,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  "Total Host Points",
                  "$totalHostPoints",
                  Icons.stars_rounded,
                  accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: whiteCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderShiro),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Agency Policy Summary",
                  style: TextStyle(
                    color: textBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(

"• Agency earns 15% commission on all host gift points.\n"
                  "• Conversion rate: 10,000 Points = \$1.00 USD.\n"
                  "• Minimum agency payout threshold is \$10.00 USD.",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: whiteCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderShiro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: textBlack,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCreateAgencyPrompt() {
    VoidCallback? createAction = () async {
      final name = _agencyNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter an agency name")),
        );
        return;
      }

      setState(() => _isCreatingAgency = true);
      try {
        final agencyId = "AG_${DateTime.now().millisecondsSinceEpoch % 1000000}";
        await FirebaseFirestore.instance
            .collection('agencies')
            .doc(agencyId)
            .set({
          'agencyId': agencyId,
          'ownerUid': _currentUser!.uid,
          'ownerNumericId': widget.userNumericId,
          'name': name,
          'commissionRate': _agencyCommissionRate,
          'totalHosts': 0,
          'withdrawnCommissionPoints': 0,
          'bonusCommissionPoints': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to create agency: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isCreatingAgency = false);
      }
    };

    Widget createChild = const Text(
      "Launch Agency",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );

    if (_isCreatingAgency) {
      createAction = null;
      createChild = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return Scaffold(
      backgroundColor: shiroBg,
      appBar: AppBar(
        backgroundColor: shiroCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textBlack, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Agency",
          style: TextStyle(
            color: textBlack,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center_outlined,
                color: accentBrown, size: 64),

const SizedBox(height: 14),
            const Text(
              "Register Your Agency",
              style: TextStyle(
                color: textBlack,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Manage hosts, track room gift points, and earn 15% agency commission.",
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _agencyNameController,
              style: const TextStyle(
                color: textBlack,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: "Agency Name (e.g. Nile Star Agency)",
                hintStyle:
                    const TextStyle(color: Colors.black38, fontSize: 13),
                filled: true,
                fillColor: whiteCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: borderShiro),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: borderShiro),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBrown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: createAction,
                child: createChild,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
