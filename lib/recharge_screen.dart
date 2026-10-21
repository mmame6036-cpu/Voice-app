import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'services/user_service.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({Key? key}) : super(key: key);

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final UserService _user = UserService();
  final TextEditingController _txIdController = TextEditingController();
  int _selectedPackageIndex = 1;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _rechargeTiers = const [
    {'coins': 7000, 'priceUsd': 0.99, 'displayPrice': '\$0.99'},
    {'coins': 21000, 'priceUsd': 2.99, 'displayPrice': '\$2.99'},
    {'coins': 70000, 'priceUsd': 9.99, 'displayPrice': '\$9.99'},
    {'coins': 150000, 'priceUsd': 19.99, 'displayPrice': '\$19.99'},
    {'coins': 400000, 'priceUsd': 49.99, 'displayPrice': '\$49.99'},
    {'coins': 900000, 'priceUsd': 99.99, 'displayPrice': '\$99.99'},
  ];

  final String _binancePayId = '1059643208';
  final String _usdtTrc20Address = 'TYDZSBLhi993hdb88172hbvTRC20';

  final List<Map<String, dynamic>> _recommendedSellers = const [
    {
      'name': 'Medina Official Agent',
      'id': '1000',
      'level': 'Senior Seller',
      'phone': '0943724560',
      'telegram': '@MedinaAgent',
      'isVerified': true,
    },
    {
      'name': 'Addis Coin Service',
      'id': '1005',
      'level': 'Verified Seller',
      'phone': '0911223344',
      'telegram': '@AddisCoins',
      'isVerified': true,
    },
  ];

  @override
  void dispose() {
    _txIdController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF00C9A7),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CoinsDetailsScreen(userId: _user.userId)),
    );
  }

  Future<void> _submitBinanceRecharge() async {
    final txId = _txIdController.text.trim();
    if (txId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Binance Transaction ID or Order ID'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final selected = _rechargeTiers[_selectedPackageIndex];
    final int amountCoins = selected['coins'];
    final String pricePaid = selected['displayPrice'];

    try {
      final res = await http.post(
        Uri.parse('${UserService.serverUrl}/api/recharge-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _user.userId,
          'userName': _user.userName.isNotEmpty ? _user.userName : 'User_${_user.userId}',
          'paymentMethod': 'Binance Pay',
          'txId': txId,
          'amountCoins': amountCoins,
          'pricePaid': pricePaid,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _txIdController.clear();

_showSuccessDialog(amountCoins, pricePaid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to submit payment request'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server connection error. Please try again later.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(int amountCoins, String pricePaid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00C9A7), size: 60),
            const SizedBox(height: 14),
            const Text(
              'Payment Request Submitted',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Binance Pay submission ($pricePaid) has been received. $amountCoins Coins will be credited to your account upon verification.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTier = _rechargeTiers[_selectedPackageIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Coins',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black87),
            tooltip: 'Coins Details',
            onPressed: _openDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 28),

const SizedBox(width: 8),
                  const Text('Coins', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
                  const SizedBox(width: 12),
                  Text(
                    '${_user.coins}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _openDetails,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: Colors.amber.withOpacity(0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Details', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Telebirr Local Agent Notice Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF00C9A7), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paying locally via Telebirr?',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Telebirr payments are exclusively handled by authorized Coin Sellers listed below.',
                          style: TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Binance Recharge Packages
            const Text(
              'Binance Pay Recharge (USDT)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rechargeTiers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, idx) {
                final tier = _rechargeTiers[idx];
                final isSelected = _selectedPackageIndex == idx;

                return GestureDetector(
                  onTap: () => setState(() => _selectedPackageIndex = idx),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF0B90B) : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 2 : 1,

),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${tier['coins']}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tier['displayPrice'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Official Binance Wallet Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCopyRow('Official Binance Pay UID', _binancePayId),
                  const SizedBox(height: 8),
                  _buildCopyRow('USDT Deposit Address (TRC20)', _usdtTrc20Address),
                  const Divider(color: Colors.black12, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total to Pay:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      Text(
                        selectedTier['displayPrice'],
                        style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TxID Submission
            TextField(
              controller: _txIdController,
              decoration: InputDecoration(
                labelText: 'Binance Order ID / TxID',
                labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
                hintText: 'Enter transaction hash or Order ID...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0B90B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitBinanceRecharge,
                icon: _isSubmitting

? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.check_circle_outline, color: Colors.black),
                label: Text(
                  _isSubmitting ? 'Verifying...' : 'Submit Binance Payment',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recommended Sellers (Coin Sellers for Telebirr)
            Row(
              children: [
                const Text(
                  'Recommended Coin Sellers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Telebirr Authorized', style: TextStyle(fontSize: 10, color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recommendedSellers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final seller = _recommendedSellers[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF00C9A7),
                        radius: 20,
                        child: Text(seller['name'][0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(seller['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: Color(0xFF00C9A7), size: 14),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${seller['id']} • ${seller['level']}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9A7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          elevation: 0,
                        ),
                        onPressed: () => _launchPhoneCall(seller['phone']),
                        icon: const Icon(Icons.phone, color: Colors.black, size: 14),
                        label: const Text('Contact', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                'By recharging you agree to the Official Nile Voice User Agreement',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: Color(0xFF00C9A7), size: 18),
          onPressed: () => _copyToClipboard(value, label),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coins Details Screen
// ---------------------------------------------------------------------------
class CoinsDetailsScreen extends StatefulWidget {
  final String userId;
  const CoinsDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CoinsDetailsScreen> createState() => _CoinsDetailsScreenState();
}

class _CoinsDetailsScreenState extends State<CoinsDetailsScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await http.get(
        Uri.parse('${UserService.serverUrl}/api/wallet/transactions?userId=${widget.userId}'),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['transactions'] != null) {
          setState(() {
            _transactions = data['transactions'];
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Coins Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey[400]),

const SizedBox(height: 12),
                      Text('No transactions yet', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Recharge coins or participate in rooms to view details.', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final tx = _transactions[idx];
                    final int amount = tx['amount'] ?? 0;
                    final bool isPositive = amount >= 0;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.04)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: isPositive ? Colors.green : Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx['description'] ?? 'Transaction',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tx['type'] ?? 'Coin Movement',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isPositive ? '+' : ''}$amount Coins',
                            style: TextStyle(
                              color: isPositive ? Colors.green : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
