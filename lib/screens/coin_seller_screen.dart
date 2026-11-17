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

  int _activeTabIndex = 0;
  int _salesMethodIndex = 0; // 0: User, 1: Coinseller
  int _rechargeSubTabIndex = 0; // 0: Official, 1: Coin Seller
  int _selectedPaymentMethod = 0; // 0: Binance Pay, 1: Telebirr
  int _selectedRechargePackage = 0;

  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _coinAmountController = TextEditingController();
  final TextEditingController _customExchangeController = TextEditingController();
  final TextEditingController _greetingController = TextEditingController();

  bool _isProcessing = false;
  String _verifiedReceiverName = "";
  bool _verifiedReceiverIsAgent = false;
  String _checkedNumericIdCache = "";
  bool _isAgencyOwnerFromDb = false;

  static const String officialBinancePayId = "1059643208";
  static const String officialTelebirrNumber = "0943724560";

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color cardBg = Colors.white;
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color accentGreen = Color(0xFF107C41);
  static const Color borderColor = Color(0xFFE2D6C5);
  static const Color buttonDark = Color(0xFF4A3528);

  final List _rechargePackages = const [
    {"coins": 1980000, "usd": 200, "price": "\$200 USD", "tier": "Standard Seller"},
    {"coins": 9900000, "usd": 1000, "price": "\$1,000 USD", "tier": "Standard Seller"},
    {"coins": 14850000, "usd": 1500, "price": "\$1,500 USD", "tier": "Senior Seller"},
    {"coins": 30000000, "usd": 3000, "price": "\$3,000 USD", "tier": "VIP Official"},
  ];

  final List _exchangePacks = const [
    {"coins": 96000, "points": 100000},
    {"coins": 960000, "points": 1000000},
    {"coins": 1920000, "points": 2000000},
    {"coins": 9600000, "points": 10000000},
    {"coins": 14400000, "points": 15000000},
    {"coins": 28800000, "points": 30000000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTabIndex = _tabController.index;
        });
      }
    });
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
    _showToast("Copied: $text");
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

  bool _checkUserMapIsAgent(Map data) {
    final String role = (data['role'] ?? '').toString().toLowerCase().trim();
    if (data['isAgent'] == true) return true;
    if (data['isCoinSeller'] == true) return true;
    if (const ['agent', 'agency', 'coinseller'].contains(role)) return true;
    if ((data['agencyId'] ?? '').toString().trim().isNotEmpty) return true;
    if ((data['agencyName'] ?? '').toString().trim().isNotEmpty) return true;
    return false;
  }

