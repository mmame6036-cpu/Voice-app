import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class WalletScreen extends StatefulWidget {
  final int currentCoins;
  final Function(int) onCoinsRecharged;
  final String userUid;
  final int userNumericId;

  const WalletScreen({
    super.key,
    required this.currentCoins,
    required this.onCoinsRecharged,
    required this.userUid,
    required this.userNumericId,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _activeTab = 0;
  late int _coins;
  int _points = 0;
  int _todayPoints = 0;

  int _selectedPackageIdx = 0;
  late TextEditingController _userIdController;
  bool _isProcessingPayment = false;
  StreamSubscription? _walletSub;

  final String _serverUrl = "https://nile-token-server.onrender.com";

  static const _binancePackages = [
    {"coins": 35000, "price": "\$5", "usd": 5, "bonus": "+0%"},
    {"coins": 70000, "price": "\$10", "usd": 10, "bonus": "+5%"},
    {"coins": 210000, "price": "\$30", "usd": 30, "bonus": "+8%"},
    {"coins": 350000, "price": "\$50", "usd": 50, "bonus": "+10%"},
    {"coins": 700000, "price": "\$100", "usd": 100, "bonus": "+15%"},
    {"coins": 3500000, "price": "\$500", "usd": 500, "bonus": "+25%"},
  ];

  static const _exchangeOptions = [
    {"points": 1000, "coins": 800},
    {"points": 5000, "coins": 4000},
    {"points": 10000, "coins": 8000},
    {"points": 50000, "coins": 40000},
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _userIdController =
        TextEditingController(text: widget.userNumericId.toString());
    _listenToUserWallet();
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _userIdController.dispose();
    super.dispose();
  }

  void _listenToUserWallet() {
    _walletSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userUid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      setState(() {
        _coins = (data['coins'] as num?)?.toInt() ?? _coins;
        _points = (data['points'] as num?)?.toInt() ?? 0;
        _todayPoints = (data['todayPoints'] as num?)?.toInt() ?? 0;
      });
    });
  }

  Future<void> _recordVerifiedTransaction({
    required int addedCoins,
    required String amountStr,
    required String txnId,
    required int targetNumericId,
    required bool serverAlreadyCredited,
  }) async {
    final db = FirebaseFirestore.instance;
    final txnRef = db.collection('recharge_transactions').doc(txnId);
    final existing = await txnRef.get();
    if (existing.exists) {
      return;
    }

    final batch = db.batch();

    if (!serverAlreadyCredited) {
      final userRef = db.collection('users').doc(widget.userUid);
      batch.set(
          userRef,
          {
            'coins': FieldValue.increment(addedCoins),
            'lastRechargeAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }

    batch.set(txnRef, {
      'txnId': txnId,
      'userUid': widget.userUid,
      'userNumericId': widget.userNumericId,
      'targetNumericId': targetNumericId,
      'coins': addedCoins,
      'amount': amountStr,
      'method': "Binance Pay (USDT)",
      'status': 'VERIFIED_SUCCESS',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    if (!serverAlreadyCredited) {
      widget.onCoinsRecharged(_coins + addedCoins);
    }
  }

  void _processBinancePay() {
    final pkg = _binancePackages[_selectedPackageIdx];

final int coinsToAdd = pkg["coins"] as int;
    final String priceStr = pkg["price"] as String;
    final int usdAmount = pkg["usd"] as int;
    final String targetText = _userIdController.text.trim();
    final int? targetNumericId = int.tryParse(targetText);

    if (targetNumericId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("እባክዎ ትክክለኛ የተጠቃሚ ID ያስገቡ!"),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF3BA2F), width: 1.2)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFF3BA2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.currency_bitcoin,
                  color: Colors.black, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              "Binance Pay",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recharge Account: ID $targetNumericId",
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Text("Package: 🪙 $coinsToAdd Coins",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text("Price: $priceStr (USDT)",
                style: const TextStyle(
                    color: Color(0xFFF3BA2F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: Color(0xFF00E5FF)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Secured by Binance Pay API server verification. Coins are credited only after payment confirmation.",
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3BA2F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

await _initiateServerBinanceOrder(
                coinsToAdd: coinsToAdd,
                priceStr: priceStr,
                usdAmount: usdAmount,
                targetNumericId: targetNumericId,
              );
            },
            child: const Text("Proceed to Pay",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateServerBinanceOrder({
    required int coinsToAdd,
    required String priceStr,
    required int usdAmount,
    required int targetNumericId,
  }) async {
    setState(() => _isProcessingPayment = true);
    final String txnId =
        "BNB_${widget.userNumericId}_${DateTime.now().millisecondsSinceEpoch}";

    try {
      final response = await http
          .post(
            Uri.parse("$_serverUrl/api/payment/binance-pay"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "userUid": widget.userUid,
              "userNumericId": widget.userNumericId,
              "targetNumericId": targetNumericId,
              "coins": coinsToAdd,
              "priceUsd": usdAmount,
              "txnId": txnId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception("Server returned status ${response.statusCode}");
      }

      final raw = jsonDecode(response.body);
      final Map res = raw is Map ? raw : {};

      final bool isSuccess = res['success'] == true;
      final String status = (res['status'] ?? '').toString().toUpperCase();
      final bool isVerified = res['verified'] == true;

      if (isSuccess && isVerified) {
        final bool serverCredited = res['credited'] == true;
        await _recordVerifiedTransaction(
          addedCoins: coinsToAdd,
          amountStr: priceStr,
          txnId: txnId,
          targetNumericId: targetNumericId,
          serverAlreadyCredited: serverCredited,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00C9A7),
              content: Text(
                "ክፍያው ተረጋግጧል! 🪙 $coinsToAdd Coins ገብቷል።",
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
        return;
      }

      if (status == 'PENDING') {
        final String checkoutUrl = (res['checkoutUrl'] ?? '').toString();
        final String payId = (res['binancePayId'] ?? '').toString();
        if (mounted) {
          _showPendingVerificationDialog(
            txnId: txnId,
            coinsToAdd: coinsToAdd,
            priceStr: priceStr,
            targetNumericId: targetNumericId,
            checkoutUrl: checkoutUrl,
            binancePayId: payId,
          );
        }
        return;
      }

      final String errMsg =
          (res['message'] ?? 'Payment not verified by Binance Pay').toString();
      throw Exception(errMsg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
            content: Text(
              "ክፍያው አልተረጋገጠም! እባክዎ ክፍያ መፈጸምዎን ወይም ኢንተርኔትዎን ያረጋግጡ። ($e)",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _showPendingVerificationDialog({
    required String txnId,
    required int coinsToAdd,
    required String priceStr,
    required int targetNumericId,
    required String checkoutUrl,
    required String binancePayId,
  }) {
    String paymentTarget = binancePayId;
    if (checkoutUrl.isNotEmpty) {
      paymentTarget = checkoutUrl;
    }

showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF3BA2F), width: 1.2),
        ),
        title: const Text(
          "Complete Binance Payment",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Send exact $priceStr USDT for 🪙 $coinsToAdd Coins.",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              "Order Ref: $txnId",
              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11.5),
            ),
            if (paymentTarget.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        paymentTarget,
                        style: const TextStyle(
                            color: Color(0xFFF3BA2F), fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy,
                          color: Color(0xFFF3BA2F), size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: paymentTarget));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("ኮፒ ተደርጓል!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              "After paying in Binance app, tap 'Verify Payment' below.",
              style: TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Close", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _verifyPendingBinanceOrder(
                txnId: txnId,
                coinsToAdd: coinsToAdd,
                priceStr: priceStr,
                targetNumericId: targetNumericId,
              );
            },
            child: const Text(
              "Verify Payment",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPendingBinanceOrder({
    required String txnId,
    required int coinsToAdd,
    required String priceStr,
    required int targetNumericId,
  }) async {
    setState(() => _isProcessingPayment = true);
    try {
      final response = await http
          .post(
            Uri.parse("$_serverUrl/api/payment/verify-binance-pay"),

headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "txnId": txnId,
              "userUid": widget.userUid,
              "targetNumericId": targetNumericId,
              "coins": coinsToAdd,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception("Verification failed (${response.statusCode})");
      }

      final raw = jsonDecode(response.body);
      final Map res = raw is Map ? raw : {};

      if (res['verified'] == true) {
        final bool serverCredited = res['credited'] == true;
        await _recordVerifiedTransaction(
          addedCoins: coinsToAdd,
          amountStr: priceStr,
          txnId: txnId,
          targetNumericId: targetNumericId,
          serverAlreadyCredited: serverCredited,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00C9A7),
              content: Text(
                "ክፍያው ተረጋግጧል! 🪙 $coinsToAdd Coins ወደ ዋሌትዎ ገብቷል።",
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      } else {
        throw Exception(
            (res['message'] ?? 'Payment not received yet on Binance').toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("ማረጋገጥ አልተቻለም: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _exchangePointsToCoins(int pointsCost, int coinsGain) async {
    if (_points < pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("በቂ ነጥብ (Points) የለዎትም!"),
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);
    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(widget.userUid);

      await db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final currentPts = (snap.data()?['points'] as num?)?.toInt() ?? 0;
        if (currentPts < pointsCost) {
          throw Exception("Insufficient points");
        }
        tx.update(userRef, {
          'points': FieldValue.increment(-pointsCost),
          'coins': FieldValue.increment(coinsGain),
        });
      });

      await db.collection('point_transactions').add({
        'userUid': widget.userUid,
        'userNumericId': widget.userNumericId,
        'type': 'EXCHANGE_TO_COINS',
        'points': -pointsCost,
        'coinsAdded': coinsGain,
        'createdAt': FieldValue.serverTimestamp(),
      });

      widget.onCoinsRecharged(_coins + coinsGain);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00C9A7),
            content: Text(
              "💎 $pointsCost Points ወደ 🪙 $coinsGain Coins ተቀይሯል!",
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("መቀየር አልተቻለም: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _showWithdrawDialog() {
    const int minWithdrawPoints = 100000;
    if (_points < minWithdrawPoints) {
      ScaffoldMessenger.of(context).showSnackBar(

const SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "ወጪ ለመጠየቅ ቢያንስ 100,000 Points (\$10) ያስፈልጋል!",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    String selectedMethod = "USDT (TRC20)";
    final addressController = TextEditingController();
    final pointsController =
        TextEditingController(text: minWithdrawPoints.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          String accountLabel = "Wallet Address / ID";
          if (selectedMethod == "Telebirr") {
            accountLabel = "Telebirr Phone Number";
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1638),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
            ),
            title: const Text(
              "Withdraw Points (💎)",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available: 💎 $_points Points (\$${(_points / 10000).toStringAsFixed(2)})",
                    style: const TextStyle(
                        color: Color(0xFF00E5FF), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: selectedMethod,
                    dropdownColor: const Color(0xFF261D45),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Payment Method",
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "USDT (TRC20)", child: Text("USDT (TRC20)")),
                      DropdownMenuItem(
                          value: "Telebirr", child: Text("Telebirr (ETB)")),
                      DropdownMenuItem(
                          value: "Binance ID", child: Text("Binance Pay ID")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedMethod = val.toString());
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Points Amount (Min 100,000)",
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(

controller: addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: accountLabel,
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel",
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final reqPoints =
                      int.tryParse(pointsController.text.trim()) ?? 0;
                  final account = addressController.text.trim();
                  if (reqPoints < minWithdrawPoints) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("ቢያንስ 100,000 Points ያስገቡ!")),
                    );
                    return;
                  }
                  if (reqPoints > _points) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ያለዎት ነጥብ አይበቃም!")),
                    );
                    return;
                  }
                  if (account.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("የመቀበያ አካውንት ያስገቡ!")),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  setState(() => _isProcessingPayment = true);

                  try {
                    final db = FirebaseFirestore.instance;
                    final userRef = db.collection('users').doc(widget.userUid);
                    final usdAmount = reqPoints / 10000.0;

                    await db.runTransaction((tx) async {
                      final snap = await tx.get(userRef);
                      final cur =
                          (snap.data()?['points'] as num?)?.toInt() ?? 0;
                      if (cur < reqPoints) {
                        throw Exception("Insufficient points");
                      }
                      tx.update(userRef, {
                        'points': FieldValue.increment(-reqPoints),
                      });
                    });

                    await db.collection('withdraw_requests').add({
                      'userUid': widget.userUid,
                      'userNumericId': widget.userNumericId,
                      'points': reqPoints,
                      'usdAmount': usdAmount,
                      'method': selectedMethod,
                      'account': account,
                      'status': 'PENDING',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF00C9A7),
                          content: Text(
                            "የወጪ ጥያቄዎ ተልኳል! Admin ሲያጸድቀው ይገባልዎታል።",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),

),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("ስህተት ተፈጥሯል: $e")),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isProcessingPayment = false);
                  }
                },
                child: const Text("Submit Request",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFF3BA2F);
    const diamondColor = Color(0xFF00E5FF);

    Color coinsTabBg = Colors.transparent;
    Color coinsTabText = Colors.white70;
    if (_activeTab == 0) {
      coinsTabBg = goldColor;
      coinsTabText = Colors.black;
    }

    Color pointsTabBg = Colors.transparent;
    Color pointsTabText = Colors.white70;
    if (_activeTab == 1) {
      pointsTabBg = diamondColor;
      pointsTabText = Colors.black;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18122B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context, _coins),
        ),
        title: const Text(
          "NILE Live Wallet",
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF18122B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: coinsTabBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "🪙 Coins ($_coins)",
                              style: TextStyle(
                                color: coinsTabText,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: pointsTabBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(

"💎 Points ($_points)",
                              style: TextStyle(
                                color: pointsTabText,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _activeTab == 0
                    ? _buildCoinsTab(goldColor)
                    : _buildPointsTab(diamondColor),
              ),
            ],
          ),
          if (_isProcessingPayment)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: goldColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoinsTab(Color brandColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF281E4B), Color(0xFF130E26)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Available Coins",
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text("🪙", style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          "$_coins",
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "ID: ${widget.userNumericId}",
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Recharge Target User ID",
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),

),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1638),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Target confirmed: ${_userIdController.text}")),
                    );
                  },
                  child: Text(
                    "Confirm",
                    style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1638),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandColor.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: brandColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.currency_bitcoin,
                      color: Colors.black, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Binance Pay (Verified Crypto)",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      Text(
                        "Settlement in USDT • Instant Server Verification",
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.verified, color: brandColor, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Select Package",
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _binancePackages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,

mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, idx) {
              final pkg = _binancePackages[idx];
              final isSelected = _selectedPackageIdx == idx;

              Color cardBg = const Color(0xFF1E1638);
              Color borderCol = Colors.white12;
              double borderW = 1.0;
              if (isSelected) {
                cardBg = const Color(0xFF261D45);
                borderCol = brandColor;
                borderW = 1.8;
              }

              return GestureDetector(
                onTap: () => setState(() => _selectedPackageIdx = idx),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderCol,
                      width: borderW,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("🪙", style: TextStyle(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text(
                              "${pkg['coins']}",
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${pkg['price']} USDT",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: brandColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pkg['bonus'] != "+0%")
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2A85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${pkg['bonus']}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _isProcessingPayment ? null : _processBinancePay,

child: Text(
                "Pay with Binance (${_binancePackages[_selectedPackageIdx]['price']} USDT)",
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPointsTab(Color diamondColor) {
    final double usdValue = _points / 10000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E3954), Color(0xFF130E26)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: diamondColor.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("My Earned Points",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: diamondColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "≈ \$${usdValue.toStringAsFixed(2)} USD",
                        style: TextStyle(
                          color: diamondColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("💎", style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 8),
                    Text(
                      "$_points",
                      style: TextStyle(
                        color: diamondColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Points: 💎 $_todayPoints",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Text(
                      "10,000 Pts = \$1",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: diamondColor,
                foregroundColor: Colors.black,

shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showWithdrawDialog,
              icon: const Icon(Icons.account_balance_wallet, size: 20),
              label: const Text(
                "Withdraw Cash (Min 100,000 Points)",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            "Exchange Points to Coins (Instant)",
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exchangeOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (context, idx) {
              final opt = _exchangeOptions[idx];
              final pts = opt["points"]!;
              final cns = opt["coins"]!;

              return GestureDetector(
                onTap: () => _exchangePointsToCoins(pts, cns),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1638),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "🪙 $cns Coins",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Use 💎 $pts Pts",
                        style: TextStyle(
                          color: diamondColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          const Text(
            "Recent Points Activity",
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('point_transactions')
                .where('userUid', isEqualTo: widget.userUid)
                .orderBy('createdAt', descending: true)
                .limit(15)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text("Loading points history...",
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                );
              }
              if (snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final QuerySnapshot qSnap = snapshot.data as QuerySnapshot;

final docs = qSnap.docs;
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18122B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "No points received yet. Go live in a voice room to earn!",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final raw = docs[i].data();
                  final Map d = raw is Map ? raw : {};
                  final int pts = (d['points'] as num?)?.toInt() ?? 0;
                  final String type =
                      (d['type'] ?? 'GIFT_RECEIVED').toString();
                  String titleText = "Gift Received in Room";
                  if (type == 'EXCHANGE_TO_COINS') {
                    titleText = "Exchanged to Coins";
                  }
                  String ptsLabel = "+💎 $pts";
                  Color ptsColor = const Color(0xFF00E5FF);
                  if (pts < 0) {
                    ptsLabel = "💎 $pts";
                    ptsColor = Colors.orangeAccent;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18122B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          titleText,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                        Text(
                          ptsLabel,
                          style: TextStyle(
                            color: ptsColor,
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
        ],
      ),
    );
  }
}
