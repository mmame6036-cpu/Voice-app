import 'dart:convert';
import 'package:flutter/material.dart';
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
    this.userNumericId = 1753925,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late int _coins;
  int _selectedPackageIdx = 0;
  late TextEditingController _userIdController;
  String _selectedCountry = "Ethiopia";
  String _selectedMethod = "binance"; // "binance" or "telebirr"
  bool _isSeller = false;
  bool _isLoadingRole = true;

  final String _serverUrl = "https://nile-token-server.onrender.com";

  // Standard Binance USDT Packages
  final List> _binancePackages = [
    {"coins": 70000, "price": "\$10", "usd": 10},
    {"coins": 210000, "price": "\$30", "usd": 30},
    {"coins": 350000, "price": "\$50", "usd": 50},
    {"coins": 700000, "price": "\$100", "usd": 100},
    {"coins": 1400000, "price": "\$200", "usd": 200},
    {"coins": 3500000, "price": "\$500", "usd": 500},
  ];

  // Coin Seller Telebirr Wholesale Packages
  final List> _telebirrSellerPackages = [
    {"coins": 700000, "price": "1,000 ETB", "birr": 1000},
    {"coins": 2100000, "price": "3,000 ETB", "birr": 3000},
    {"coins": 3500000, "price": "5,000 ETB", "birr": 5000},
    {"coins": 7000000, "price": "10,000 ETB", "birr": 10000},
    {"coins": 14000000, "price": "20,000 ETB", "birr": 20000},
    {"coins": 35000000, "price": "50,000 ETB", "birr": 50000},
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _userIdController = TextEditingController(text: widget.userNumericId.toString());
    _checkUserRole();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userUid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['role'] == 'seller') {
          setState(() {
            _isSeller = true;
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingRole = false);
    }
  }

  Future<void> _saveCoinsToFirestore(int addedCoins) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userUid);
      await userRef.set({
        'coins': FieldValue.increment(addedCoins),
        'lastRechargeAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _processBinancePay() {
    final pkg = _binancePackages[_selectedPackageIdx];
    final coinsToAdd = pkg["coins"] as int;
    final priceStr = pkg["price"] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.currency_bitcoin, color: Color(0xFFF3BA2F)),
            SizedBox(width: 8),
            Text(
              "Binance Pay",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Target Account: ID ${_userIdController.text}", style: const TextStyle(color: Colors.black54)),

const SizedBox(height: 8),
            Text("Selected Package: 🪙 $coinsToAdd Coins", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text("Amount: $priceStr (USDT)", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 14, color: Color(0xFF00C9A7)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Secure crypto settlement via Binance Pay API",
                      style: TextStyle(fontSize: 11, color: Colors.black87),
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
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3BA2F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _coins += coinsToAdd;
              });

              await _saveCoinsToFirestore(coinsToAdd);
              widget.onCoinsRecharged(_coins);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF00C9A7),
                    content: Text("Binance Pay successful! 🪙 $coinsToAdd Coins added."),
                  ),
                );
              }
            },
            child: const Text("Pay with Binance", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _processTelebirrSellerPay() {
    final pkg = _telebirrSellerPackages[_selectedPackageIdx];
    final coinsToAdd = pkg["coins"] as int;
    final priceStr = pkg["price"] as String;
    final amountBirr = pkg["birr"] as int;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Color(0xFF005BAA)),
            SizedBox(width: 8),
            Text(
              "Telebirr Seller Portal",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF005BAA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text("Authorized Coin Seller Portal",
                  style: TextStyle(color: Color(0xFF005BAA), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Text("Seller Account ID: ${_userIdController.text}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),

const SizedBox(height: 6),
            Text("Wholesale Volume: 🪙 $coinsToAdd Coins", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text("Total Settlement: $priceStr", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final response = await http.post(
                  Uri.parse("$_serverUrl/api/payment/telebirr-seller-webhook"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "sellerNumericId": widget.userNumericId,
                    "amountBirr": amountBirr,
                    "telebirrTxnId": "TXN_${DateTime.now().millisecondsSinceEpoch}",
                  }),
                );

                if (response.statusCode == 200) {
                  setState(() {
                    _coins += coinsToAdd;
                  });
                  widget.onCoinsRecharged(_coins);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF005BAA),
                        content: Text("Telebirr Seller Settlement Complete! 🪙 $coinsToAdd Coins credited."),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settlement verification failed.")),
                    );
                  }
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error connecting to payment gateway.")),
                  );
                }
              }
            },
            child: const Text("Confirm Telebirr Pay", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPackages = _selectedMethod == "binance" ? _binancePackages : _telebirrSellerPackages;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context, _coins),
        ),
        title: const Text(
          "Recharge",
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "User ID",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),

),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _userIdController,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("User ID ${_userIdController.text} confirmed")),
                              );
                            },
                            child: const Text(
                              "Confirm",
                              style: TextStyle(
                                color: Color(0xFF00C9A7),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Country/Region",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountry,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                          items: ["Ethiopia", "All country", "United States", "Saudi Arabia", "UAE"]
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCountry = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_isSeller)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),

border: Border.all(color: const Color(0xFF90CAF9)),
                        ),
                        child: const Row(
                          children: [
                            Text("🛡️", style: TextStyle(fontSize: 14)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Certified Coin Seller Account Active",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Text("🏷️", style: TextStyle(fontSize: 14)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Official Global Recharge",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A3408),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      "Payment Method",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Binance Method Button (Available to all)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedMethod = "binance";
                              _selectedPackageIdx = 0;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedMethod == "binance" ? const Color(0xFF00C9A7) : Colors.black12,
                                  width: _selectedMethod == "binance" ? 1.6 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF3BA2F),
                                      shape: BoxShape.circle,
                                    ),

child: const Center(
                                      child: Text(
                                        "B",
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Binance (USDT)",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_isSeller) ...[
                          const SizedBox(width: 10),
                          // Telebirr Method Button (Available ONLY to Sellers)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedMethod = "telebirr";
                                _selectedPackageIdx = 0;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedMethod == "telebirr" ? const Color(0xFF005BAA) : Colors.black12,
                                    width: _selectedMethod == "telebirr" ? 1.6 : 1.0,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone_android, color: Color(0xFF005BAA), size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      "Telebirr (Seller)",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentPackages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, idx) {
                        final pkg = currentPackages[idx];
                        final isSelected = _selectedPackageIdx == idx;
                        final activeThemeColor = _selectedMethod == "binance" ? const Color(0xFF00C9A7) : const Color(0xFF005BAA);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedPackageIdx = idx),

child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? activeThemeColor : Colors.black12,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("🪙", style: TextStyle(fontSize: 22)),
                                const SizedBox(height: 6),
                                Text(
                                  "${pkg['coins']}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${pkg['price']}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedMethod == "binance" ? Colors.deepOrangeAccent : const Color(0xFF005BAA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedMethod == "binance" ? const Color(0xFF00C9A7) : const Color(0xFF005BAA),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _selectedMethod == "binance" ? _processBinancePay : _processTelebirrSellerPay,
                        child: Text(
                          _selectedMethod == "binance"
                              ? "Recharge with Binance (${currentPackages[_selectedPackageIdx]['price']})"
                              : "Wholesale Recharge with Telebirr (${currentPackages[_selectedPackageIdx]['price']})",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
