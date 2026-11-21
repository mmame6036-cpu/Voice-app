import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointsWalletScreen extends StatefulWidget {
  const PointsWalletScreen({super.key});

  @override
  State<PointsWalletScreen> createState() => _PointsWalletScreenState();
}

class _PointsWalletScreenState extends State<PointsWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? _user = FirebaseAuth.instance.currentUser;
  StreamSubscription? _userSub;

  int _totalPoints = 0;
  int _frozenPoints = 0;
  int _userCoins = 0;
  String _userDisplayName = "User";
  int _userNumericId = 0;
  String _savedSecurityPin = "";
  bool _usesLegacyDiamonds = false;

  static const int pointsPerUsd = 10000;
  static const double etbPerUsd = 135.0;

  static const Color shiroBg = Color(0xFFF7F4EB);
  static const Color cardColor = Color(0xFFEFE9DA);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF6B655B);
  static const Color primaryPurple = Color(0xFF7E22CE);

  // Cash out state
  final TextEditingController _cashOutController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  dynamic _selectedMethod;
  double _calculatedUsd = 0.0;
  bool _isSubmittingWithdraw = false;

  // Exchange state
  final TextEditingController _exchangeController = TextEditingController();
  int _calculatedCoins = 0;

  // Transfer state
  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _transferAmountController =
      TextEditingController();
  String? _verifiedUserName;
  String? _verifiedUserUid;
  bool _isCheckingUser = false;

  final List _paymentMethods = [
    {
      "name": "Telebirr",
      "currency": "ETB",
      "fee": "Fee: 3%",
      "icon": Icons.phone_android,
      "color": Colors.blue,
      "accountLabel": "Telebirr Phone Number (+251...)",
    },
    {
      "name": "CBE (Commercial Bank of Ethiopia)",
      "currency": "ETB",
      "fee": "Fee: 3%",
      "icon": Icons.account_balance,
      "color": Colors.purple,
      "accountLabel": "CBE Account Number (1000...)",
    },
    {
      "name": "Bank of Abyssinia",
      "currency": "ETB",
      "fee": "Fee: 3%",
      "icon": Icons.storefront,
      "color": Colors.amber,
      "accountLabel": "Abyssinia Account Number",
    },
    {
      "name": "Awash Bank",
      "currency": "ETB",
      "fee": "Fee: 3%",
      "icon": Icons.account_balance_wallet,
      "color": Colors.orange,
      "accountLabel": "Awash Account Number",
    },
    {
      "name": "Binance Pay",
      "currency": "USDT",
      "fee": "Fee: 1% + \$0.5/txn",
      "icon": Icons.currency_bitcoin,
      "color": Colors.amber,
      "accountLabel": "Binance Pay ID or USDT Address",
    },
  ];

  bool get _isEtbSelected {
    if (_selectedMethod == null) return false;
    return _selectedMethod['currency'].toString() == "ETB";
  }

  double get _calculatedEtb => _calculatedUsd * etbPerUsd;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listenToUserData();
  }

  void _listenToUserData() {
    final user = _user;
    if (user == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;

      final raw = doc.data();
      if (raw == null) return;
      final Map data = raw is Map ? raw : {};

      int pts = (data['points'] as num?)?.toInt() ?? 0;
      int legacyDmnds = (data['diamonds'] as num?)?.toInt() ?? 0;
      bool useLegacy = false;

      if (pts == 0 && legacyDmnds > 0) {
        pts = legacyDmnds;
        useLegacy = true;
      }

int frozen = (data['frozenPoints'] as num?)?.toInt() ?? 0;
      if (frozen == 0) {
        frozen = (data['frozenDiamonds'] as num?)?.toInt() ?? 0;
      }

      String nameVal = "User";
      if (data['name'] != null) {
        nameVal = data['name'].toString();
      } else if (data['nickname'] != null) {
        nameVal = data['nickname'].toString();
      }

      setState(() {
        _totalPoints = pts;
        _frozenPoints = frozen;
        _usesLegacyDiamonds = useLegacy;
        _userCoins = (data['coins'] as num?)?.toInt() ?? 0;
        _userDisplayName = nameVal;
        _userNumericId = (data['numericId'] as num?)?.toInt() ?? 0;
        _savedSecurityPin = (data['paymentPin'] ?? '').toString().trim();
      });
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _tabController.dispose();
    _cashOutController.dispose();
    _fullNameController.dispose();
    _accountNumberController.dispose();
    _exchangeController.dispose();
    _targetIdController.dispose();
    _transferAmountController.dispose();
    super.dispose();
  }

  // Verify (or set if first time) Security Password for Cash Out, Exchange & Transfer
  Future<bool> _verifySecurityPassword(String actionTitle) async {
    final user = _user;
    if (user == null) return false;

    String latestPin = _savedSecurityPin;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        latestPin = (doc.data()!['paymentPin'] ?? '').toString().trim();
        _savedSecurityPin = latestPin;
      }
    } catch (_) {}

    if (!mounted) return false;

    // If user hasn't set a Security Password yet, allow them to create it first
    if (latestPin.isEmpty) {
      final newPinCtrl = TextEditingController();
      final confirmPinCtrl = TextEditingController();
      final bool? created = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: primaryPurple),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Set Security Password",
                  style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please set a 6-digit Security Password to protect your withdrawals, exchanges, and transfers:",
                style: TextStyle(color: textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Enter 6-digit Security Password",
                  counterText: "",
                  filled: true,
                  fillColor: shiroBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPinCtrl,

keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Confirm Security Password",
                  counterText: "",
                  filled: true,
                  fillColor: shiroBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel", style: TextStyle(color: textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final p1 = newPinCtrl.text.trim();
                final p2 = confirmPinCtrl.text.trim();
                if (p1.length != 6 || p1 != p2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text("Enter matching 6-digit passwords."),
                    ),
                  );
                  return;
                }
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({'paymentPin': p1}, SetOptions(merge: true));
                _savedSecurityPin = p1;
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text("Save & Continue",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return created == true;
    }

    // Ask user for existing Security Password
    final pinCtrl = TextEditingController();
    final bool? verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: primaryPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Security Password ($actionTitle)",
                style: const TextStyle(
                    color: textDark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your 6-digit Security Password to authorize this transaction:",
              style: TextStyle(color: textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              style: const TextStyle(
                  color: textDark,
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "••••••",
                counterText: "",
                filled: true,
                fillColor: shiroBg,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final entered = pinCtrl.text.trim();
              if (entered != latestPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text("Incorrect Security Password!"),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text("Verify",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return verified == true;
  }

  // 1. Submit Withdraw Request to Firestore (Requires Full Name + ETB + Security Password)
  Future<void> _submitWithdrawRequest() async {
    final user = _user;
    if (user == null) return;

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method")),
      );
      return;
    }

    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter your Full Name (Account Holder)")),
      );
      return;
    }

    final accountDetail = _accountNumberController.text.trim();
    if (accountDetail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Please enter your ${_selectedMethod['name']} account details")),
      );
      return;
    }

    final points = int.tryParse(_cashOutController.text.trim()) ?? 0;
    if (points < pointsPerUsd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Minimum withdrawal is 10,000 Points")),
      );
      return;
    }

    if (points > _totalPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient points balance")),
      );
      return;
    }

    // Require Security Password before submitting Cash Out
    final bool authorized = await _verifySecurityPassword("Cash out");
    if (!authorized) return;

    setState(() => _isSubmittingWithdraw = true);

    try {
      final double usdAmount = points / pointsPerUsd;
      final bool isEtb = _selectedMethod['currency'].toString() == "ETB";
      final double etbAmount = usdAmount * etbPerUsd;
      final String formattedPayout = isEtb
          ? "${etbAmount.toStringAsFixed(2)} ETB"
          : "\$${usdAmount.toStringAsFixed(2)} USD";

      final batch = FirebaseFirestore.instance.batch();
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      if (_usesLegacyDiamonds) {
        batch.update(userRef, {
          'diamonds': FieldValue.increment(-points),
          'frozenDiamonds': FieldValue.increment(points),
        });
      } else {
        batch.update(userRef, {
          'points': FieldValue.increment(-points),
          'frozenPoints': FieldValue.increment(points),
        });
      }

      final requestRef =
          FirebaseFirestore.instance.collection('withdraw_requests').doc();
      batch.set(requestRef, {
        'requestId': requestRef.id,
        'userUid': user.uid,
        'uid': user.uid,
        'userNumericId': _userNumericId,

'userName': _userDisplayName,
        'fullName': fullName,
        'accountHolderName': fullName,
        'points': points,
        'usdAmount': usdAmount,
        'etbAmount': isEtb ? etbAmount : 0.0,
        'payoutDisplay': formattedPayout,
        'method': _selectedMethod['name'],
        'currency': _selectedMethod['currency'],
        'account': accountDetail,
        'accountDetails': accountDetail,
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _cashOutController.clear();
      _fullNameController.clear();
      _accountNumberController.clear();
      setState(() {
        _calculatedUsd = 0.0;
        _selectedMethod = null;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: primaryPurple),
                SizedBox(width: 8),
                Text("Request Submitted",
                    style: TextStyle(color: textDark, fontSize: 16)),
              ],
            ),
            content: Text(
              "Full Name: $fullName\nAmount: $points Points ($formattedPayout)\nRef: ${requestRef.id}\n\nSubmitted for admin review.",
              style: const TextStyle(color: textMuted, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK",
                    style: TextStyle(
                        color: primaryPurple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Withdrawal error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingWithdraw = false);
    }
  }

  Future<void> _checkTargetUser() async {
    final queryText = _targetIdController.text.trim();
    if (queryText.isEmpty) return;

    setState(() {
      _isCheckingUser = true;
      _verifiedUserName = null;
      _verifiedUserUid = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('numericId', isEqualTo: int.tryParse(queryText) ?? 0)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final docData = doc.data();
        String foundName = "User ${docData['numericId']}";
        if (docData['name'] != null) {
          foundName = docData['name'].toString();
        }
        setState(() {
          _verifiedUserName = foundName;
          _verifiedUserUid = doc.id;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User ID not found")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUser = false);
    }
  }

  // 2. Execute Transfer (Requires Security Password)
  Future<void> _executeTransfer() async {
    final user = _user;
    if (user == null) return;

    if (_verifiedUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please verify User ID first")),
      );
      return;
    }

    if (_verifiedUserUid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot transfer points to yourself")),
      );
      return;
    }

final amount = int.tryParse(_transferAmountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid points amount")),
      );
      return;
    }

    if (amount > _totalPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient points balance")),
      );
      return;
    }

    // Require Security Password before executing Transfer
    final bool authorized = await _verifySecurityPassword("Transfer");
    if (!authorized) return;

    final fee = (amount * 0.02).round();
    final received = amount - fee;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final senderRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final receiverRef =
          FirebaseFirestore.instance.collection('users').doc(_verifiedUserUid);

      if (_usesLegacyDiamonds) {
        batch.update(senderRef, {'diamonds': FieldValue.increment(-amount)});
      } else {
        batch.update(senderRef, {'points': FieldValue.increment(-amount)});
      }
      batch.update(receiverRef, {'points': FieldValue.increment(received)});

      await batch.commit();

      _transferAmountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Successfully transferred $received points (Fee: $fee)")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Transfer failed: $e")),
        );
      }
    }
  }

  // 3. Execute Exchange (Requires Security Password)
  Future<void> _executeExchange() async {
    final user = _user;
    if (user == null) return;

    final points = int.tryParse(_exchangeController.text.trim()) ?? 0;
    if (points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid points amount")),
      );
      return;
    }

    if (points > _totalPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient points")),
      );
      return;
    }

    // Require Security Password before executing Exchange
    final bool authorized = await _verifySecurityPassword("Exchange");
    if (!authorized) return;

    final coinsToAdd = ((points / 10000) * 9000).round();

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      if (_usesLegacyDiamonds) {
        await userRef.update({
          'diamonds': FieldValue.increment(-points),
          'coins': FieldValue.increment(coinsToAdd),
        });
      } else {
        await userRef.update({
          'points': FieldValue.increment(-points),
          'coins': FieldValue.increment(coinsToAdd),
        });
      }

      _exchangeController.clear();
      setState(() => _calculatedCoins = 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Exchanged $points points for $coinsToAdd coins!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Exchange failed: $e")),
        );
      }
    }
  }

  void _openPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: shiroBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

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
            const Text(
              "Select Payment Method",
              style: TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  final String methodName = method['name'].toString();
                  final String methodCurrency = method['currency'].toString();
                  final String methodFee = method['fee'].toString();
                  final Color iconColor = method['color'] as Color;
                  final IconData iconData = method['icon'] as IconData;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.18),
                          child: Icon(iconData, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                methodName,
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$methodCurrency • $methodFee",
                                style: const TextStyle(
                                    color: textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedMethod = method;
                              if (_fullNameController.text.trim().isEmpty &&
                                  _userDisplayName != "User") {

_fullNameController.text = _userDisplayName;
                              }
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text("Select",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: shiroBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Points Wallet",
          style: TextStyle(
              color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Available Points",
                      style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "$_totalPoints",
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Frozen Points: $_frozenPoints (Pending admin review)",
                  style: const TextStyle(color: textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TabBar(
              controller: _tabController,
              indicatorColor: primaryPurple,
              indicatorWeight: 3,
              labelColor: primaryPurple,
              unselectedLabelColor: textMuted,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Cash out"),
                Tab(text: "Exchange"),
                Tab(text: "Transfer"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCashOutTab(),
                _buildExchangeTab(),
                _buildTransferTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildCashOutTab() {
    String chosenMethodName = "Select Payment Method";
    String accountHint = "Account details (Select method first)";
    if (_selectedMethod != null) {
      chosenMethodName = _selectedMethod['name'].toString();
      accountHint = _selectedMethod['accountLabel'].toString();
    }

    final String equivalentText = _isEtbSelected
        ? "Equivalent: ${_calculatedEtb.toStringAsFixed(2)} ETB"
        : "Equivalent: \$${_calculatedUsd.toStringAsFixed(2)} USD";

    final String rateText = _isEtbSelected
        ? "${etbPerUsd.toStringAsFixed(0)} ETB = 10,000 Points"
        : "1 USD = 10,000 Points";

    VoidCallback? withdrawAction = _submitWithdrawRequest;
    Widget withdrawLabel = const Text(
      "Withdraw Cash",
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );

    if (_isSubmittingWithdraw) {
      withdrawAction = null;
      withdrawLabel = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Payment Method, Full Name & Account Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment Method",
                      style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        color: textDark, size: 14),
                    onPressed: _openPaymentMethodSheet,
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openPaymentMethodSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance,
                          color: primaryPurple, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          chosenMethodName,
                          style: const TextStyle(
                              color: primaryPurple,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.black12),
              const SizedBox(height: 6),
              const Text(
                "Full Name (Account Holder):",
                style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                    color: textDark,
                    fontSize: 15,

fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: "Enter Full Name",
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                ),
              ),
              if (_selectedMethod != null) ...[
                const Divider(color: Colors.black12),
                const SizedBox(height: 6),
                Text(
                  "Enter ${_selectedMethod['name']} Account:",
                  style: const TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _accountNumberController,
                  style: const TextStyle(
                      color: textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: accountHint,
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Points Amount Card (ETB for Ethiopian banks/Telebirr, USD for USDT)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Points Amount",
                  style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cashOutController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          color: textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: "Min. 10,000",
                        hintStyle:
                            TextStyle(color: Colors.black26, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        final p = int.tryParse(val) ?? 0;
                        setState(() {
                          _calculatedUsd = p / pointsPerUsd;
                        });
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _cashOutController.text = "$_totalPoints";
                      setState(() {
                        _calculatedUsd = _totalPoints / pointsPerUsd;
                      });
                    },
                    child: const Text("All",
                        style: TextStyle(
                            color: primaryPurple, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

const Divider(color: Colors.black12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    equivalentText,
                    style: const TextStyle(
                        color: textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    rateText,
                    style: const TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // 3. Withdraw Action Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 2,
            ),
            onPressed: withdrawAction,
            child: withdrawLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Exchange Points to Coins",
                      style: TextStyle(
                          color: textDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold)),
                  Text("Rate: 10,000 Pts = 9,000 Coins",
                      style: TextStyle(color: textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _exchangeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: "Enter points amount",
                  hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  final p = int.tryParse(val) ?? 0;
                  setState(() {
                    _calculatedCoins = ((p / 10000) * 9000).round();
                  });
                },
              ),
              const Divider(color: Colors.black12),
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "You will receive: $_calculatedCoins Coins",
                    style: const TextStyle(
                        color: textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(

backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 2,
            ),
            onPressed: _executeExchange,
            child: const Text("Confirm Exchange",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildTransferTab() {
    VoidCallback? checkAction = _checkTargetUser;
    Widget checkLabel = const Text(
      "Check",
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );

    if (_isCheckingUser) {
      checkAction = null;
      checkLabel = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Recipient User ID",
                  style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetIdController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          color: textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: "Enter numeric User ID",
                        hintStyle:
                            TextStyle(color: Colors.black26, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: checkAction,
                    child: checkLabel,
                  ),
                ],
              ),
              if (_verifiedUserName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Verified Name: $_verifiedUserName",
                    style: const TextStyle(
                        color: primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const Divider(color: Colors.black12),
              const SizedBox(height: 6),
              const Text("Transfer Points (Fee: 2%)",
                  style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(

controller: _transferAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: "Enter points to send",
                  hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "• 2% platform transaction fee applies on transfer.\n• Verified user points will be credited immediately.",
            style: TextStyle(color: textMuted, fontSize: 11.5, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 2,
            ),
            onPressed: _executeTransfer,
            child: const Text("Send Transfer",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
