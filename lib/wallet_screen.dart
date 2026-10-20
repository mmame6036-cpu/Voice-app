import 'package:flutter/material.dart';
import 'services/user_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  late TabController _tabController;
  int _selectedPackageIndex = 0;
  String _selectedPaymentMethod = 'Telebirr';

  final List<Map<String, dynamic>> _coinPackages = [
    {'coins': 100, 'priceBirr': 50, 'bonus': 0},
    {'coins': 500, 'priceBirr': 240, 'bonus': 20},
    {'coins': 1200, 'priceBirr': 550, 'bonus': 100},
    {'coins': 3000, 'priceBirr': 1300, 'bonus': 350},
    {'coins': 7000, 'priceBirr': 2900, 'bonus': 1000},
    {'coins': 15000, 'priceBirr': 6000, 'bonus': 2500},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _processPayment() {
    final pkg = _coinPackages[_selectedPackageIndex];
    final totalCoins = (pkg['coins'] as int) + (pkg['bonus'] as int);
    final price = pkg['priceBirr'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2236),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$_selectedPaymentMethod Payment',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Do you want to pay $price ETB to purchase $totalCoins coins?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _user.coins += totalCoins;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('+$totalCoins coins added successfully! 🎉'),
                  backgroundColor: const Color(0xFF00C9A7),
                ),
              );
            },
            child: const Text('Pay Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D101D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131728),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00C9A7),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00C9A7),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Coins'),
            Tab(text: 'Earnings (Diamonds)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCoinsTab(),
          _buildDiamondsTab(),
        ],
      ),
    );
  }

Widget _buildCoinsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E245E), Color(0xFF4A3E8F)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Coin Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '${_user.coins}',
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Select Payment Method',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildPaymentOption('Telebirr', Icons.phone_android, const Color(0xFF007ECC)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentOption('CBE Birr', Icons.account_balance, const Color(0xFF8B2671)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const Text(
          'Coin Packages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _coinPackages.length,
          itemBuilder: (ctx, i) {
            final pkg = _coinPackages[i];
            final isSel = _selectedPackageIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedPackageIndex = i),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF1E2842) : const Color(0xFF131728),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? const Color(0xFF00C9A7) : Colors.white10,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${pkg['coins']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    if (pkg['bonus'] > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${pkg['bonus']} Bonus',
                          style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${pkg['priceBirr']} ETB',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _processPayment,
            child: const Text(
              'Recharge Now',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String name, IconData icon, Color color) {
    final isSel = _selectedPaymentMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = name),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? color.withOpacity(0.2) : const Color(0xFF131728),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? color : Colors.white12, width: isSel ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiamondsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3B4F), Color(0xFF15657E)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Total Diamonds Earned', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.diamond, color: Colors.cyanAccent, size: 28),
                        SizedBox(width: 8),
                        Text(

'0',
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Minimum withdrawal threshold is 5,000 Diamonds.')),
                    );
                  },
                  child: const Text('Withdraw', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Earnings Rules:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• 70% of gift value is converted into diamonds for the receiver.\n• 1,000 Diamonds = 500 ETB.\n• Withdrawals are processed to Telebirr or Bank account within 24 hours.',
            style: TextStyle(color: Colors.white54, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
