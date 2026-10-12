import 'dart:convert';
import 'package:flutter/material.dart';
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
  int _selectedPackageIndex = 0;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _rechargeTiers = [
    {'coins': 7000, 'price': 0.99, 'displayPrice': '\$0.99'},
    {'coins': 21000, 'price': 2.99, 'displayPrice': '\$2.99'},
    {'coins': 70000, 'price': 9.99, 'displayPrice': '\$9.99'},
  ];

  final List<Map<String, dynamic>> _recommendedSellers = [];

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoinsDetailsScreen()),
    );
  }

  Future<void> _payWithBinance(double amount, int coins) async {
    setState(() => _isProcessing = true);
    try {
      final response = await http.post(
        Uri.parse('https://voice-app-2-jd95.onrender.com/api/binance/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _user.userId,
          'amount': amount,
          'coins': coins,
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          final String urlStr = resData['checkoutUrl'] ?? '';
          final Uri url = Uri.parse(urlStr);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment initiation failed')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'New User Mega Pack',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Special', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPackItem(Icons.monetization_on, Colors.amber, 'x9,000', 'Coins'),
                      _buildPackItem(Icons.diamond, Colors.purpleAccent, 'x3,000', 'Points'),
                      _buildPackItem(Icons.crop_original, Colors.blueAccent, 'Frame*1', '15 Days'),
                      _buildPackItem(Icons.military_tech, Colors.amber, 'Medal*1', 'Permanent'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        elevation: 0,
                      ),
                      onPressed: () => _payWithBinance(0.99, 9000),
                      child: const Text('\$0.99 Buy Now (Binance Pay)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ),

),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Coins Recharge (Binance Pay / USDT)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_rechargeTiers.length, (idx) {
                final tier = _rechargeTiers[idx];
                final isSelected = _selectedPackageIndex == idx;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPackageIndex = idx),
                    child: Container(
                      margin: EdgeInsets.only(left: idx == 0 ? 0 : 5, right: idx == _rechargeTiers.length - 1 ? 0 : 5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        children: [
                          Text(
                            '${tier['coins']}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tier['displayPrice'],
                            style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0B90B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                  elevation: 0,
                ),
                onPressed: _isProcessing
                    ? null
                    : () {
                        final selected = _rechargeTiers[_selectedPackageIndex];
                        _payWithBinance(selected['price'], selected['coins']);
                      },
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.account_balance_wallet, color: Colors.black),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Pay with Binance Pay',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Recommended Sellers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                Text('Ethiopia (Telebirr)', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),

],
            ),
            const SizedBox(height: 12),
            if (_recommendedSellers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.storefront_outlined, size: 44, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      'No authorized sellers active right now.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact agency to pay locally with Telebirr.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics),
                itemCount: _recommendedSellers.length,
                itemBuilder: (context, i) {
                  final seller = _recommendedSellers[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Text(seller['name'][0]),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(seller['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Seller Level: ${seller['level']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7)),
                          onPressed: () {},
                          child: const Text('Contact', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'By recharging you agree to the Recharge Agreement',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPackItem(IconData icon, Color color, String value, String title) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coins Details Screen
// ---------------------------------------------------------------------------
class CoinsDetailsScreen extends StatelessWidget {
  const CoinsDetailsScreen({Key? key}) : super(key: key);

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No transactions yet', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 4),
            Text('No more data', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
