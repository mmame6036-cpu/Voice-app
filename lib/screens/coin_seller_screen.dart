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

  int _selectedPayoutChannel = 0; // 0: Telebirr, 1: CBE, 2: Abyssinia, 3: Binance
  int _selectedRechargeChannel = 0; // 0: Binance Pay, 1: Telebirr
  int _selectedPackageIndex = 0;

  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _coinAmountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();

  bool _isProcessing = false;
  String _checkedUserName = "";

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkBg = Color(0xFF0D0A1C);
  static const Color cardBg = Color(0xFF171524);

  final List> _rechargePackages = [
    {"coins": 1980000, "price": "\$200 / 24,000 ETB", "tag": "Standard"},
    {"coins": 9900000, "price": "\$1,000 / 120,000 ETB", "tag": "Standard"},
    {"coins": 14850000, "price": "\$1,500 / 180,000 ETB", "tag": "Popular"},
    {"coins": 30000000, "price": "\$3,000 / 360,000 ETB", "tag": "VIP Merchant"},
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
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard", style: TextStyle(color: goldColor)),
        backgroundColor: cardBg,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _verifyReceiver() async {
    final queryText = _receiverIdController.text.trim();
    if (queryText.isEmpty) return;

    setState(() => _checkedUserName = "Searching...");

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
          _checkedUserName = data['nickname'] ?? data['name'] ?? "Verified User";
        });
      } else {
        setState(() => _checkedUserName = "User Not Found");
      }
    } catch (_) {
      setState(() => _checkedUserName = "Verification Error");
    }
  }

  Future<void> _executeCoinTransfer(int sellerBalance) async {
    final targetInput = _receiverIdController.text.trim();
    final amountInput = int.tryParse(_coinAmountController.text.trim()) ?? 0;

    if (targetInput.isEmpty || amountInput <= 0) {
      _showFeedback("Please enter a valid receiver ID and coin amount.");
      return;
    }

    if (amountInput % 1000 != 0) {
      _showFeedback("Amount must be a multiple of 1,000.");
      return;
    }

    if (amountInput > sellerBalance) {
      _showFeedback("Insufficient seller balance.");
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
        _showFeedback("Target receiver account does not exist.");
        setState(() => _isProcessing = false);
        return;
      }

      final receiverRef = query.docs.first.reference;
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
          'receiverUid': receiverRef.id,
          'amount': amountInput,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'transfer',
        });
      });

      _receiverIdController.clear();
      _coinAmountController.clear();
      setState(() => _checkedUserName = "");
      _showFeedback("Transfer of $amountInput Coins completed successfully!");
    } catch (e) {
      _showFeedback("Transfer failed: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _submitPayoutRequest(int availableDiamonds) async {
    final accountNum = _accountNumberController.text.trim();
    final accountName = _accountNameController.text.trim();

    if (accountNum.isEmpty || accountName.isEmpty) {
      _showFeedback("Please fill in account details.");
      return;
    }

    if (availableDiamonds < 100000) {
      _showFeedback("Minimum payout requirement is 100,000 Diamonds.");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final channels = ["Telebirr", "Commercial Bank of Ethiopia (CBE)", "Bank of Abyssinia", "Binance Pay (USDT)"];
      final chosenChannel = channels[_selectedPayoutChannel];

      await FirebaseFirestore.instance.collection('payout_requests').add({
        'uid': _currentUser!.uid,
        'channel': chosenChannel,
        'accountNumber': accountNum,
        'accountName': accountName,
        'diamondAmount': availableDiamonds,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _accountNumberController.clear();
      _accountNameController.clear();
      Navigator.pop(context);
      _showFeedback("Payout request submitted for $chosenChannel!");
    } catch (e) {
      _showFeedback("Submission error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        backgroundColor: cardBg,
      ),
    );
  }

  void _openPayoutModal(int availableDiamonds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(

borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Diamond Points Settlement",
                style: TextStyle(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Available: $availableDiamonds Points (≈ \$${(availableDiamonds / 10000).toStringAsFixed(2)} USD)",
                style: const TextStyle(color: goldColor, fontSize: 13),
              ),
              const SizedBox(height: 18),
              const Text(
                "Select Payout Method",
                style: TextStyle(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPayoutOption(0, "Telebirr", Icons.phone_android, setModalState),
                    _buildPayoutOption(1, "CBE", Icons.account_balance, setModalState),
                    _buildPayoutOption(2, "Abyssinia", Icons.account_balance_wallet, setModalState),
                    _buildPayoutOption(3, "Binance Pay", Icons.currency_bitcoin, setModalState),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _accountNumberController,
                style: const TextStyle(color: goldColor),
                decoration: InputDecoration(
                  hintText: _selectedPayoutChannel == 3 ? "Binance Pay ID / USDT Address" : "Account / Phone Number",
                  hintStyle: TextStyle(color: goldColor.withOpacity(0.4), fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _accountNameController,
                style: const TextStyle(color: goldColor),
                decoration: InputDecoration(
                  hintText: "Account Holder Full Name",
                  hintStyle: TextStyle(color: goldColor.withOpacity(0.4), fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : () => _submitPayoutRequest(availableDiamonds),
                  child: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text("Submit Payout Request", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildPayoutOption(int index, String label, IconData icon, StateSetter setModalState) {
    final bool isSelected = _selectedPayoutChannel == index;
    return GestureDetector(
      onTap: () {
        setModalState(() => _selectedPayoutChannel = index);
        setState(() => _selectedPayoutChannel = index);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? goldColor : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: goldColor.withOpacity(isSelected ? 1.0 : 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : goldColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : goldColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: goldColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Coin Seller Portal",
          style: TextStyle(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : null,
        builder: (context, userSnap) {
          final uData = (userSnap.hasData && userSnap.data!.exists)
              ? userSnap.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final int coins = uData['coins'] ?? 0;
          final int diamonds = uData['diamonds'] ?? 0;
          final String displayId = uData['numericId']?.toString() ?? (uid.length >= 6 ? uid.substring(0, 6) : "100000");

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Profile Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: goldColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: goldColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: goldColor),
                                ),
                                child: const Center(
                                  child: Icon(Icons.storefront, color: goldColor, size: 26),
                                ),

),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "MERCHANT ACCOUNT",
                                      style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _copyToClipboard(displayId),
                                      child: Row(
                                        children: [
                                          Text("ID: $displayId", style: TextStyle(color: goldColor.withOpacity(0.8), fontSize: 12)),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.copy, size: 12, color: goldColor),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: goldColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: goldColor),
                                ),
                                child: const Text(
                                  "Certified",
                                  style: TextStyle(color: goldColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF281C4B), cardBg],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: goldColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Seller Coin Balance",
                                    style: TextStyle(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  GestureDetector(
                                    onTap: () => _openPayoutModal(diamonds),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

decoration: BoxDecoration(
                                        color: goldColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "Convert Points",
                                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.monetization_on, color: goldColor, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$coins",
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: goldColor),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 20),
                              Text(
                                "Diamonds Available: $diamonds Pts",
                                style: TextStyle(color: goldColor.withOpacity(0.8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SellerTabDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: goldColor,
                      indicatorWeight: 3,
                      labelColor: goldColor,
                      unselectedLabelColor: goldColor.withOpacity(0.4),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: "Transfer"),
                        Tab(text: "Recharge"),
                        Tab(text: "Settlement"),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTransferTab(coins),
                _buildRechargeTab(),
                _buildSettlementTab(diamonds),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransferTab(int sellerBalance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Receiver User ID or UID:", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: goldColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _receiverIdController,
                    style: const TextStyle(color: goldColor),
                    decoration: InputDecoration(

hintText: "Enter Receiver Numeric ID (e.g. 100000)",
                      hintStyle: TextStyle(color: goldColor.withOpacity(0.4), fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _verifyReceiver,
                  child: const Text("Verify", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (_checkedUserName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "Account: $_checkedUserName",
              style: const TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 18),
          const Text("Coin Amount:", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: goldColor.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _coinAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: goldColor),
              decoration: InputDecoration(
                hintText: "Enter amount (Multiples of 1,000)",
                hintStyle: TextStyle(color: goldColor.withOpacity(0.4), fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _isProcessing ? null : () => _executeCoinTransfer(sellerBalance),
              child: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("Confirm Transfer", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Recharge Method:", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRechargeChannel = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedRechargeChannel == 0 ? goldColor.withOpacity(0.15) : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: goldColor.withOpacity(_selectedRechargeChannel == 0 ? 1.0 : 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.currency_bitcoin, color: goldColor, size: 24),
                        SizedBox(height: 4),

Text("Binance Pay", style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRechargeChannel = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedRechargeChannel == 1 ? goldColor.withOpacity(0.15) : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: goldColor.withOpacity(_selectedRechargeChannel == 1 ? 1.0 : 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.phone_android, color: goldColor, size: 24),
                        SizedBox(height: 4),
                        Text("Telebirr", style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Wholesale Packages:", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: _rechargePackages.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, idx) {
              final pkg = _rechargePackages[idx];
              final isSelected = _selectedPackageIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _selectedPackageIndex = idx),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor.withOpacity(0.15) : cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldColor.withOpacity(isSelected ? 1.0 : 0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${pkg['coins']} Coins", style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(pkg['price'], style: TextStyle(color: goldColor.withOpacity(0.7), fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {
                final chosen = _selectedRechargeChannel == 0 ? "Binance Pay" : "Telebirr";
                _showFeedback("Opening $chosen merchant payment gateway...");
              },
              child: const Text("Recharge Now", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSettlementTab(int availableDiamonds) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: goldColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Available Diamond Points:", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13)),
                Text("$availableDiamonds Pts", style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Accepted Channels for Cashout:", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          _buildPayoutChannelCard("Telebirr", "Instant local cashout", Icons.phone_android),
          _buildPayoutChannelCard("Commercial Bank of Ethiopia (CBE)", "Direct bank deposit", Icons.account_balance),
          _buildPayoutChannelCard("Bank of Abyssinia", "Direct bank deposit", Icons.account_balance_wallet),
          _buildPayoutChannelCard("Binance Pay (USDT)", "Crypto settlement globally", Icons.currency_bitcoin),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () => _openPayoutModal(availableDiamonds),
              child: const Text("Request Payout", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutChannelCard(String name, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goldColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: goldColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: TextStyle(color: goldColor.withOpacity(0.5), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SellerTabDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: const Color(0xFF171524), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SellerTabDelegate oldDelegate) => false;
}
