import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _hostIdController = TextEditingController();
  bool _isInviting = false;

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _showInviteHostDialog(String agencyId) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Invite Host",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter Host UID to link them to your agency.",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hostIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter Host UID",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isInviting
                  ? null
                  : () async {
                      final inputHostUid = _hostIdController.text.trim();
                      if (inputHostUid.isEmpty) return;

                      setDialogState(() => _isInviting = true);

                      try {
                        final hostRef = FirebaseFirestore.instance.collection('hosts').doc(inputHostUid);
                        final hostSnap = await hostRef.get();

                        if (hostSnap.exists) {
                          await hostRef.update({
                            'agencyId': agencyId,
                            'status': 'active',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          await hostRef.set({
                            'hostUid': inputHostUid,
                            'agencyId': agencyId,
                            'status': 'active',
                            'totalDiamonds': 0,
                            'dailyDiamonds': 0,
                            'monthlyDiamonds': 0,

'liveDurationMinutesToday': 0,
                            'validDaysThisMonth': 0,
                            'newFansToday': 0,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        }

                        await FirebaseFirestore.instance.collection('agencies').doc(agencyId).update({
                          'totalHosts': FieldValue.increment(1),
                        });

                        _hostIdController.clear();
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Host added successfully!")),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to link host: $e")),
                          );
                        }
                      } finally {
                        setDialogState(() => _isInviting = false);
                      }
                    },
              child: _isInviting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettlementModal(num commissionDiamonds, double usdtValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Commission Settlement",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Available Balance: $commissionDiamonds Diamonds (≈ \$${usdtValue.toStringAsFixed(2)} USDT)",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.currency_exchange, color: Color(0xFF00C9A7)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Supported: Telebirr, CBE Bank Transfer, USDT (TRC-20)",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),

onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settlement request submitted.")),
                  );
                },
                child: const Text("Request Settlement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHostManagementModal(String hostUid, Map<String, dynamic> hostData, String agencyId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Host: ${hostUid.length > 10 ? hostUid.substring(0, 10) : hostUid}",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Status: ${hostData['status'] ?? 'active'}",
              style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              "Monthly Diamonds: ${hostData['monthlyDiamonds'] ?? 0}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              "Valid Days: ${hostData['validDaysThisMonth'] ?? 0} Days",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.85),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('hosts').doc(hostUid).update({
                    'agencyId': '',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  await FirebaseFirestore.instance.collection('agencies').doc(agencyId).update({
                    'totalHosts': FieldValue.increment(-1),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Host removed from agency.")),
                    );
                  }
                },
                child: const Text("Remove from Agency", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF141226),
        body: Center(
          child: Text("Please sign in first.", style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final String ownerUid = _currentUser!.uid;

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
          "Agency Center",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white70),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Agency link copied to share.")),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('agencies')
            .where('ownerUid', isEqualTo: ownerUid)
            .limit(1)
            .snapshots(),
        builder: (context, agencySnap) {
          if (agencySnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            );
          }

          if (!agencySnap.hasData || agencySnap.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.domain_disabled, size: 60, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      "No Agency Registered",
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "You are not registered as an agency manager.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () async {
                        final autoId = "AG_${ownerUid.substring(0, 5).toUpperCase()}";
                        await FirebaseFirestore.instance.collection('agencies').doc(autoId).set({
                          'agencyId': autoId,
                          'ownerUid': ownerUid,
                          'agencyName': "NILE Stars Agency",
                          'commissionRate': 0.10,
                          'totalHosts': 0,
                          'totalAgencyEarnings': 0,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      },
                      child: const Text("Initialize Agency", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          final agencyDoc = agencySnap.data!.docs.first;
          final agencyData = agencyDoc.data() as Map<String, dynamic>;
          final String agencyId = agencyData['agencyId'] ?? agencyDoc.id;
          final String agencyName = agencyData['agencyName'] ?? "My Agency";
          final num commissionDiamonds = agencyData['totalAgencyEarnings'] ?? 0;
          final double usdtValue = commissionDiamonds / 10000.0;

return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('hosts')
                .where('agencyId', isEqualTo: agencyId)
                .snapshots(),
            builder: (context, hostSnap) {
              final hostDocs = hostSnap.data?.docs ?? [];
              final int activeHostsCount = hostDocs.length;

              int totalGroupDiamonds = 0;
              for (var doc in hostDocs) {
                final hData = doc.data() as Map<String, dynamic>;
                totalGroupDiamonds += (hData['monthlyDiamonds'] as num? ?? 0).toInt();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Agency Overview Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C224D), Color(0xFF1E1B38)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.domain, color: Color(0xFFFFD700), size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        agencyName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      GestureDetector(
                                        onTap: () => _copyToClipboard(agencyId, "Agency ID copied!"),
                                        child: Row(
                                          children: [
                                            Text(
                                              "ID: $agencyId",
                                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.copy, size: 11, color: Colors.white54),

],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => _showSettlementModal(commissionDiamonds, usdtValue),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C9A7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    "Settlement",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildRevenueItem("Agency Commission", "${usdtValue.toStringAsFixed(2)} USDT", const Color(0xFF00C9A7)),
                              _buildRevenueItem("Total Group Diamonds", "$totalGroupDiamonds", const Color(0xFFFFD700)),
                              _buildRevenueItem("Active Hosts", "$activeHostsCount", Colors.purpleAccent),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. Agency Quick Actions
                    Row(
                      children: [
                        _buildQuickAction(Icons.person_add, "Invite Host", const Color(0xFF00C9A7), () => _showInviteHostDialog(agencyId)),
                        const SizedBox(width: 10),
                        _buildQuickAction(Icons.how_to_reg, "Requests (0)", Colors.orangeAccent, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No pending host applications.")),
                          );
                        }),
                        const SizedBox(width: 10),
                        _buildQuickAction(Icons.campaign, "Notice", Colors.blueAccent, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Agency tier incentives updated for this month.")),
                          );
                        }),
                        const SizedBox(width: 10),
                        _buildQuickAction(Icons.insights, "Analytics", Colors.pinkAccent, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Detailed analytics report will refresh at 00:00 UTC.")),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 3. Hosts Management Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [

Text(
                          "Agency Hosts List",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Filter >",
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Realtime Host List
                    if (hostDocs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B38),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Center(
                          child: Text(
                            "No hosts linked to this agency yet.\nTap 'Invite Host' to get started.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: hostDocs.length,
                        itemBuilder: (context, idx) {
                          final hostItem = hostDocs[idx];
                          final hData = hostItem.data() as Map<String, dynamic>;
                          final String hUid = hData['hostUid'] ?? hostItem.id;
                          final num liveMinutes = hData['liveDurationMinutesToday'] ?? 0;
                          final double hours = liveMinutes / 60.0;
                          final int mDiamonds = hData['monthlyDiamonds'] ?? 0;
                          final bool isActive = (hData['status'] ?? 'active') == 'active';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1B38),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Colors.white10,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.person, color: Colors.white54, size: 28),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 10,
                                        height: 10,

decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFF00C9A7) : Colors.grey,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF1E1B38), width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Host: ${hUid.length > 8 ? hUid.substring(0, 8) : hUid}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Duration: ${hours.toStringAsFixed(1)}h • Diamonds: $mDiamonds",
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showHostManagementModal(hUid, hData, agencyId),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      "Manage",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
            },
          );
        },
      ),
    );
  }

  Widget _buildRevenueItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String title, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(

padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B38),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
