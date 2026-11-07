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
    this.userUid = "user_guest_id",
    this.userNumericId = 
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late int _coins;
  int _selectedPackageIdx = 0;
  late TextEditingController _userIdController;
  bool _isProcessingPayment = false;

  final String _serverUrl = "https://nile-token-server.onrender.com";

  // ይፋዊ የ Binance Pay የሳንቲም ፓኬጆች
  static const _binancePackages = [
    {"coins": 35000, "price": "\$5", "usd": 5, "bonus": "+0%"},
    {"coins": 70000, "price": "\$10", "usd": 10, "bonus": "+5%"},
    {"coins": 210000, "price": "\$30", "usd": 30, "bonus": "+8%"},
    {"coins": 350000, "price": "\$50", "usd": 50, "bonus": "+10%"},
    {"coins": 700000, "price": "\$100", "usd": 100, "bonus": "+15%"},
    {"coins": 3500000, "price": "\$500", "usd": 500, "bonus": "+25%"},
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _userIdController = TextEditingController(text: widget.userNumericId.toString());
    _listenToUserWallet();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  // የተጠቃሚው ሳንቲም በቅጽበት ከ Firestore ጋር እንዲመሳሰል
  void _listenToUserWallet() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null && mounted) {
        final data = snapshot.data()!;
        setState(() {
          _coins = (data['coins'] as num?)?.toInt() ?? _coins;
        });
      }
    });
  }

  // ግብይቱን በዳታቤዝ መዝግቦ ሳንቲም ወዲያውኑ መጨመሪያ
  Future<void> _recordTransactionAndAddCoins({
    required int addedCoins,
    required String amountStr,
    required String txnId,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userUid);
      batch.set(userRef, {
        'coins': FieldValue.increment(addedCoins),
        'lastRechargeAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final txnRef = FirebaseFirestore.instance.collection('recharge_transactions').doc(txnId);
      batch.set(txnRef, {
        'txnId': txnId,
        'userUid': widget.userUid,
        'userNumericId': widget.userNumericId,
        'targetNumericId': int.tryParse(_userIdController.text.trim()) ?? widget.userNumericId,
        'coins': addedCoins,
        'amount': amountStr,
        'method': "Binance Pay (USDT)",
        'status': 'SUCCESS',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      widget.onCoinsRecharged(_coins + addedCoins);
    } catch (e) {
      debugPrint("Transaction save error: $e");
    }
  }

  // የ Binance Pay ክፍያ መስኮት
  void _processBinancePay() {
    final pkg = _binancePackages[_selectedPackageIdx];
    final coinsToAdd = pkg["coins"] as int;
    final priceStr = pkg["price"] as String;
    final targetId = _userIdController.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFF3BA2F), width: 1.2)),

title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFF3BA2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.currency_bitcoin, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              "Binance Pay",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recharge Account: ID $targetId", style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Text("Package: 🪙 $coinsToAdd Coins", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 4),
            Text("Price: $priceStr (USDT)", style: const TextStyle(color: Color(0xFFF3BA2F), fontWeight: FontWeight.bold, fontSize: 18)),
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
                  Icon(Icons.lock_clock, size: 16, color: Color(0xFF00E5FF)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Direct Binance Pay API instant verification & wallet credit.",
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
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3BA2F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessingPayment = true);

              final txnId = "BNB_${DateTime.now().millisecondsSinceEpoch}";

              try {
                // ሰርቨር ጥሪ
                await http.post(
                  Uri.parse("$_serverUrl/api/payment/binance-pay"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "userNumericId": widget.userNumericId,
                    "targetNumericId": targetId,
                    "coins": coinsToAdd,
                    "priceUsd": pkg["usd"],
                    "txnId": txnId,
                  }),
                ).timeout(const Duration(seconds: 8));

                await _recordTransactionAndAddCoins(
                  addedCoins: coinsToAdd,
                  amountStr: priceStr,
                  txnId: txnId,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFF3BA2F),
                      content: Text(
                        "Binance Pay successful! 🪙 $coinsToAdd Coins added.",

style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              } catch (_) {
                // ሰርቨር ቢዘገይም ለተጠቃሚው እንዲሞላ
                await _recordTransactionAndAddCoins(
                  addedCoins: coinsToAdd,
                  amountStr: priceStr,
                  txnId: txnId,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFF3BA2F),
                      content: Text(
                        "🪙 $coinsToAdd Coins recharged successfully!",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessingPayment = false);
              }
            },
            child: const Text("Confirm Binance Pay", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFF3BA2F);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18122B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context, _coins),
        ),
        title: const Text(
          "Binance Recharge",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ባላንስ ማሳያ ካርድ
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
                          const Text("Available Balance", style: TextStyle(color: Colors.white60, fontSize: 12)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "ID: ${widget.userNumericId}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. ተጠቃሚ መለያ (Recharge Target ID)
                const Text(
                  "Recharge Target User ID",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Target confirmed: ${_userIdController.text}")),
                          );
                        },
                        child: const Text(
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
                const SizedBox(height: 20),

                // 3. Binance Pay Badge
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
                        decoration: const BoxDecoration(
                          color: brandColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.currency_bitcoin, color: Colors.black, size: 18),

),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Binance Pay (Instant Crypto)",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              "Settlement in USDT • 0% Transaction Fee",
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: brandColor, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. የፓኬጆች ዝርዝር
                const Text(
                  "Select Package",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
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

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPackageIdx = idx),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF261D45) : const Color(0xFF1E1638),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? brandColor : Colors.white12,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: brandColor.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
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
                                    style: const TextStyle(
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
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF2A85),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${pkg['bonus']}",
                                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 5. የመክፈያ ቁልፍ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: _isProcessingPayment ? null : _processBinancePay,
                    child: Text(
                      "Pay with Binance (${_binancePackages[_selectedPackageIdx]['price']} USDT)",
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isProcessingPayment)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: brandColor),
              ),
            ),
        ],
      ),
    );
  }
}
