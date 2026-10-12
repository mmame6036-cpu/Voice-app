import 'package:flutter/material.dart';
import 'services/user_service.dart';

class CoinSellerScreen extends StatefulWidget {
  const CoinSellerScreen({Key? key}) : super(key: key);

  @override
  State<CoinSellerScreen> createState() => _CoinSellerScreenState();
}

class _CoinSellerScreenState extends State<CoinSellerScreen> {
  final UserService _user = UserService();
  String _sellerLevel = 'Beginner Seller';
  String _selectedPaymentMethod = 'Telebirr';

  void _openTransferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SellerTransferSheet(),
    );
  }

  void _openRechargeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SellerRechargeSheet(),
    );
  }

  void _openExchangeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SellerExchangeSheet(),
    );
  }

  void _selectPaymentMethodDialog() {
    final methods = ['Telebirr', 'Binance', 'USDT', 'CBE', 'VISA'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...methods.map((m) => ListTile(
                title: Text(m, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: _selectedPaymentMethod == m ? const Icon(Icons.check_circle, color: Color(0xFF00C9A7)) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = m);
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        );
      },
    );
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
        title: const Text('Coin Seller', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Seller Profile
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.amber,
                  child: Text(
                    _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'S',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_user.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),

const SizedBox(height: 3),
                      Text('ID: ${_user.userId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9A7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: const Text('Level Up', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Current level: $_sellerLevel', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 16),

            // Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      const Text('Balance', style: TextStyle(fontSize: 14, color: Colors.black54)),
                      const Spacer(),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.amber),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        onPressed: () {},
                        child: const Text('Details', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${_user.coins}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  const Divider(color: Colors.black12, height: 24),
                  GestureDetector(
                    onTap: _selectPaymentMethodDialog,
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(_selectedPaymentMethod, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Three Main Action Buttons (Transfer, Recharge, Exchange)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(icon: Icons.send_to_mobile, label: 'Transfer', onTap: _openTransferSheet),
                _buildActionButton(icon: Icons.add_card, label: 'Recharge', onTap: _openRechargeSheet),
                _buildActionButton(icon: Icons.currency_exchange, label: 'Exchange', onTap: _openExchangeSheet),
              ],
            ),
            const SizedBox(height: 24),

// Greeting Message Settings Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Text('Greeting Message Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7F4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF00C9A7), size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. TRANSFER SHEET (TRANSFER TO USER / COINSELLER)
// ---------------------------------------------------------------------------
class SellerTransferSheet extends StatefulWidget {
  const SellerTransferSheet({Key? key}) : super(key: key);

  @override
  State<SellerTransferSheet> createState() => _SellerTransferSheetState();
}

class _SellerTransferSheetState extends State<SellerTransferSheet> {
  bool _isTransferToUser = true;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Transfer Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Sales Method: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('User'),
                selected: _isTransferToUser,
                selectedColor: const Color(0xFF00C9A7),
                onSelected: (val) => setState(() => _isTransferToUser = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Coinseller'),
                selected: !_isTransferToUser,
                selectedColor: const Color(0xFF00C9A7),
                onSelected: (val) => setState(() => _isTransferToUser = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _idController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isTransferToUser ? 'User ID' : 'Coinseller ID',

suffixIcon: TextButton(onPressed: () {}, child: const Text('Check', style: TextStyle(color: Color(0xFF00C9A7)))),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Coin Amount (x1,000)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Please enter a multiple of 1,000', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {},
              child: const Text('Transfer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. RECHARGE SHEET (WHOLESALE COINS FOR SELLERS)
// ---------------------------------------------------------------------------
class SellerRechargeSheet extends StatelessWidget {
  const SellerRechargeSheet({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _wholesaleTiers = const [
    {'coins': '1,980,000', 'price': '\$200', 'badge': 'Standard Seller'},
    {'coins': '9,900,000', 'price': '\$1000', 'badge': 'Standard Seller'},
    {'coins': '14,850,000', 'price': '\$1500', 'badge': 'Senior Seller'},
    {'coins': '30,000,000', 'price': '\$3000', 'badge': 'Senior Seller'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Wholesale Recharge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              itemCount: _wholesaleTiers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (ctx, idx) {
                final item = _wholesaleTiers[idx];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['badge'], style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),

Text(item['coins'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(item['price'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {},
              child: const Text('Recharge Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. EXCHANGE SHEET (POINTS TO COINS)
// ---------------------------------------------------------------------------
class SellerExchangeSheet extends StatelessWidget {
  const SellerExchangeSheet({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _exchangeTiers = const [
    {'coins': '960,000', 'points': '1,000,000', 'level': 'Standard Seller'},
    {'coins': '1,960,000', 'points': '2,000,000', 'level': 'Standard Seller'},
    {'coins': '9,800,000', 'points': '10,000,000', 'level': 'Standard Seller'},
    {'coins': '30,000,000', 'points': '30,000,000', 'level': 'Senior Seller'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Exchange Points to Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              itemCount: _exchangeTiers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (ctx, idx) {
                final item = _exchangeTiers[idx];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['level'], style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('${item['coins']} Coins', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${item['points']} Pts', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                );

},
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {},
              child: const Text('Exchange', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
