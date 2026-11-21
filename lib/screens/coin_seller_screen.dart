import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

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
  static const String _serverUrl = "https://nile-token-server.onrender.com";

  static const Color bgColor = Color(0xFFF5F7F9);
  static const Color cardBg = Colors.white;
  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color buttonDark = Color(0xFF14B8A6);

  final List _rechargePackages = const [
    {"coins": 1980000, "usd": 200, "price": "\$200", "tier": "Standard Seller"},
    {"coins": 9900000, "usd": 1000, "price": "\$1000", "tier": "Standard Seller"},
    {"coins": 14850000, "usd": 1500, "price": "\$1500", "tier": "Standard Seller"},
    {"coins": 30000000, "usd": 3000, "price": "\$3000", "tier": "Senior Seller"},
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

  Map _toMap(dynamic raw) {
    if (raw is Map) {
      return Map.from(raw);
    }
    return {};
  }

  String _readStr(Map m, String key) {
    final val = m[key];
    if (val == null) return "";
    return val.toString().trim();
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
        backgroundColor: const Color(0xFF1F2937),
        duration: const Duration(seconds: 2),
      ),
    );
  }

bool _checkUserMapIsAgent(Map data) {
    final String role = _readStr(data, 'role').toLowerCase();
    if (data['isAgent'] == true) return true;
    if (data['isCoinSeller'] == true) return true;
    if (const ['agent', 'agency', 'coinseller'].contains(role)) return true;
    if (_readStr(data, 'agencyId').isNotEmpty) return true;
    if (_readStr(data, 'agencyName').isNotEmpty) return true;
    return false;
  }

  Future _verifyAgencyOwnership(String numericIdStr) async {
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

  String _resolveSellerLevel(int totalCoinsSold, int maxSingleRechargeUsd) {
    if (totalCoinsSold >= 30000000 || maxSingleRechargeUsd >= 3000) {
      return "Senior Seller";
    }
    if (totalCoinsSold >= 2000000 || maxSingleRechargeUsd >= 200) {
      return "Standard Seller";
    }
    return "Beginner Seller";
  }

  void _showSellerLevelDialog(int totalCoinsSold, String currentLevel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: accentGold, size: 24),
            SizedBox(width: 8),
            Text(
              "Coin Seller Levels",
              style: TextStyle(
                  color: textBlack, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current level: $currentLevel",
              style: const TextStyle(
                  color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              "Total Coins Sold: $totalCoinsSold Coins",
              style: const TextStyle(color: Colors.black87, fontSize: 12),
            ),
            const Divider(height: 20),
            const Text(
              "• Beginner Seller: 1\$ = 9.8K Coins\n"
              "• Standard Seller: 1\$ = 9.9K Coins (Single recharge >= \$200)\n"
              "• Senior Seller: 1\$ = 10K Coins (Single recharge >= \$3000)",
              style: TextStyle(color: textBlack, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
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

  Future _verifyReceiver() async {
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
        final Map data = _toMap(query.docs.first.data());
        String foundName = "Verified User";
        final String nameVal = _readStr(data, 'name');
        final String dispVal = _readStr(data, 'displayName');
        if (nameVal.isNotEmpty) {
          foundName = nameVal;
        } else if (dispVal.isNotEmpty) {
          foundName = dispVal;
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

  Future _executeCoinTransfer({
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

      final Map receiverMap = _toMap(receiverDoc.data());
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
        final Map sellerMap = _toMap(sellerSnap.data());
        final int currentCoins = (sellerMap['coins'] as num?)?.toInt() ?? 0;
        final int prevSold = (sellerMap['totalCoinsSold'] as num?)?.toInt() ?? 0;
        final int maxRecharge =
            (sellerMap['maxSingleRechargeUsd'] as num?)?.toInt() ?? 0;

        if (currentCoins < amountInput) {
          throw Exception("Insufficient balance.");
        }

        final int newTotalSold = prevSold + amountInput;
        final String newLevel = _resolveSellerLevel(newTotalSold, maxRecharge);

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

  // Create Binance-Only Wholesale Order & Open Dedicated Binance Checkout Page
  Future _startBinanceWholesaleOrder({
    required String sellerNumericId,
    required String sellerName,
  }) async {
    if (_isProcessing) return;
    final user = _currentUser;
    if (user == null) return;

    final pkg = _rechargePackages[_selectedRechargePackage] as Map;
    final int coinsToReceive = pkg['coins'] as int;
    final int usdCost = pkg['usd'] as int;
    final String priceLabel = pkg['price'].toString();

    final String channelType =
        _rechargeSubTabIndex == 1 ? "Coin Seller" : "Official";
    final now = DateTime.now();
    final String dateStamp =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    String orderId = "$dateStamp$sellerNumericId${now.millisecond.toString().padLeft(4, '0')}";
    String binancePayId = officialBinancePayId;
    String checkoutUrl = "";

    setState(() => _isProcessing = true);

    try {
      // Attempt server order creation for automated Binance verification
      try {
        final int targetNumId = int.tryParse(sellerNumericId) ?? 0;
        final response = await http
            .post(
              Uri.parse("$_serverUrl/api/create-order"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({

"uid": user.uid,
                "userUid": user.uid,
                "numericId": targetNumId,
                "userNumericId": targetNumId,
                "targetNumericId": targetNumId,
                "coins": coinsToReceive,
                "usdAmount": usdCost,
                "amount": usdCost,
                "priceUsd": usdCost,
                "isWholesaleSeller": true,
              }),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final raw = jsonDecode(response.body);
          if (raw is Map) {
            final String srvRef = (raw['orderRef'] ?? '').toString().trim();
            if (srvRef.isNotEmpty) {
              orderId = srvRef;
            }
            final String srvPayId =
                (raw['binancePayId'] ?? '').toString().trim();
            if (srvPayId.isNotEmpty) {
              binancePayId = srvPayId;
            }
            checkoutUrl = (raw['checkoutUrl'] ?? '').toString().trim();
          }
        }
      } catch (_) {}

      await FirebaseFirestore.instance
          .collection('coin_recharges')
          .doc(orderId)
          .set({
        'orderRef': orderId,
        'uid': user.uid,
        'sellerNumericId': sellerNumericId,
        'sellerName': sellerName,
        'channelType': channelType,
        'paymentMethod': 'Binance Pay (USDT)',
        'currency': 'USDT',
        'coins': coinsToReceive,
        'usdAmount': usdCost,
        'credited': false,
        'status': 'PENDING',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _BinanceCheckoutScreen(
            userUid: user.uid,
            userNumericId: sellerNumericId,
            orderId: orderId,
            coins: coinsToReceive,
            usdAmount: usdCost,
            priceLabel: priceLabel,
            binancePayId: binancePayId,
            checkoutUrl: checkoutUrl,
            serverUrl: _serverUrl,
          ),
        ),
      );
    } catch (e) {
      _showToast("Failed to create Binance order: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future _executePointsExchange(
      int userPoints, int pointsCost, int coinsGain) async {
    final user = _currentUser;
    if (user == null) return;
    if (pointsCost <= 0 || coinsGain <= 0) return;

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
        final Map data = _toMap(snap.data());
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
      _showToast(
          "Exchanged $pointsCost Points for $coinsGain Coins (96% Agent Rate)!");
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
                  if (!snapshot.hasData || snapshot.data == null) {
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
                    final Map mapA = _toMap(a.data());
                    final Map mapB = _toMap(b.data());
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
                      final Map item = _toMap(docs[idx].data());

                      String headerTitle = "Agent Exchange (96%)";
                      if (item['salesMethod'] != null) {
                        headerTitle = "Transfer (${item['salesMethod']})";
                      } else if (item['orderRef'] != null) {
                        final String st = (item['status'] ?? 'PENDING').toString();
                        headerTitle = "Binance Recharge ($st)";
                      }

                      String subInfo = "";
                      if (item['receiverId'] != null) {
                        subInfo = "To ID: ${item['receiverId']}";
                      } else if (item['orderRef'] != null) {
                        subInfo =
                            "Order: ${item['orderRef']} (\$${item['usdAmount']} USDT)";
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
                                color: primaryTeal,
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
        backgroundColor: cardBg,
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
            fillColor: bgColor,
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
              backgroundColor: primaryTeal,
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
                "Coin Seller is exclusively available for verified Agents. Hosts and regular users cannot access this section.",
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
                    backgroundColor: primaryTeal,
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
        backgroundColor: cardBg,
        elevation: 0.4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Coin Seller",
          style: TextStyle(
            color: textBlack,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded,
                color: Colors.black54, size: 22),
            onPressed: () => _showSellerLevelDialog(0, "Beginner Seller"),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: primaryTeal),
            );
          }

          final docSnap = snapshot.data as DocumentSnapshot;
          final Map userData = docSnap.exists ? _toMap(docSnap.data()) : {};

          String numericId = "100000";
          final String numStr = _readStr(userData, 'numericId');
          final String idStr = _readStr(userData, 'id');
          if (numStr.isNotEmpty) {
            numericId = numStr;
          } else if (idStr.isNotEmpty) {
            numericId = idStr;
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
          final String agName = _readStr(userData, 'agencyName');
          final String uName = _readStr(userData, 'name');
          final String dName = _readStr(userData, 'displayName');
          if (agName.isNotEmpty) {
            name = agName;
          } else if (uName.isNotEmpty) {
            name = uName;
          } else if (dName.isNotEmpty) {
            name = dName;
          }

          final int coins = (userData['coins'] as num?)?.toInt() ?? 0;
          final int points = (userData['points'] as num?)?.toInt() ?? 0;
          final int totalCoinsSold =
              (userData['totalCoinsSold'] as num?)?.toInt() ?? 0;
          final int maxSingleRechargeUsd =
              (userData['maxSingleRechargeUsd'] as num?)?.toInt() ?? 0;
          final String currentLevel =
              _resolveSellerLevel(totalCoinsSold, maxSingleRechargeUsd);

          String sellerGreeting = "Thank you for buying from NILE Live!";
          final String customGreet = _readStr(userData, 'sellerGreeting');
          if (customGreet.isNotEmpty) {
            sellerGreeting = customGreet;
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              // 1. Agent Profile Card (Matches Video Header)

Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentGold, width: 2),
                          ),
                          child: const Icon(Icons.storefront,
                              color: accentGold, size: 26),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "ID:$numericId",
                                      style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _copyToClipboard(numericId),
                                      child: const Icon(Icons.copy_rounded,
                                          size: 13, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showSellerLevelDialog(
                              totalCoinsSold, currentLevel),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: primaryTeal,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(

"Level Up",
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
                    const Divider(color: Color(0xFFF3F4F6), height: 22),
                    Row(
                      children: [
                        const Text(
                          "Current level: ",
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        Text(
                          currentLevel,
                          style: const TextStyle(
                            color: textBlack,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Balance & Binance-Only Payment Method Card
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
                          style: TextStyle(
                              color: textBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                        GestureDetector(
                          onTap: () => _showHistoryModal(
                              "Transfer History", "coin_transfers"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accentGold),
                            ),
                            child: const Text(
                              "Details",
                              style: TextStyle(
                                  color: accentGold,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            color: accentGold, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: textBlack,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 22),

Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded,
                                color: Color(0xFFFF7043), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Payment Method",
                              style: TextStyle(
                                  color: textBlack,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF3BA2F)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.currency_bitcoin,
                                  color: Color(0xFFF3BA2F), size: 16),
                              SizedBox(width: 4),
                              Text(
                                "Binance Only",
                                style: TextStyle(
                                  color: textBlack,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Tab Structure (Transfer, Recharge, Exchange)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryTeal,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.black54),
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
          color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
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
                      color: primaryTeal,
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
                      : primaryTeal,
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
                  color: primaryTeal, fontWeight: FontWeight.bold),
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
                backgroundColor: primaryTeal,
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
    final Color bg = isSelected ? primaryTeal : bgColor;
    final Color border = isSelected ? primaryTeal : borderColor;
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

  // 2. Recharge Section (Binance ONLY + Video Package Grid + Recharge Rules)
  Widget _buildRechargeSection({
    required String sellerNumericId,
    required String sellerName,
  }) {
    return Column(
      children: [
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
                children: [
                  _buildRechargeSubTab(0, "Official"),
                  const SizedBox(width: 10),
                  _buildRechargeSubTab(1, "Coin Seller"),
                ],
              ),
              const SizedBox(height: 14),

              // Binance Only Payment Method Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card_rounded,
                            color: Color(0xFF0284C7), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Payment Method",
                          style: TextStyle(
                              color: textBlack,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: Color(0xFFF3BA2F),
                          child: Icon(Icons.currency_bitcoin,
                              color: Colors.white, size: 15),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Binance",
                          style: TextStyle(
                              color: textBlack,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rechargePackages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,

childAspectRatio: 1.55,
                ),
                itemBuilder: (context, idx) {
                  final pkg = _rechargePackages[idx] as Map;
                  final isSelected = _selectedRechargePackage == idx;
                  final String tierTag = pkg['tier'].toString();
                  final bool isSenior = tierTag.contains("Senior");

                  return GestureDetector(
                    onTap: () => setState(() => _selectedRechargePackage = idx),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE6FFFA)
                                : bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryTeal : borderColor,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.monetization_on,
                                      color: accentGold, size: 16),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _formatCoins(pkg['coins'] as int),
                                      style: const TextStyle(
                                          color: textBlack,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pkg['price'].toString(),
                                style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSenior
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFE11D48),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(11),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              tierTag,
                              style: const TextStyle(

color: Colors.white,
                                fontSize: 9.5,
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isProcessing
                      ? null
                      : () => _startBinanceWholesaleOrder(
                            sellerNumericId: sellerNumericId,
                            sellerName: sellerName,
                          ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "Recharge",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
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
                        color: primaryTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Recharge Rules Table (Matches Video)
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
              const Text(
                "Recharge Rules",
                style: TextStyle(
                  color: textBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Seller Level",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                    ),

Expanded(
                      flex: 3,
                      child: Text(
                        "Proportion",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "Level Requirement",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              _buildRuleRow("Beginner", "9.8K", "Single recharge\n-"),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _buildRuleRow("Standard", "9.9K", "Single recharge\n≥ \$ 200"),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _buildRuleRow("Senior", "10K", "Single recharge\n≥ \$ 3000"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleRow(String level, String coinsPerDollar, String reqText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              level,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textBlack),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("1\$ = ",
                    style: TextStyle(fontSize: 12, color: textBlack)),
                const Icon(Icons.monetization_on,
                    color: accentGold, size: 14),
                Text(
                  coinsPerDollar,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textBlack),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              reqText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5, color: Colors.black87, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoins(int num) {
    final s = num.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buf.write(',');
      }
    }
    return buf.toString().split('').reversed.join();
  }

  Widget _buildRechargeSubTab(int index, String label) {
    final bool isSelected = _rechargeSubTabIndex == index;
    final Color bg = isSelected ? primaryTeal : bgColor;
    final Color border = isSelected ? primaryTeal : borderColor;
    final Color fg = isSelected ? Colors.white : textBlack;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rechargeSubTabIndex = index),
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
          const Divider(color: Color(0xFFF3F4F6), height: 18),
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
                        color: primaryTeal, fontWeight: FontWeight.bold),
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
                            color: primaryTeal,
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
                      backgroundColor: primaryTeal,
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

// ============================================================================
// DEDICATED BINANCE CHECKOUT SCREEN (Matches Video + Strict Payment Verify)
// ============================================================================
class _BinanceCheckoutScreen extends StatefulWidget {
  final String userUid;
  final String userNumericId;
  final String orderId;
  final int coins;
  final int usdAmount;
  final String priceLabel;
  final String binancePayId;
  final String checkoutUrl;
  final String serverUrl;

  const _BinanceCheckoutScreen({
    required this.userUid,
    required this.userNumericId,
    required this.orderId,
    required this.coins,
    required this.usdAmount,
    required this.priceLabel,
    required this.binancePayId,
    required this.checkoutUrl,
    required this.serverUrl,
  });

  @override
  State<_BinanceCheckoutScreen> createState() => _BinanceCheckoutScreenState();
}

class _BinanceCheckoutScreenState extends State<_BinanceCheckoutScreen>
    with WidgetsBindingObserver {
  bool _awaitingBinanceReturn = false;
  bool _isCheckingVerification = false;
  bool _orderCompleted = false;
  StreamSubscription? _orderDocSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToOrderStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orderDocSub?.cancel();
    super.dispose();
  }

// Real-time listener: If Admin or Binance Webhook marks order PAID, confirm immediately
  void _listenToOrderStatus() {
    _orderDocSub = FirebaseFirestore.instance
        .collection('coin_recharges')
        .doc(widget.orderId)
        .snapshots()
        .listen((doc) async {
      if (!mounted  _orderCompleted  !doc.exists || doc.data() == null) {
        return;
      }
      final data = doc.data()!;
      final String status = (data['status'] ?? '').toString().toUpperCase();
      final bool isPaid = status == 'VERIFIED_SUCCESS' ||
          status == 'PAID' ||
          status == 'APPROVED' ||
          status == 'COMPLETED';

      if (isPaid) {
        await _finalizePaidOrder(alreadyCreditedByServer: data['credited'] == true);
      }
    }, onError: (_) {});
  }

  // Auto-detect when user switches back from Binance app to NILE Live
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _awaitingBinanceReturn &&
        !_orderCompleted) {
      _verifyWithServerAndFirestore(fromAutoReturn: true);
    }
  }

  void _onPayNowPressed() {
    final String copyTarget = widget.checkoutUrl.isNotEmpty
        ? widget.checkoutUrl
        : widget.binancePayId;

    Clipboard.setData(ClipboardData(text: copyTarget));
    setState(() {
      _awaitingBinanceReturn = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F2937),
        duration: const Duration(seconds: 4),
        content: Text(
          "Binance Pay ID (${widget.binancePayId}) copied! Open Binance app to send ${widget.priceLabel} USDT, then return here.",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future _verifyWithServerAndFirestore({bool fromAutoReturn = false}) async {
    if (_isCheckingVerification || _orderCompleted) return;
    setState(() => _isCheckingVerification = true);

    bool isVerifiedPaid = false;
    bool serverCredited = false;

    try {
      // 1. Query Server Verification Endpoint
      final response = await http
          .post(
            Uri.parse("${widget.serverUrl}/api/verify-payment"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "orderRef": widget.orderId,
              "txnId": widget.orderId,
              "userUid": widget.userUid,
              "targetNumericId": int.tryParse(widget.userNumericId) ?? 0,
              "coins": widget.coins,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        if (raw is Map && raw['verified'] == true) {
          isVerifiedPaid = true;
          serverCredited = true;
        }
      }

      // 2. Also check Firestore document status in case Admin approved directly
      if (!isVerifiedPaid) {
        final docSnap = await FirebaseFirestore.instance
            .collection('coin_recharges')
            .doc(widget.orderId)
            .get();
        if (docSnap.exists && docSnap.data() != null) {
          final data = docSnap.data()!;
          final String status =
              (data['status'] ?? '').toString().toUpperCase();
          if (status == 'VERIFIED_SUCCESS' ||
              status == 'PAID' ||
              status == 'APPROVED' ||
              status == 'COMPLETED') {
            isVerifiedPaid = true;
            serverCredited = data['credited'] == true;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isCheckingVerification = false);

    // STRICT RULE: If NOT paid, NEVER show the final Order Confirmation / OK dialog!
    if (!isVerifiedPaid) {

ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF374151),
          content: Text(
            "Payment not received yet. Complete your USDT payment in Binance first.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    await _finalizePaidOrder(alreadyCreditedByServer: serverCredited);
  }

  Future _finalizePaidOrder({required bool alreadyCreditedByServer}) async {
    if (_orderCompleted) return;
    _orderCompleted = true;

    try {
      final db = FirebaseFirestore.instance;
      final orderRef = db.collection('coin_recharges').doc(widget.orderId);
      final userRef = db.collection('users').doc(widget.userUid);

      await db.runTransaction((tx) async {
        final orderSnap = await tx.get(orderRef);
        final orderData = orderSnap.data() ?? {};
        if (orderData['credited'] == true) return;

        tx.set(
          orderRef,
          {
            'status': 'VERIFIED_SUCCESS',
            'credited': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (!alreadyCreditedByServer) {
          final userSnap = await tx.get(userRef);
          final uData = userSnap.data() ?? {};
          final int prevMax =
              (uData['maxSingleRechargeUsd'] as num?)?.toInt() ?? 0;
          final int newMax =
              widget.usdAmount > prevMax ? widget.usdAmount : prevMax;

          tx.set(
            userRef,
            {
              'coins': FieldValue.increment(widget.coins),
              'maxSingleRechargeUsd': newMax,
              'lastRechargeAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });
    } catch (_) {}

    if (!mounted) return;

    // Final Order Confirmation Dialog with OK button (ONLY shown after verified payment)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF14B8A6), size: 26),
            SizedBox(width: 8),
            Text(
              "Order Confirmed",
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 17,
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
              "Payment of ${widget.priceLabel} USDT verified via Binance.",
              style: const TextStyle(color: Colors.black87, fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            Text(
              "Added: +${widget.coins} Coins",
              style: const TextStyle(
                color: Color(0xFF14B8A6),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Order ID: ${widget.orderId}",
              style: const TextStyle(color: Colors.black54, fontSize: 11.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Binance",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFFF3BA2F),
                    child: Icon(Icons.currency_bitcoin,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Binance",
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Pay ${widget.priceLabel} USDT (${widget.coins} Coins)",
                    style: const TextStyle(
                      color: Color(0xFF14B8A6),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // QR / Binance Pay ID Frame (Matches Video Layout)
                  Container(
                    width: 210,
                    height: 210,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFD1D5DB), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            size: 96, color: Color(0xFF1F2937)),
                        const SizedBox(height: 8),
                        const Text(
                          "Binance Pay ID",
                          style: TextStyle(
                              color: Colors.black54, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(

ClipboardData(text: widget.binancePayId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Binance Pay ID copied!")),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.binancePayId,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy,
                                  size: 14, color: Color(0xFF14B8A6)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  const Text(
                    "Order ID",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.orderId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Order ID copied!")),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.orderId,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_rounded,
                            size: 15, color: Colors.black54),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "User ID",
                    style: TextStyle(color: Colors.black54, fontSize: 13.5),
                  ),
                  Text(
                    widget.userNumericId,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (_awaitingBinanceReturn) ...[
              SizedBox(
                width: double.infinity,

height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _isCheckingVerification
                      ? null
                      : () => _verifyWithServerAndFirestore(),
                  child: _isCheckingVerification
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF14B8A6)),
                        )
                      : const Text(
                          "Verify Payment Status",
                          style: TextStyle(
                            color: Color(0xFF14B8A6),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _onPayNowPressed,
                child: const Text(
                  "Pay Now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
