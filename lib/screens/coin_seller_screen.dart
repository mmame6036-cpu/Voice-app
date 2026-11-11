import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoinSellerScreen extends StatefulWidget {
  const CoinSellerScreen({super.key});

  @override
  State<CoinSellerScreen> createState() => _CoinSellerScreenState();
}

class _CoinSellerScreenState extends State<CoinSellerScreen>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  int _salesMethodIndex = 0; // 0: User, 1: Coinseller
  int _rechargeSubTabIndex = 0; // 0: Official, 1: Coin Seller
  int _selectedPaymentMethod = 0; // 0: Telebirr, 1: Binance Pay
  int _selectedRechargePackage = 0;

  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _coinAmountController = TextEditingController();
  final TextEditingController _customExchangeController = TextEditingController();
  final TextEditingController _greetingController = TextEditingController();

  bool _isProcessing = false;
  String _verifiedReceiverName = "";

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color cardBg = Colors.white;
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color borderColor = Color(0xFFE2D6C5);
  static const Color buttonDark = Color(0xFF4A3528);

  final List> _rechargePackages = const [
    {"coins": 1980000, "price": "\$200", "tier": "Standard Seller"},
    {"coins": 9900000, "price": "\$1,000", "tier": "Standard Seller"},
    {"coins": 14850000, "price": "\$1,500", "tier": "Senior Seller"},
    {"coins": 30000000, "price": "\$3,000", "tier": "Senior Seller"},
  ];

  final List> _exchangePacks = const [
    {"coins": 960000, "points": 1000000},
    {"coins": 1960000, "points": 2000000},
    {"coins": 9800000, "points": 10000000},
    {"coins": 14700000, "points": 15000000},
    {"coins": 30000000, "points": 30000000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receiverIdController.dispose();
    _coinAmountController.dispose();
    _customExchangeController.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast("Copied ID: $text");
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

  Future<void> _verifyReceiver() async {
    final queryText = _receiverIdController.text.trim();
    if (queryText.isEmpty) return;

    setState(() => _verifiedReceiverName = "Searching...");

    try {
      final int? numId = int.tryParse(queryText);
      QuerySnapshot query;
      if (numId != null) {
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('numericId', isEqualTo: numId)
            .limit(1)
            .get();
      } else {
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: queryText)
            .limit(1)
            .get();
      }

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _verifiedReceiverName = data['name'] ?? data['displayName'] ?? "Verified User";
        });
      } else {
        setState(() => _verifiedReceiverName = "User Not Found");
      }
    } catch (_) {
      setState(() => _verifiedReceiverName = "Verification Failed");
    }
  }

