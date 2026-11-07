import 'package:flutter/material.dart';
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

class _AgencyScreenState extends State<AgencyScreen> with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  final TextEditingController _hostIdController = TextEditingController();
  final TextEditingController _binancePayController = TextEditingController();
  bool _isLoading = false;

  static const double _agencyCommissionRate = 0.15;
  static const int _diamondsPerUsd = 1000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostIdController.dispose();
    _binancePayController.dispose();
    super.dispose();
  }

  Future<void> _addHostToAgency(String agencyId) async {
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
            const SnackBar(content: Text("User not found with this ID"), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      final targetUserDoc = userQuery.docs.first;
      final targetData = targetUserDoc.data();

      if (targetData['agencyId'] != null && targetData['agencyId'].toString().isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This user already belongs to an agency"), backgroundColor: Colors.orangeAccent),
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      batch.update(targetUserDoc.reference, {
        'agencyId': agencyId,
        'isHost': true,
        'joinedAgencyAt': FieldValue.serverTimestamp(),
      });

      final agencyRef = FirebaseFirestore.instance.collection('agencies').doc(agencyId);
      batch.update(agencyRef, {
        'totalHosts': FieldValue.increment(1),
      });

      await batch.commit();

      _hostIdController.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Host successfully added to your agency!"), backgroundColor: Color(0xFF00C9A7)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add host: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddHostDialog(String agencyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF00E5FF), width: 1)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1, color: Color(0xFF00E5FF), size: 22),

SizedBox(width: 8),
            Text("Recruit New Host", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter Host's User Numeric ID:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _hostIdController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "e.g. 1753925",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
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
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : () => _addHostToAgency(agencyId),
            child: const Text("Add Host", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAgencyPayoutDialog(String agencyId, double availableCommissionUsd) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFF3BA2F), width: 1.2)),
        title: const Row(
          children: [
            Icon(Icons.currency_bitcoin, color: Color(0xFFF3BA2F), size: 24),
            SizedBox(width: 8),
            Text("Agency Commission Payout", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Available Commission: \$${availableCommissionUsd.toStringAsFixed(2)} USDT", style: const TextStyle(color: Color(0xFFF3BA2F), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            const Text("Binance Pay ID:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _binancePayController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Enter Binance Pay ID",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,

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
              backgroundColor: const Color(0xFFF3BA2F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final bId = _binancePayController.text.trim();
              if (bId.isEmpty) return;

              Navigator.pop(ctx);
              final txnId = "AGN_${DateTime.now().millisecondsSinceEpoch}";

              await FirebaseFirestore.instance.collection('withdrawals').doc(txnId).set({
                'txnId': txnId,
                'agencyId': agencyId,
                'userNumericId': widget.userNumericId,
                'amountUsd': availableCommissionUsd,
                'binancePayId': bId,
                'status': 'PENDING',
                'type': 'AGENCY_COMMISSION',
                'createdAt': FieldValue.serverTimestamp(),
              });

              await FirebaseFirestore.instance.collection('agencies').doc(agencyId).update({
                'unpaidCommissionDiamonds': 0,
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Commission payout request submitted!"), backgroundColor: Color(0xFF00C9A7)),
                );
              }
            },
            child: const Text("Submit Payout", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0B1E),
        body: Center(child: Text("Please login first", style: TextStyle(color: Colors.white))),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agencies')
          .where('ownerUid', isEqualTo: _currentUser!.uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0B1E),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return _buildCreateAgencyPrompt();
        }

        final agencyDoc = snapshot.data!.docs.first;
        final agencyData = agencyDoc.data() as Map<String, dynamic>;
        final agencyId = agencyDoc.id;
        final agencyName = agencyData['name'] ?? "My Agency";
        final int unpaidDiamonds = (agencyData['unpaidCommissionDiamonds'] as num?)?.toInt() ?? 0;
        final double commissionUsd = (unpaidDiamonds * _agencyCommissionRate) / _diamondsPerUsd;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0B1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF18122B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(agencyName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF00E5FF)),
                onPressed: () => _showAddHostDialog(agencyId),

),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00E5FF),
              labelColor: const Color(0xFF00E5FF),
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: "Agency Hosts"),
                Tab(text: "Commission & Stats"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildHostsListTab(agencyId),
              _buildStatsTab(agencyId, agencyData, commissionUsd),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHostsListTab(String agencyId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('agencyId', isEqualTo: agencyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
        }

        final hosts = snapshot.data!.docs;
        if (hosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_outlined, color: Colors.white24, size: 54),
                const SizedBox(height: 12),
                const Text("No hosts in your agency yet.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                  onPressed: () => _showAddHostDialog(agencyId),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Recruit Host", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: hosts.length,
          itemBuilder: (context, idx) {
            final h = hosts[idx].data() as Map<String, dynamic>;
            final name = h['name'] ?? "Host";
            final numericId = h['numericId'] ?? 0;
            final diamonds = (h['diamonds'] as num?)?.toInt() ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1638),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF281E4B),
                    ),
                    child: Center(
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : "H", style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text("ID: $numericId", style: const TextStyle(color: Colors.white54, fontSize: 11.5)),

],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Text("💎", style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text("$diamonds", style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text("Earned", style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsTab(String agencyId, Map<String, dynamic> data, double commissionUsd) {
    final int totalHosts = (data['totalHosts'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F1A3A), Color(0xFF0B3B3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Agency Net Commission (15%)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  "\$${commissionUsd.toStringAsFixed(2)} USDT",
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onPressed: commissionUsd < 10 ? null : () => _showAgencyPayoutDialog(agencyId, commissionUsd),
                    child: Text(
                      commissionUsd < 10 ? "Min. 10 USDT to Withdraw Commission" : "Withdraw Agency Profit (USDT)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Agency Performance", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCard("Active Hosts", "$totalHosts", Icons.people, const Color(0xFF00E5FF))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard("Commission Rate", "15%", Icons.percent, const Color(0xFFFFD700))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color accent) {
    return Container(

padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1638),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCreateAgencyPrompt() {
    final nameController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18122B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create Agency", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center_outlined, color: Color(0xFF00E5FF), size: 64),
            const SizedBox(height: 14),
            const Text("Register Your Agency", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("Manage hosts, track room diamond gifts, and earn 15% agency commission.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Agency Name (e.g. Star Live Agency)",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E1638),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final agencyId = "AGN_${DateTime.now().millisecondsSinceEpoch}";
                  await FirebaseFirestore.instance.collection('agencies').doc(agencyId).set({
                    'agencyId': agencyId,
                    'ownerUid': _currentUser!.uid,
                    'ownerNumericId': widget.userNumericId,
                    'name': name,
                    'commissionRate': _agencyCommissionRate,
                    'totalHosts': 0,
                    'unpaidCommissionDiamonds': 0,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                },
                child: const Text("Launch Agency", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
