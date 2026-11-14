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
  int _activeTab = 0; // 0 = Coins Wallet, 1 = Points Wallet
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

  // በሰርቨር የተረጋገጠ ግብይት ብቻ መዝግቦ ሳንቲም መጨመሪያ
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
      return; // ተመሳሳይ txnId በድጋሚ እንዳይቆጠር
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

// የ Binance Pay ክፍያ ሂደት (ያለ ሰርቨር ማረጋገጫ ሳንቲም አይጨምርም)
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
    final String paymentTarget =
        checkoutUrl.isNotEmpty ? checkoutUrl : binancePayId;

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
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1638),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
          ),
          title: const Text(
            "Withdraw Points (💎)",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Available: 💎 $_points Points (\$${(_points / 10000).toStringAsFixed(2)})",
                  style:
                      const TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
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
                      setDialogState(() => selectedMethod = val);
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
                    labelText: selectedMethod == "Telebirr"
