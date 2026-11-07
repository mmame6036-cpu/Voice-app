import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HostEarningsScreen extends StatefulWidget {
  final int userNumericId;

  const HostEarningsScreen({
    super.key,
    required this.userNumericId,
  });

  @override
  State<HostEarningsScreen> createState() => _HostEarningsScreenState();
}

class _HostEarningsScreenState extends State<HostEarningsScreen> with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  final TextEditingController _binanceIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmitting = false;

  // 1,000 Diamonds = 1 USDT
  static const int _diamondsPerUsd = 1000;
  static const int _minWithdrawDiamonds = 10000; // 10 USDT minimum

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _binanceIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showWithdrawModal(int availableDiamonds) {
    _amountController.text = (availableDiamonds ~/ _diamondsPerUsd).toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1638),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final maxUsd = availableDiamonds ~/ _diamondsPerUsd;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Withdraw via Binance Pay", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text("Available: 💎 $availableDiamonds ($maxUsd USDT)", style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                const Text("Binance Pay ID / Pay Email", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _binanceIdController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Enter Binance Pay ID (e.g. 19283746)",
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),

),
                const SizedBox(height: 14),
                const Text("Amount (USDT)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Min. 10 USDT",
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3BA2F),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final binanceId = _binanceIdController.text.trim();
                            final enteredUsd = int.tryParse(_amountController.text.trim()) ?? 0;
                            final requiredDiamonds = enteredUsd * _diamondsPerUsd;

                            if (binanceId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter your Binance Pay ID")),
                              );
                              return;
                            }
                            if (enteredUsd < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Minimum withdrawal amount is 10 USDT")),
                              );
                              return;
                            }
                            if (requiredDiamonds > availableDiamonds) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Insufficient diamonds balance")),
                              );
                              return;
                            }

                            setModalState(() => _isSubmitting = true);
                            Navigator.pop(ctx);
                            await _processWithdrawal(binanceId, enteredUsd, requiredDiamonds);
                          },
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text("Confirm Withdrawal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _processWithdrawal(String binanceId, int amountUsd, int diamondsToDeduct) async {
    if (_currentUser == null) return;
    setState(() => _isSubmitting = true);

    final txnId = "WTH_${DateTime.now().millisecondsSinceEpoch}";
    final batch = FirebaseFirestore.instance.batch();

    try {
      // 1. የሆስቱን ዳይመንድ ባላንስ መቀነስ
      final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      batch.update(userRef, {
        'diamonds': FieldValue.increment(-diamondsToDeduct),
      });

// 2. በ withdrawals ስብስብ ውስጥ መመዝገብ
      final withdrawRef = FirebaseFirestore.instance.collection('withdrawals').doc(txnId);
      batch.set(withdrawRef, {
        'txnId': txnId,
        'userUid': _currentUser!.uid,
        'userNumericId': widget.userNumericId,
        'amountUsd': amountUsd,
        'diamonds': diamondsToDeduct,
        'binancePayId': binanceId,
        'status': 'PENDING', // PENDING, APPROVED, REJECTED
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00C9A7),
            content: Text("Withdrawal request for \$$amountUsd USDT submitted!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Withdrawal failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0B1E),
        body: Center(child: Text("Please login first", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18122B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Host Earnings & Payout", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF3BA2F),
          labelColor: const Color(0xFFF3BA2F),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "My Earnings"),
            Tab(text: "Payout History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEarningsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF3BA2F)));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final int diamonds = (data['diamonds'] as num?)?.toInt() ?? 0;
        final double estimatedUsd = diamonds / _diamondsPerUsd;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // የገቢ ባላንስ ካርድ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF281E4B), Color(0xFF130E26)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF3BA2F).withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF3BA2F).withOpacity(0.12),

blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Host Diamonds Balance", style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("ID: ${widget.userNumericId}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("💎", style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 8),
                        Text(
                          "$diamonds",
                          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "≈ \$${estimatedUsd.toStringAsFixed(2)} USDT",
                      style: const TextStyle(color: Color(0xFFF3BA2F), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3BA2F),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: diamonds < _minWithdrawDiamonds ? null : () => _showWithdrawModal(diamonds),
                        child: Text(
                          diamonds < _minWithdrawDiamonds
                              ? "Min. 10,000 💎 (10 USDT) to Withdraw"
                              : "Withdraw via Binance Pay",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // መመሪያዎች
              const Text("Payout Rules", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildRuleTile(Icons.swap_horiz, "Conversion Rate", "1,000 Diamonds = 1 USDT"),
              _buildRuleTile(Icons.timer_outlined, "Processing Time", "Transfers processed within 24-48 hours via Binance Pay"),
              _buildRuleTile(Icons.verified_user_outlined, "Direct & Safe", "0% platform tax deducted during host payout"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('withdrawals')
          .where('userUid', isEqualTo: _currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF3BA2F)));
        }

final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text("No payout requests yet.", style: TextStyle(color: Colors.white38, fontSize: 13)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, idx) {
            final item = docs[idx].data() as Map<String, dynamic>;
            final status = item['status'] ?? 'PENDING';
            final amount = item['amountUsd'] ?? 0;
            final diamonds = item['diamonds'] ?? 0;
            final binanceId = item['binancePayId'] ?? '';

            Color statusColor = const Color(0xFFF3BA2F);
            if (status == 'APPROVED') statusColor = const Color(0xFF00C9A7);
            if (status == 'REJECTED') statusColor = Colors.redAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1638),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("\$$amount USDT", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("💎 $diamonds • Binance: $binanceId", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRuleTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1638),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF3BA2F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
