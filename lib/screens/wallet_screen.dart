import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  int _selectedPayMethod = 0; // 0 = Binance Pay, 1 = USDT (TRC20)
  String _selectedCountry = "All country";
  late TextEditingController _userIdController;
  bool _isProcessingPayment = false;
  StreamSubscription? _walletSub;

  final String _serverUrl = "https://nile-token-server.onrender.com";

  static const Color kPageBg = Color(0xFFF6F7F9);
  static const Color kCardWhite = Color(0xFFFFFFFF);
  static const Color kInputFill = Color(0xFFEDEEF2);
  static const Color kTextDark = Color(0xFF1F2329);
  static const Color kTextMuted = Color(0xFF7A818E);
  static const Color kTealAccent = Color(0xFF00BFA5);
  static const Color kPriceCoral = Color(0xFFE85A3C);
  static const Color kGoldCoin = Color(0xFFF3BA2F);

  static const _binancePackages = [
    {"coins": 35000, "label": "35,000", "price": "\$5", "usd": 5, "bonus": "+0%"},
    {"coins": 70000, "label": "70,000", "price": "\$10", "usd": 10, "bonus": "+5%"},
    {"coins": 210000, "label": "210,000", "price": "\$30", "usd": 30, "bonus": "+8%"},
    {"coins": 350000, "label": "350,000", "price": "\$50", "usd": 50, "bonus": "+10%"},
    {"coins": 700000, "label": "700,000", "price": "\$100", "usd": 100, "bonus": "+15%"},
    {"coins": 3500000, "label": "3,500,000", "price": "\$500", "usd": 500, "bonus": "+25%"},
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
    required String orderRef,
    required int targetNumericId,
    required bool serverAlreadyCredited,
  }) async {
    final db = FirebaseFirestore.instance;
    final txnRef = db.collection('recharge_transactions').doc(orderRef);
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
      'txnId': orderRef,
      'orderRef': orderRef,
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
          content: Text("Please enter a valid numeric User ID!"),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kTealAccent, width: 1.4),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: kGoldCoin,
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
                  color: kTextDark),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recharge Account: ID $targetNumericId",
                style: const TextStyle(color: kTextMuted, fontSize: 13)),
            const SizedBox(height: 10),
            Text("Package: 🪙 $coinsToAdd Coins",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kTextDark)),
            const SizedBox(height: 4),
            Text("Price: $priceStr (USDT)",
                style: const TextStyle(
                    color: kPriceCoral,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPageBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: kTealAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Secured by Binance Pay server verification. Coins are credited after admin payment confirmation.",
                      style: TextStyle(fontSize: 11, color: kTextMuted),
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

child: const Text("Cancel", style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kTealAccent,
              foregroundColor: Colors.white,
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

    final String effectiveUid =
        targetNumericId == widget.userNumericId ? widget.userUid : "";

    try {
      final response = await http
          .post(
            Uri.parse("$_serverUrl/api/create-order"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "uid": effectiveUid,
              "userUid": effectiveUid,
              "numericId": targetNumericId,
              "userNumericId": widget.userNumericId,
              "targetNumericId": targetNumericId,
              "coins": coinsToAdd,
              "usdAmount": usdAmount,
              "amount": usdAmount,
              "priceUsd": usdAmount,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw Exception("Server returned status ${response.statusCode}");
      }

      final raw = jsonDecode(response.body);
      final Map res = raw is Map ? raw : {};

      final bool isSuccess = res['success'] == true;
      final String status = (res['status'] ?? '').toString().toUpperCase();
      final bool isVerified = res['verified'] == true;
      final String serverOrderRef = (res['orderRef'] ?? '').toString();

      if (isSuccess && isVerified && serverOrderRef.isNotEmpty) {
        await _recordVerifiedTransaction(
          addedCoins: coinsToAdd,
          amountStr: priceStr,
          orderRef: serverOrderRef,
          targetNumericId: targetNumericId,
          serverAlreadyCredited: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: kTealAccent,
              content: Text(
                "Payment verified! 🪙 $coinsToAdd Coins credited.",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
        return;
      }

      if (isSuccess && status == 'PENDING' && serverOrderRef.isNotEmpty) {
        final String checkoutUrl = (res['checkoutUrl'] ?? '').toString();
        final String payId =
            (res['binancePayId'] ?? '1059643208').toString();
        if (mounted) {
          _showPendingVerificationDialog(
            orderRef: serverOrderRef,
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
          (res['error'] ?? res['message'] ?? 'Order creation failed').toString();

throw Exception(errMsg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
            content: Text(
              "Order could not be created. Check internet connection and try again. ($e)",
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
    required String orderRef,
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

    final TextEditingController txIdCtrl = TextEditingController();
    final ImagePicker picker = ImagePicker();
    String screenshotBase64 = "";
    String screenshotName = "";
    bool isSubmittingProof = false;
    bool proofSent = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: kCardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: kTealAccent, width: 1.4),
          ),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  "Complete Binance Payment",
                  style: TextStyle(
                      color: kTextDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5),
                ),
              ),
              if (proofSent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Sent",
                    style: TextStyle(
                        color: kTealAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Send exact $priceStr USDT for 🪙 $coinsToAdd Coins.",
                  style: const TextStyle(color: kTextMuted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  "Order Ref: $orderRef",
                  style: const TextStyle(
                      color: kTealAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold),
                ),
                if (paymentTarget.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPageBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPayMethod == 1
                                    ? "USDT (TRC20) / Binance Pay ID:"
                                    : "Binance Pay ID:",
                                style: const TextStyle(
                                    color: kTextMuted, fontSize: 10),
                              ),
                              Text(
                                paymentTarget,
                                style: const TextStyle(
                                    color: kTextDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy,
                              color: kTealAccent, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: paymentTarget));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Copied to clipboard!")),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  "Submit Payment Proof to Dashboard",
                  style: TextStyle(
                      color: kTextDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: txIdCtrl,
                  style: const TextStyle(color: kTextDark, fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: "Enter Binance Order ID / TxID",
                    hintStyle:
                        const TextStyle(color: kTextMuted, fontSize: 11.5),
                    filled: true,
                    fillColor: kPageBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    try {
                      final XFile? picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 900,
                        maxHeight: 900,
                        imageQuality: 72,
                      );
                      if (picked == null) return;
                      final Uint8List bytes = await picked.readAsBytes();
                      if (bytes.length > 850000) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Image too large. Pick a smaller screenshot.")),
                          );
                        }
                        return;
                      }
                      setDlgState(() {
                        screenshotBase64 =
                            "data:image/jpeg;base64,${base64Encode(bytes)}";
                        screenshotName = picked.name;
                      });
                    } catch (_) {}
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: kPageBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: screenshotBase64.isNotEmpty
                            ? kTealAccent
                            : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          screenshotBase64.isNotEmpty
                              ? Icons.check_circle
                              : Icons.add_photo_alternate_outlined,
                          color: kTealAccent,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            screenshotBase64.isNotEmpty
                                ? "Screenshot: $screenshotName"
                                : "Upload Payment Screenshot",
                            style: TextStyle(
                              color: screenshotBase64.isNotEmpty
                                  ? kTealAccent
                                  : kTextDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTextDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSubmittingProof
                        ? null
                        : () async {
                            final String tx = txIdCtrl.text.trim();
                            if (tx.isEmpty && screenshotBase64.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text(
                                      "Enter TxID or upload payment screenshot first."),
                                ),
                              );
                              return;
                            }
                            setDlgState(() => isSubmittingProof = true);
                            try {
                              final db = FirebaseFirestore.instance;
                              final String refUsed =
                                  tx.isNotEmpty ? tx : orderRef;
                              final Map<String, dynamic> proofPayload = {
                                'orderRef': orderRef,
                                'orderId': orderRef,
                                'uid': widget.userUid,
                                'userUid': widget.userUid,
                                'userNumericId': widget.userNumericId,
                                'targetNumericId': targetNumericId,
                                'numericId': targetNumericId,
                                'coins': coinsToAdd,
                                'amount': priceStr,
                                'usdAmount': int.tryParse(priceStr
                                        .replaceAll(RegExp(r'[^0-9]'), '')) ??
                                    0,
                                'paymentMethod': _selectedPayMethod == 1
                                    ? 'USDT (TRC20)'
                                    : 'Binance Pay (USDT)',
                                'binanceTxId': refUsed,
                                'transactionId': refUsed,
                                'proofScreenshot': screenshotBase64,
                                'screenshotUrl': screenshotBase64,
                                'status': 'PROOF_SUBMITTED',
                                'credited': false,
                                'proofSubmittedAt':
                                    FieldValue.serverTimestamp(),
                                'timestamp': FieldValue.serverTimestamp(),
                              };

                              final batch = db.batch();
                              batch.set(
                                  db
                                      .collection('recharge_orders')
                                      .doc(orderRef),
                                  proofPayload,
                                  SetOptions(merge: true));
                              batch.set(
                                  db
                                      .collection('recharge_requests')
                                      .doc(orderRef),
                                  proofPayload,
                                  SetOptions(merge: true));
                              await batch.commit();

                              setDlgState(() {
                                isSubmittingProof = false;
                                proofSent = true;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: kTealAccent,
                                    content: Text(
                                      "Proof sent to Admin Dashboard!",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setDlgState(() => isSubmittingProof = false);
                            }
                          },
                    icon: const Icon(Icons.send_rounded, size: 15),
                    label: Text(
                      proofSent
                          ? "Update Proof on Dashboard"
                          : "Send Proof to Dashboard",
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close", style: TextStyle(color: kTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTealAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _verifyPendingBinanceOrder(
                  orderRef: orderRef,
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
      ),
    );
  }

  Future<void> _verifyPendingBinanceOrder({
    required String orderRef,
    required int coinsToAdd,
    required String priceStr,
    required int targetNumericId,
  }) async {
    setState(() => _isProcessingPayment = true);
    try {
      final response = await http
          .post(
            Uri.parse("$_serverUrl/api/verify-payment"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "orderRef": orderRef,
              "txnId": orderRef,
              "userUid": widget.userUid,
              "targetNumericId": targetNumericId,
              "coins": coinsToAdd,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final raw = jsonDecode(response.body);
      final Map res = raw is Map ? raw : {};

      if (response.statusCode == 200 && res['verified'] == true) {
        await _recordVerifiedTransaction(
          addedCoins: coinsToAdd,
          amountStr: priceStr,
          orderRef: orderRef,
          targetNumericId: targetNumericId,
          serverAlreadyCredited: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: kTealAccent,
              content: Text(
                "Payment approved! 🪙 $coinsToAdd Coins added to your wallet.",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      } else {
        final String msg = (res['message'] ??
                'Payment is still pending admin approval. Please wait and check again.')
            .toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text(
                msg,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Verification error: $e"),
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
          content: Text("Insufficient points balance!"),
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
            backgroundColor: kTealAccent,
            content: Text(
              "Exchanged 💎 $pointsCost Points to 🪙 $coinsGain Coins!",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Exchange failed: $e")),
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
            "Minimum 100,000 Points (\$10) required to withdraw!",
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
            backgroundColor: kCardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: kTealAccent, width: 1.4),
            ),
            title: const Text(
              "Withdraw Points (💎)",
              style: TextStyle(
                  color: kTextDark,
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
                        color: kTealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: selectedMethod,
                    dropdownColor: kCardWhite,
                    style: const TextStyle(color: kTextDark, fontSize: 13),

decoration: InputDecoration(
                      labelText: "Payment Method",
                      labelStyle: const TextStyle(color: kTextMuted),
                      filled: true,
                      fillColor: kPageBg,
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
                    style: const TextStyle(color: kTextDark),
                    decoration: InputDecoration(
                      labelText: "Points Amount (Min 100,000)",
                      labelStyle: const TextStyle(color: kTextMuted),
                      filled: true,
                      fillColor: kPageBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    style: const TextStyle(color: kTextDark),
                    decoration: InputDecoration(
                      labelText: accountLabel,
                      labelStyle: const TextStyle(color: kTextMuted),
                      filled: true,
                      fillColor: kPageBg,
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
                child:
                    const Text("Cancel", style: TextStyle(color: kTextMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTealAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final reqPoints =
                      int.tryParse(pointsController.text.trim()) ?? 0;
                  final account = addressController.text.trim();
                  if (reqPoints < minWithdrawPoints) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Minimum withdrawal is 100,000 Points!")),
                    );
                    return;
                  }
                  if (reqPoints > _points) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Insufficient points balance!")),
                    );
                    return;
                  }
                  if (account.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please enter payout account details!")),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  setState(() => _isProcessingPayment = true);

try {
                    final db = FirebaseFirestore.instance;
                    final userRef = db.collection('users').doc(widget.userUid);
                    final usdAmount = reqPoints / 10000.0;
                    String resolvedUserName = "ID ${widget.userNumericId}";

                    await db.runTransaction((tx) async {
                      final snap = await tx.get(userRef);
                      final data = snap.data();
                      final cur = (data?['points'] as num?)?.toInt() ?? 0;

                      if (cur < reqPoints) {
                        throw Exception("Insufficient points");
                      }
                      final rawName = (data?['name'] ?? '').toString().trim();
                      if (rawName.isNotEmpty) {
                        resolvedUserName = "$rawName (${widget.userNumericId})";
                      }
                      tx.update(userRef, {
                        'points': FieldValue.increment(-reqPoints),
                      });
                    });

                    await db.collection('withdraw_requests').add({
                      'userUid': widget.userUid,
                      'userName': resolvedUserName,
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
                          backgroundColor: kTealAccent,
                          content: Text(
                            "Withdrawal request submitted! It will be processed after admin approval.",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Submission error: $e")),
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
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: kPageBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: kTextDark, size: 18),
          onPressed: () => Navigator.pop(context, _coins),
        ),
        title: Text(
          _activeTab == 0 ? "Recharge" : "Points",
          style: const TextStyle(
              color: kTextDark, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _activeTab = _activeTab == 0 ? 1 : 0;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

decoration: BoxDecoration(
                    color: kCardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kTealAccent, width: 1.1),
                  ),
                  child: Text(
                    _activeTab == 0 ? "💎 $_points" : "🪙 $_coins",
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _activeTab == 0 ? _buildCoinsTab() : _buildPointsTab(),
          if (_isProcessingPayment)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: kTealAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoinsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User ID Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "User ID",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              Text(
                "Balance: 🪙 $_coins",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: kInputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: kTextDark,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: kTealAccent,
                        content: Text(
                          "Target confirmed: ${_userIdController.text}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      color: kTealAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Country/Region Section
          const Text(
            "Country/Region",

style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: kInputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                value: _selectedCountry,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down,
                    color: kTextDark, size: 24),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kTextDark,
                ),
                items: const [
                  DropdownMenuItem(
                      value: "All country", child: Text("All country")),
                  DropdownMenuItem(value: "Ethiopia", child: Text("Ethiopia")),
                  DropdownMenuItem(value: "Global", child: Text("Global")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCountry = val.toString());
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Official Agency Recharge Banner
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      "Official Agency Recharge: Verified USDT settlement via Binance Pay."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBEFD4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5533D),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        "%",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Official Agency Recharge",
                      style: TextStyle(
                        color: Color(0xFF4A3B22),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    "20% off >",
                    style: TextStyle(
                      color: Color(0xFFD97724),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 4. Recharge Method Cards (2-Column Grid Structure)
          const Text(
            "Recharge",
            style: TextStyle(

fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPayMethod = 0),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kCardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedPayMethod == 0
                            ? kTealAccent
                            : Colors.black12,
                        width: _selectedPayMethod == 0 ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: kGoldCoin,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.currency_bitcoin,
                              color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Binance Pay",
                            style: TextStyle(
                              color: kTextDark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPayMethod = 1),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kCardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedPayMethod == 1
                            ? kTealAccent
                            : Colors.black12,
                        width: _selectedPayMethod == 1 ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF26A17B),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              "₮",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "USDT",
                            style: TextStyle(
                              color: kTextDark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 5. Coin Packages Grid (3-Column White Cards)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _binancePackages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.96,
            ),
            itemBuilder: (context, idx) {
              final pkg = _binancePackages[idx];
              final isSelected = _selectedPackageIdx == idx;

              return GestureDetector(
                onTap: () => setState(() => _selectedPackageIdx = idx),
                child: Container(
                  decoration: BoxDecoration(
                    color: kCardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? kTealAccent : Colors.transparent,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF3CD),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text("🪙",
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${pkg['label']}",
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${pkg['price']}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kPriceCoral,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pkg['bonus'] != "+0%")
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEFEA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${pkg['bonus']}",
                              style: const TextStyle(
                                color: kPriceCoral,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

// Proceed Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTealAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _isProcessingPayment ? null : _processBinancePay,
              child: Text(
                "Recharge (${_binancePackages[_selectedPackageIdx]['price']} USDT)",
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPointsTab() {
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
              color: kCardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kTealAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("My Earned Points",
                        style: TextStyle(color: kTextMuted, fontSize: 12.5)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kTealAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "≈ \$${usdValue.toStringAsFixed(2)} USD",
                        style: const TextStyle(
                          color: kTealAccent,
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
                    const Text("💎", style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      "$_points",
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.black12, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Points: 💎 $_todayPoints",
                      style: const TextStyle(color: kTextMuted, fontSize: 12),
                    ),
                    const Text(
                      "10,000 Pts = \$1",
                      style: TextStyle(color: kTextMuted, fontSize: 11.5),
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
                backgroundColor: kTealAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showWithdrawDialog,
              icon: const Icon(Icons.account_balance_wallet, size: 20),
              label: const Text(
                "Withdraw Cash (Min 100,000 Points)",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            "Exchange Points to Coins (Instant)",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark),
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
                    color: kCardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "🪙 $cns Coins",
                        style: const TextStyle(
                          color: kTextDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Use 💎 $pts Pts",
                        style: const TextStyle(
                          color: kPriceCoral,
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
                fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark),
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
                        style: TextStyle(color: kTextMuted, fontSize: 12)),

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
                    color: kCardWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "No points received yet. Go live in a voice room to earn!",
                      style: TextStyle(color: kTextMuted, fontSize: 12),
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
                  Color ptsColor = kTealAccent;
                  if (pts < 0) {
                    ptsLabel = "💎 $pts";
                    ptsColor = kPriceCoral;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: kCardWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          titleText,
                          style:
                              const TextStyle(color: kTextDark, fontSize: 13),
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
          const SizedBox(height: 22),
          const Text(
            "Withdrawal Requests Status",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark),
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('withdraw_requests')
                .where('userUid', isEqualTo: widget.userUid)
                .limit(15)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final QuerySnapshot qSnap = snapshot.data as QuerySnapshot;
              if (qSnap.docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCardWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "No withdrawal requests yet.",
                      style: TextStyle(color: kTextMuted, fontSize: 12),
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: qSnap.docs.length,
                itemBuilder: (context, idx) {
                  final raw = qSnap.docs[idx].data();
                  final Map d = raw is Map ? raw : {};
                  final String method = (d['method'] ?? 'Payout').toString();
                  final double usd =
                      (d['usdAmount'] as num?)?.toDouble() ?? 0.0;
                  final String status =
                      (d['status'] ?? 'PENDING').toString().toUpperCase();
                  Color stColor = Colors.orange;
                  if (status == 'PAID' || status == 'APPROVED') {
                    stColor = kTealAccent;
                  } else if (status == 'REJECTED') {
                    stColor = Colors.redAccent;
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: kCardWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$method (\$${usd.toStringAsFixed(2)})",
                          style: const TextStyle(
                              color: kTextDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: stColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