Future<void> _verifyAgencyOwnership(String numericIdStr) async {
    if (numericIdStr.isEmpty) return;
    if (_checkedNumericIdCache == numericIdStr) return;
    _checkedNumericIdCache = numericIdStr;
    final int? numId = int.tryParse(numericIdStr);
    if (numId == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('agencies')
          .where('ownerNumericId', isEqualTo: numId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        setState(() {
          _isAgencyOwnerFromDb = true;
        });
      }
    } catch (_) {}
  }

  String _resolveSellerLevel(int totalCoinsSold) {
    if (totalCoinsSold >= 30000000) {
      return "VIP Official Seller";
    }
    if (totalCoinsSold >= 10000000) {
      return "Senior Seller";
    }
    if (totalCoinsSold >= 2000000) {
      return "Standard Seller";
    }
    return "Beginner Seller";
  }

  void _showSellerLevelDialog(int totalCoinsSold, String currentLevel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: accentGold, size: 24),
            SizedBox(width: 8),
            Text(
              "Agent Coin Seller Tiers",
              style: TextStyle(color: textBlack, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Rank: $currentLevel",
              style: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              "Total Coins Transferred: $totalCoinsSold Coins",
              style: const TextStyle(color: Colors.black87, fontSize: 12),
            ),
            const Divider(height: 20),
            const Text(
              "• Beginner Seller: 0 - 1,999,999 Coins sold\n"
              "• Standard Seller: 2,000,000+ Coins sold\n"
              "• Senior Seller: 10,000,000+ Coins sold\n"
              "• VIP Official Seller: 30,000,000+ Coins sold",
              style: TextStyle(color: textBlack, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: buttonDark),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _isTargetDocAgent(Map data, int? numId) async {
    if (_checkUserMapIsAgent(data)) return true;
    if (numId != null) {
      final agSnap = await FirebaseFirestore.instance
          .collection('agencies')
          .where('ownerNumericId', isEqualTo: numId)
          .limit(1)
          .get();
      if (agSnap.docs.isNotEmpty) return true;
    }
    return false;
  }

  Future<void> _verifyReceiver() async {
    final queryText = _receiverIdController.text.trim();
    if (queryText.isEmpty) return;

    setState(() {
      _verifiedReceiverName = "Searching...";
      _verifiedReceiverIsAgent = false;
    });

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
        final raw = query.docs.first.data();
        final Map data = raw is Map ? raw : {};
        String foundName = "Verified User";
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          foundName = data['name'].toString();
        } else if (data['displayName'] != null && data['displayName'].toString().isNotEmpty) {
          foundName = data['displayName'].toString();
        }
        final int? resolvedNum = (data['numericId'] as num?)?.toInt() ?? numId;
        final bool targetIsAgent = await _isTargetDocAgent(data, resolvedNum);

        if (mounted) {
          setState(() {
            _verifiedReceiverName = foundName;
            _verifiedReceiverIsAgent = targetIsAgent;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _verifiedReceiverName = "User Not Found";
            _verifiedReceiverIsAgent = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _verifiedReceiverName = "Verification Failed";
          _verifiedReceiverIsAgent = false;
        });
      }
    }
  }

  Future<void> _executeCoinTransfer({
    required int sellerBalance,
    required String sellerName,
    required String sellerNumericId,
    required String sellerGreeting,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final targetInput = _receiverIdController.text.trim();
    final amountInput = int.tryParse(_coinAmountController.text.trim()) ?? 0;

    if (targetInput.isEmpty) {
      _showToast("Please enter a valid receiver ID.");
      return;
    }
    if (amountInput <= 0) {
      _showToast("Please enter a valid coin amount.");
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
      if (receiverDoc.id == user.uid) {
        _showToast("You cannot transfer coins to your own account.");
        setState(() => _isProcessing = false);
        return;
      }

      final rawReceiver = receiverDoc.data();
      final Map receiverMap = rawReceiver is Map ? rawReceiver : {};
      final int? targetNumId = (receiverMap['numericId'] as num?)?.toInt() ?? numId;

      if (_salesMethodIndex == 1) {
        final bool targetIsAgent = await _isTargetDocAgent(receiverMap, targetNumId);
        if (!targetIsAgent) {
          _showToast("Target account is not a registered Agent / Coin Seller.");
          setState(() => _isProcessing = false);
          return;
        }
      }

      final receiverRef = receiverDoc.reference;
      final sellerRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final String salesType = _salesMethodIndex == 1 ? "Coinseller" : "User";

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final sellerSnap = await transaction.get(sellerRef);
        final rawSeller = sellerSnap.data();
        final Map sellerMap = rawSeller is Map ? rawSeller : {};
        final int currentCoins = (sellerMap['coins'] as num?)?.toInt() ?? 0;
        final int prevSold = (sellerMap['totalCoinsSold'] as num?)?.toInt() ?? 0;

if (currentCoins < amountInput) {
          throw Exception("Insufficient balance.");
        }

        final int newTotalSold = prevSold + amountInput;
        final String newLevel = _resolveSellerLevel(newTotalSold);

        transaction.update(sellerRef, {
          'coins': FieldValue.increment(-amountInput),
          'totalCoinsSold': newTotalSold,
          'sellerLevel': newLevel,
        });

        transaction.update(receiverRef, {
          'coins': FieldValue.increment(amountInput),
        });

        final logRef = FirebaseFirestore.instance.collection('coin_transfers').doc();
        transaction.set(logRef, {
          'sellerUid': user.uid,
          'sellerName': sellerName,
          'sellerNumericId': sellerNumericId,
          'receiverUid': receiverDoc.id,
          'receiverId': targetInput,
          'salesMethod': salesType,
          'coins': amountInput,
          'greeting': sellerGreeting,
          'timestamp': FieldValue.serverTimestamp(),
        });

        final notifRef = receiverRef.collection('notifications').doc();
        transaction.set(notifRef, {
          'type': 'COIN_RECEIVED',
          'title': 'Coins Received (+$amountInput)',
          'message': sellerGreeting,
          'coins': amountInput,
          'senderUid': user.uid,
          'senderName': sellerName,
          'senderNumericId': sellerNumericId,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      _receiverIdController.clear();
      _coinAmountController.clear();
      setState(() {
        _verifiedReceiverName = "";
        _verifiedReceiverIsAgent = false;
      });
      _showToast("Successfully transferred $amountInput Coins!");
    } catch (e) {
      _showToast("Transfer failed: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openWholesaleRechargeDialog({
    required String sellerNumericId,
    required String sellerName,
  }) async {
    if (_isProcessing) return;
    final user = _currentUser;
    if (user == null) return;

    final pkg = _rechargePackages[_selectedRechargePackage];
    final int coinsToReceive = pkg['coins'] as int;
    final int usdCost = pkg['usd'] as int;
    final String priceLabel = pkg['price'].toString();

    String methodTitle = "Binance Pay (USD)";
    String payAddress = officialBinancePayId;
    if (_selectedPaymentMethod == 1) {
      methodTitle = "Telebirr (USD)";
      payAddress = officialTelebirrNumber;
    }

    final String channelType =
        _rechargeSubTabIndex == 1 ? "Senior Coin Seller" : "Official Wholesale";
    final String orderRef =
        "SLR_${sellerNumericId}_${DateTime.now().millisecondsSinceEpoch}";

    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('coin_recharges')
          .doc(orderRef)
          .set({
        'orderRef': orderRef,
        'uid': user.uid,
        'sellerNumericId': sellerNumericId,
        'sellerName': sellerName,
        'channelType': channelType,
        'paymentMethod': methodTitle,
        'currency': 'USD',
        'coins': coinsToReceive,
        'usdAmount': usdCost,
        'paymentTxnId': '',
        'status': 'PENDING',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showToast("Failed to create order: $e");
      }
      return;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (!mounted) return;
    final TextEditingController receiptController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: accentGreen, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Wholesale Order ($priceLabel)",
                style: const TextStyle(
                  color: textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Coins: ",
                    style: TextStyle(
                      color: textBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    "$coinsToReceive Coins",
                    style: const TextStyle(
                      color: accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    " ($priceLabel)",
                    style: const TextStyle(
                      color: textBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Order Ref: $orderRef",
                style: const TextStyle(
                  color: accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "1. Send exact $priceLabel via $methodTitle to:",
                style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        payAddress,
                        style: const TextStyle(
                          color: textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyToClipboard(payAddress),
                      child: const Icon(Icons.copy, size: 18, color: primaryBrown),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "2. Enter Payment Transaction ID / Receipt:",
                style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: receiptController,
                style: const TextStyle(color: textBlack, fontSize: 13),
                decoration: InputDecoration(

hintText: "e.g. Binance Order ID or Telebirr Ref",
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 11.5),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              const SizedBox(height: 10),
              const Text(
                "Order is sent to Admin Dashboard as PENDING. Once verified by Admin, coins will be added to your agent balance.",
                style: TextStyle(color: Colors.black54, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final proof = receiptController.text.trim();
              if (proof.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('coin_recharges')
                    .doc(orderRef)
                    .set({'paymentTxnId': proof}, SetOptions(merge: true)).catchError((_) {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _showToast("Order $orderRef submitted! Check Recharge Details.");
            },
            child: const Text("Submit Order", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executePointsExchange(
      int userPoints, int pointsCost, int coinsGain) async {
    final user = _currentUser;
    if (user == null) return;
    if (pointsCost <= 0) return;
    if (coinsGain <= 0) return;

    if (pointsCost < 10000) {
      _showToast("Minimum exchange is 10,000 Points.");
      return;
    }

    if (userPoints < pointsCost) {
      _showToast("Insufficient points balance.");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(userRef);
        final raw = snap.data();
        final Map data = raw is Map ? raw : {};
        final int currentPts = (data['points'] as num?)?.toInt() ?? 0;

        if (currentPts < pointsCost) {
          throw Exception("Insufficient points.");
        }

        transaction.update(userRef, {
          'points': FieldValue.increment(-pointsCost),
          'coins': FieldValue.increment(coinsGain),
        });

        final logRef = FirebaseFirestore.instance.collection('point_exchanges').doc();
        transaction.set(logRef, {
          'uid': user.uid,
          'pointsDeducted': pointsCost,
          'coinsAdded': coinsGain,
          'rate': '96%',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      _customExchangeController.clear();
      _showToast("Exchanged $pointsCost Points for $coinsGain Coins (96% Agent Rate)!");
    } catch (e) {
      _showToast("Exchange failed: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showHistoryModal(String title, String collectionName) {
    final String filterField =
        collectionName == 'coin_transfers' ? "sellerUid" : "uid";
    final String currentUid = _currentUser?.uid ?? "";

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
                color: textBlack,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection(collectionName)
                    .where(filterField, isEqualTo: currentUid)
                    .limit(100)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text(
                        "No history records found.",
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    );
                  }
                  final qSnap = snapshot.data as QuerySnapshot;
                  if (qSnap.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No history records found.",
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    );
                  }

                  final docs = qSnap.docs.toList();
                  docs.sort((a, b) {
                    final rawA = a.data();
                    final rawB = b.data();
                    final Map mapA = rawA is Map ? rawA : {};
                    final Map mapB = rawB is Map ? rawB : {};
                    final tsA = mapA['timestamp'];
                    final tsB = mapB['timestamp'];
                    if (tsA is Timestamp && tsB is Timestamp) {
                      return tsB.compareTo(tsA);
                    }
                    return 0;
                  });

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final raw = docs[idx].data();
                      final Map item = raw is Map ? raw : {};

                      String headerTitle = "Agent Exchange (96%)";
                      if (item['salesMethod'] != null) {
                        headerTitle = "Transfer (${item['salesMethod']})";
                      } else if (item['orderRef'] != null) {
                        final String st = (item['status'] ?? 'PENDING').toString();
                        headerTitle = "Wholesale Recharge ($st)";
                      }

                      String subInfo = "";
                      if (item['receiverId'] != null) {
                        subInfo = "To ID: ${item['receiverId']}";
                      } else if (item['orderRef'] != null) {
                        final String tx = (item['paymentTxnId'] ?? '').toString();
                        subInfo = tx.isNotEmpty
                            ? "Ref: ${item['orderRef']} • Tx: $tx"

: "Ref: ${item['orderRef']} (\$${item['usdAmount']} USD)";
                      } else if (item['coinsAdded'] != null) {
                        subInfo = "Points: -${item['pointsDeducted']} Pts";
                      }

                      String amountRight = "";
                      if (item['orderRef'] != null) {
                        amountRight = "+${item['coins']} Coins";
                      } else if (item['coins'] != null) {
                        amountRight = "-${item['coins']} Coins";
                      } else if (item['coinsAdded'] != null) {
                        amountRight = "+${item['coinsAdded']} Coins";
                      }

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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    headerTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: textBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subInfo,
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              amountRight,
                              style: const TextStyle(
                                color: accentGreen,
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

  void _showGreetingDialog(String existingGreeting) {
    _greetingController.text = existingGreeting;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Greeting Message Settings",
          style: TextStyle(
              color: textBlack, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _greetingController,
          maxLines: 3,
          style: const TextStyle(color: textBlack),
          decoration: InputDecoration(
            hintText: "Enter automatic greeting sent to buyers...",
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final msg = _greetingController.text.trim();
              final user = _currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({'sellerGreeting': msg}, SetOptions(merge: true));
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _showToast("Greeting message saved.");
            },
            child: const Text("Save",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedAccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person,
                    color: Colors.redAccent, size: 40),
              ),
              const SizedBox(height: 14),
              const Text(
                "Agents Only (Access Restricted)",
                style: TextStyle(
                  color: textBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Coin Seller Hub is exclusively available for verified Agency Owners. Hosts and standard users cannot access this section.",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Go Back",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          child: Text("Please sign in first.",
              style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Agent Coin Seller Hub",
          style: TextStyle(
            color: textBlack,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: primaryBrown),
            );
          }

          final docSnap = snapshot.data as DocumentSnapshot;
          Map userData = {};
          if (docSnap.exists) {
            final raw = docSnap.data();
            if (raw is Map) {
              userData = raw;
            }
          }

          String numericId = "100000";
          if (userData['numericId'] != null) {
            numericId = userData['numericId'].toString();
          } else if (userData['id'] != null) {
            numericId = userData['id'].toString();
          }

          _verifyAgencyOwnership(numericId);

          bool isAuthorizedAgent = _checkUserMapIsAgent(userData);
          if (_isAgencyOwnerFromDb) {
            isAuthorizedAgent = true;
          }
          if (!isAuthorizedAgent) {
            return _buildRestrictedAccessView();
          }

          String name = "Agent Seller";
          if (userData['agencyName'] != null &&
              userData['agencyName'].toString().isNotEmpty) {
            name = userData['agencyName'].toString();
          } else if (userData['name'] != null &&
              userData['name'].toString().isNotEmpty) {
            name = userData['name'].toString();
          } else if (userData['displayName'] != null &&
              userData['displayName'].toString().isNotEmpty) {
            name = userData['displayName'].toString();
          }

          final int coins = (userData['coins'] as num?)?.toInt() ?? 0;
          final int points = (userData['points'] as num?)?.toInt() ?? 0;
          final int totalCoinsSold =
              (userData['totalCoinsSold'] as num?)?.toInt() ?? 0;
          final String currentLevel = _resolveSellerLevel(totalCoinsSold);

          String sellerGreeting = "Thank you for buying from NILE Live!";
          if (userData['sellerGreeting'] != null &&
              userData['sellerGreeting'].toString().isNotEmpty) {
            sellerGreeting = userData['sellerGreeting'].toString();
          }

          Widget activeBodySection = _buildTransferSection(
            sellerCoins: coins,
            sellerName: name,
            sellerNumericId: numericId,
            sellerGreeting: sellerGreeting,
          );
          if (_activeTabIndex == 1) {
            activeBodySection = _buildRechargeSection(
              sellerNumericId: numericId,
              sellerName: name,
            );
          } else if (_activeTabIndex == 2) {
            activeBodySection = _buildExchangeSection(points);
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [

// 1. Agent Profile Card
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
                      child: const Icon(Icons.storefront,
                          color: primaryBrown, size: 26),
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
                                    color: textBlack,
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
                                child: const Icon(Icons.copy,
                                    size: 13, color: primaryBrown),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Agent ID: $numericId • Sold: $totalCoinsSold",
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 11),
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
                    GestureDetector(
                      onTap: () =>
                          _showSellerLevelDialog(totalCoinsSold, currentLevel),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentGreen,
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
                          "Agent Coin Balance",
                          style:
                              TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: () => _showHistoryModal(
                              "Transfer History", "coin_transfers"),
                          child: const Text(
                            "Details >",
                            style: TextStyle(
                                color: textBlack,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            color: accentGreen, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: accentGreen,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Coins",
                          style: TextStyle(
                            color: accentGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFEFE6DE), height: 22),
                    const Text(
                      "Wholesale Payment Method (USD):",
                      style: TextStyle(
                          color: textBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPaymentMethodPill(
                            0, "Binance Pay (USD)", Icons.currency_bitcoin),
                        const SizedBox(width: 10),
                        _buildPaymentMethodPill(
                            1, "Telebirr (USD)", Icons.phone_android),
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
                  unselectedLabelColor: textBlack,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  onTap: (idx) {
                    setState(() {
                      _activeTabIndex = idx;
                    });
                  },
                  tabs: const [
                    Tab(text: "Transfer"),
                    Tab(text: "Recharge"),
                    Tab(text: "Exchange"),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Dynamic Active Section
              activeBodySection,

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
                        Icon(Icons.chat_bubble_outline,
                            color: textBlack, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Greeting Message Settings",
                          style: TextStyle(
                            color: textBlack,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: textBlack),
                      onPressed: () => _showGreetingDialog(sellerGreeting),
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
    final Color bg = isSelected ? buttonDark : bgColor;
    final Color border = isSelected ? buttonDark : borderColor;
    final Color fg = isSelected ? Colors.white : textBlack;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Transfer Section
  Widget _buildTransferSection({
    required int sellerCoins,
    required String sellerName,
    required String sellerNumericId,
    required String sellerGreeting,
  }) {
    VoidCallback? transferAction = () => _executeCoinTransfer(

sellerBalance: sellerCoins,
          sellerName: sellerName,
          sellerNumericId: sellerNumericId,
          sellerGreeting: sellerGreeting,
        );
    Widget transferChild = const Text(
      "Transfer",
      style: TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
    );

    if (_isProcessing) {
      transferAction = null;
      transferChild = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return Container(
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
            style: TextStyle(
                color: textBlack, fontSize: 13, fontWeight: FontWeight.bold),
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
            "Receiver User ID",
            style: TextStyle(
                color: textBlack, fontSize: 13, fontWeight: FontWeight.bold),
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
                    onChanged: (_) {
                      if (_verifiedReceiverName.isNotEmpty) {
                        setState(() {
                          _verifiedReceiverName = "";
                          _verifiedReceiverIsAgent = false;
                        });
                      }
                    },
                    style: const TextStyle(
                        color: textBlack, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: "Enter receiver numeric ID",
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _verifyReceiver,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: buttonDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Check",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_verifiedReceiverName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _verifiedReceiverIsAgent
                  ? "Receiver: $_verifiedReceiverName (Agent / Seller)"
                  : "Receiver: $_verifiedReceiverName",
              style: TextStyle(

color: _verifiedReceiverName == "User Not Found"
                      ? Colors.redAccent
                      : accentGreen,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            "Coin Amount",
            style: TextStyle(
                color: textBlack, fontSize: 13, fontWeight: FontWeight.bold),
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
              style: const TextStyle(
                  color: accentGreen, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "Enter amount (e.g. 10000)",
                hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Must be a multiple of 1,000 Coins",
            style: TextStyle(color: Colors.black45, fontSize: 10.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: transferAction,
              child: transferChild,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () =>
                  _showHistoryModal("Transfer Details", "coin_transfers"),
              child: const Text(
                "Transfer Detail >",
                style: TextStyle(
                    color: textBlack,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesMethodOption(int index, String label) {
    final bool isSelected = _salesMethodIndex == index;
    final Color bg = isSelected ? buttonDark : bgColor;
    final Color border = isSelected ? buttonDark : borderColor;
    final Color fg = isSelected ? Colors.white : textBlack;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _salesMethodIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 2. Recharge Section (USD Pricing for both Binance Pay & Telebirr)
  Widget _buildRechargeSection({
    required String sellerNumericId,
    required String sellerName,
  }) {
    return Container(
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
              _buildRechargeSubTab(0, "Official Wholesale"),
              const SizedBox(width: 10),
              _buildRechargeSubTab(1, "Senior Coin Seller"),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Select Wholesale Package (USD)",
            style: TextStyle(
                color: textBlack, fontSize: 13, fontWeight: FontWeight.bold),
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

              final Color itemBg =
                  isSelected ? const Color(0xFFE8F5E9) : bgColor;
              final Color itemBorder = isSelected ? accentGreen : borderColor;
              final double itemBorderW = isSelected ? 1.8 : 1.0;

              return GestureDetector(
                onTap: () => setState(() => _selectedRechargePackage = idx),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: itemBorder, width: itemBorderW),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${pkg['coins']} Coins",
                        style: const TextStyle(
                            color: accentGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pkg['price'].toString(),
                        style: const TextStyle(
                            color: textBlack,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pkg['tier'].toString(),
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 9.5),
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
                backgroundColor: accentGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isProcessing
                  ? null
                  : () => _openWholesaleRechargeDialog(
                        sellerNumericId: sellerNumericId,
                        sellerName: sellerName,
                      ),
              child: const Text(
                "Create Wholesale Order",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,

fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () =>
                  _showHistoryModal("Recharge Details", "coin_recharges"),
              child: const Text(
                "Recharge Details >",
                style: TextStyle(
                    color: textBlack,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeSubTab(int index, String label) {
    final bool isSelected = _rechargeSubTabIndex == index;
    final Color bg = isSelected ? buttonDark : bgColor;
    final Color border = isSelected ? buttonDark : borderColor;
    final Color fg = isSelected ? Colors.white : textBlack;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rechargeSubTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. Exchange Section (Points to Coins at 96% Agent Rate)
  Widget _buildExchangeSection(int userPoints) {
    return Container(
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
              const Text("My Agent Points",
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
              Text(
                "$userPoints Pts",
                style: const TextStyle(
                    color: accentGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Color(0xFFEFE6DE), height: 18),
          const Text(
            "Custom Exchange (96% Agent Rate)",
            style: TextStyle(
                color: textBlack, fontSize: 13, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(
                        color: textBlack, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: "e.g. 100000 Pts = 96000 Coins",
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () {

final input = int.tryParse(
                                  _customExchangeController.text.trim()) ??
                              0;
                          if (input > 0) {
                            final int coinsCalculated = (input * 0.96).floor();
                            _executePointsExchange(
                                userPoints, input, coinsCalculated);
                          }
                        },
                  child: const Text(
                    "Convert",
                    style: TextStyle(
                        color: accentGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Agent Exchange Packs (96% Rate)",
            style: TextStyle(
                color: textBlack, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._exchangePacks.map((pack) {
            final int coinsGain = pack['coins'] as int;
            final int pointsCost = pack['points'] as int;

            final VoidCallback? packAction = _isProcessing
                ? null
                : () => _executePointsExchange(userPoints, pointsCost, coinsGain);

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
                        style: const TextStyle(
                            color: accentGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 13),
                      ),
                      Text(
                        "$pointsCost Points",
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 10.5),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      elevation: 0,
                    ),
                    onPressed: packAction,
                    child: const Text("Exchange",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () =>
                  _showHistoryModal("Exchange Details", "point_exchanges"),
              child: const Text(
                "Exchange Details >",
                style: TextStyle(
                    color: textBlack,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