Future<void> _executeCoinTransfer(int sellerBalance) async {
    final targetInput = _receiverIdController.text.trim();
    final amountInput = int.tryParse(_coinAmountController.text.trim()) ?? 0;

    if (targetInput.isEmpty || amountInput <= 0) {
      _showToast("Please enter a valid receiver ID and coin amount.");
      return;
    }

    if (amountInput % 1000 != 0) {
      _showToast("Coin amount must be a multiple of 1,000.");
      return;
    }

    if (amountInput > sellerBalance) {
      _showToast("Insufficient coin balance.");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final int? numId = int.tryParse(targetInput);
      QuerySnapshot query;
      if (numId != null) {
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('numericId', isEqualTo: numId)
            .limit(1)
            .get();
      } else {
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: targetInput)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
        _showToast("Target receiver account does not exist.");
        setState(() => _isProcessing = false);
        return;
      }

      final receiverDoc = query.docs.first;
      final receiverRef = receiverDoc.reference;
      final sellerRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final sellerSnap = await transaction.get(sellerRef);
        final currentCoins = (sellerSnap.data() as Map<String, dynamic>)['coins'] ?? 0;

        if (currentCoins < amountInput) {
          throw Exception("Insufficient balance.");
        }

        transaction.update(sellerRef, {'coins': FieldValue.increment(-amountInput)});
        transaction.update(receiverRef, {'coins': FieldValue.increment(amountInput)});

        final logRef = FirebaseFirestore.instance.collection('coin_transfers').doc();
        transaction.set(logRef, {
          'sellerUid': _currentUser!.uid,
          'receiverUid': receiverDoc.id,
          'receiverId': targetInput,
          'salesMethod': _salesMethodIndex == 0 ? "User" : "Coinseller",
          'coins': amountInput,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      _receiverIdController.clear();
      _coinAmountController.clear();
      setState(() => _verifiedReceiverName = "");
      _showToast("Successfully transferred $amountInput Coins!");
    } catch (e) {
      _showToast("Transfer failed: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _executePointsExchange(int userPoints, int pointsCost, int coinsGain) async {
    if (pointsCost <= 0 || coinsGain <= 0) return;

    if (userPoints < pointsCost) {
      _showToast("Insufficient points balance.");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(userRef);
        final currentPts = (snap.data() as Map<String, dynamic>)['points'] ?? 0;

        if (currentPts < pointsCost) {
          throw Exception("Insufficient points.");
        }

        transaction.update(userRef, {
          'points': FieldValue.increment(-pointsCost),
          'coins': FieldValue.increment(coinsGain),
        });

        final logRef = FirebaseFirestore.instance.collection('point_exchanges').doc();
        transaction.set(logRef, {
          'uid': _currentUser!.uid,
          'pointsDeducted': pointsCost,
          'coinsAdded': coinsGain,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

_customExchangeController.clear();
      _showToast("Exchanged $pointsCost Points for $coinsGain Coins!");
    } catch (e) {
      _showToast("Exchange failed: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showHistoryModal(String title, String collectionName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(collectionName)
                    .where(
                      collectionName == 'coin_transfers' ? 'sellerUid' : 'uid',
                      isEqualTo: _currentUser?.uid,
                    )
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No history records found.",
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, idx) {
                      final item = snapshot.data!.docs[idx].data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['salesMethod'] != null
                                      ? "Transfer (${item['salesMethod']})"
                                      : "Exchange",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: primaryBrown,
                                  ),
                                ),
                                const SizedBox(height: 2),

Text(
                                  item['receiverId'] != null
                                      ? "To ID: ${item['receiverId']}"
                                      : "Coins: +${item['coinsAdded']}",
                                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                                ),
                              ],
                            ),
                            Text(
                              item['coins'] != null ? "-${item['coins']} Coins" : "-${item['pointsDeducted']} Pts",
                              style: const TextStyle(
                                color: accentGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGreetingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Greeting Message Settings",
          style: TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _greetingController,
          maxLines: 3,
          style: const TextStyle(color: primaryBrown),
          decoration: InputDecoration(
            hintText: "Enter automatic greeting for your buyers...",
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final msg = _greetingController.text.trim();
              if (msg.isNotEmpty && _currentUser != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .set({'sellerGreeting': msg}, SetOptions(merge: true));
              }
              if (mounted) Navigator.pop(ctx);
              _showToast("Greeting message saved.");
            },
            child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _currentUser?.uid ?? "";

    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text("Please sign in first.", style: TextStyle(color: Colors.black54)),
        ),
      );
    }

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
          "Coin Seller Hub",
          style: TextStyle(
            color: primaryBrown,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          final userData = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final String name = userData['agencyName'] ?? userData['name'] ?? userData['displayName'] ?? "KEDIR FAMS";
          final String numericId = (userData['numericId'] ?? userData['id'] ?? "1753925").toString();
          final int coins = (userData['coins'] as num?)?.toInt() ?? 0;
          final int points = (userData['points'] as num?)?.toInt() ?? 0;
          final String currentLevel = userData['sellerLevel'] ?? "Beginner Seller";

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. Seller Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
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
                      child: const Icon(Icons.storefront, color: primaryBrown, size: 26),
                    ),
                    const SizedBox(width: 12),
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
                                    color: primaryBrown,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _copyToClipboard(numericId),
                                child: const Icon(Icons.copy, size: 12, color: primaryBrown),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "ID: $numericId",
                            style: const TextStyle(color: Colors.black45, fontSize: 11),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Current level: $currentLevel",
                            style: const TextStyle(
                              color: accentGold,

fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Level Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Balance & Payment Method Card
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
                          "Balance",
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: () => _showHistoryModal("Transfer History", "coin_transfers"),
                          child: const Text(
                            "Details >",
                            style: TextStyle(color: primaryBrown, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: accentGold, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: primaryBrown,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFEFE6DE), height: 22),
                    const Text(
                      "Payment Method:",
                      style: TextStyle(color: primaryBrown, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPaymentMethodPill(0, "Telebirr", Icons.phone_android),
                        const SizedBox(width: 10),
                        _buildPaymentMethodPill(1, "Binance Pay", Icons.currency_bitcoin),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Tab Structure (Transfer, Recharge, Exchange)
              Container(
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
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: "Transfer"),
                    Tab(text: "Recharge"),
                    Tab(text: "Exchange"),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tab View Content
              SizedBox(
                height: 480,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransferSection(coins),
                    _buildRechargeSection(),
                    _buildExchangeSection(points),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. Greeting Message Setting Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: primaryBrown, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Greeting Message Settings",
                          style: TextStyle(
                            color: primaryBrown,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14, color: primaryBrown),
                      onPressed: _showGreetingDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodPill(int index, String label, IconData icon) {
    final bool isSelected = _selectedPaymentMethod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? buttonDark : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? buttonDark : borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : primaryBrown, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : primaryBrown,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Transfer Section
  Widget _buildTransferSection(int sellerCoins) {
    return SingleChildScrollView(

physics: const BouncingScrollPhysics(),
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
            const Text(
              "Sales Method",
              style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSalesMethodOption(0, "User"),
                const SizedBox(width: 10),
                _buildSalesMethodOption(1, "Coinseller"),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              "User ID",
              style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _receiverIdController,
                      style: const TextStyle(color: primaryBrown),
                      decoration: const InputDecoration(
                        hintText: "Enter user ID",
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _verifyReceiver,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: buttonDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Check",
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_verifiedReceiverName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                "Name: $_verifiedReceiverName",
                style: const TextStyle(color: accentGold, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              "Coin Amount",
              style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _coinAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: primaryBrown),
                decoration: const InputDecoration(
                  hintText: "Enter amount *1,000",
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 12),

border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Please enter a multiple of 1",
              style: TextStyle(color: Colors.black38, fontSize: 10.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : () => _executeCoinTransfer(sellerCoins),
                child: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Transfer", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () => _showHistoryModal("Transfer Details", "coin_transfers"),
                child: const Text(
                  "Transfer Detail >",
                  style: TextStyle(color: primaryBrown, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesMethodOption(int index, String label) {
    final bool isSelected = _salesMethodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _salesMethodIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? buttonDark : bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? buttonDark : borderColor),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : primaryBrown,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 2. Recharge Section
  Widget _buildRechargeSection() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
              children: [
                _buildRechargeSubTab(0, "Official"),
                const SizedBox(width: 10),
                _buildRechargeSubTab(1, "Coin Seller"),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              "Select Recharge Package",
              style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rechargePackages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,

),
              itemBuilder: (context, idx) {
                final pkg = _rechargePackages[idx];
                final isSelected = _selectedRechargePackage == idx;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRechargePackage = idx),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFBF4E6) : bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? accentGold : borderColor, width: isSelected ? 1.5 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${pkg['coins']} Coins",
                          style: const TextStyle(color: primaryBrown, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pkg['price'].toString(),
                          style: const TextStyle(color: accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pkg['tier'].toString(),
                          style: const TextStyle(color: Colors.black38, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  final channel = _selectedPaymentMethod == 0 ? "Telebirr" : "Binance Pay";
                  _showToast("Opening $channel gateway for wholesale recharge...");
                },
                child: const Text("Recharge", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () => _showHistoryModal("Recharge Details", "coin_recharges"),
                child: const Text(
                  "Recharge Details >",
                  style: TextStyle(color: primaryBrown, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRechargeSubTab(int index, String label) {
    final bool isSelected = _rechargeSubTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rechargeSubTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? buttonDark : bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? buttonDark : borderColor),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : primaryBrown,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

// 3. Exchange Section (Points to Coins)
  Widget _buildExchangeSection(int userPoints) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                const Text("My Points", style: TextStyle(color: Colors.black45, fontSize: 12)),
                Text(
                  "$userPoints Pts",
                  style: const TextStyle(color: accentGold, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(color: Color(0xFFEFE6DE), height: 18),
            const Text(
              "Custom Exchange",
              style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customExchangeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: primaryBrown),
                      decoration: const InputDecoration(
                        hintText: "Enter points to exchange",
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final input = int.tryParse(_customExchangeController.text.trim()) ?? 0;
                      if (input > 0) {
                        // 1 USD = 10,000 Points; 1:1 direct equivalence to coins
                        _executePointsExchange(userPoints, input, input);
                      }
                    },
                    child: const Text("Convert", style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Standard Exchange Packs",
              style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._exchangePacks.map((pack) {
              final int coinsGain = pack['coins'] as int;
              final int pointsCost = pack['points'] as int;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(

"$coinsGain Coins",
                          style: const TextStyle(color: primaryBrown, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          "$pointsCost Points",
                          style: const TextStyle(color: Colors.black38, fontSize: 10.5),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF107C41),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        elevation: 0,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _executePointsExchange(userPoints, pointsCost, coinsGain),
                      child: const Text("Exchange", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => _showHistoryModal("Exchange Details", "point_exchanges"),
                child: const Text(
                  "Exchange Details >",
                  style: TextStyle(color: primaryBrown, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
