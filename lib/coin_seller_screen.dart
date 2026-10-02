import 'package:flutter/material.dart';

// ============================================================================
// 🪙 NILE VOICE - OFFICIAL COIN SELLER DASHBOARD
// ============================================================================
class CoinSellerScreen extends StatefulWidget {
  final int initialCoins;
  final Function(int) onCoinsUpdated;

  const CoinSellerScreen({
    Key? key,
    required this.initialCoins,
    required this.onCoinsUpdated,
  }) : super(key: key);

  @override
  State<CoinSellerScreen> createState() => _CoinSellerScreenState();
}

class _CoinSellerScreenState extends State<CoinSellerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _sellerBalance;
  double _sellerPoints = 45200.0;
  String _sellerLevel = "Senior Seller 🔰";

  // Transfer Controllers
  bool _isTransferToUser = true; // true = User, false = Coinseller
  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _coinAmountController = TextEditingController();
  String? _verifiedUserName;
  bool _isCheckingUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sellerBalance = widget.initialCoins;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _targetIdController.dispose();
    _coinAmountController.dispose();
    super.dispose();
  }

  // ተጠቃሚውን መፈተሻ (Check User ID)
  void _checkUserId() {
    String id = _targetIdController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎ የተጠቃሚውን መለያ (ID) ያስገቡ')),
      );
      return;
    }

    setState(() {
      _isCheckingUser = true;
      _verifiedUserName = null;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _isCheckingUser = false;
        if (id == "1000") {
          _verifiedUserName = "KEDIR (Master Admin)";
        } else if (id == "1001") {
          _verifiedUserName = "Abebe Bekele";
        } else if (id == "1002") {
          _verifiedUserName = "Fatima Mohammed";
        } else {
          _verifiedUserName = "Nile Member #$id";
        }
      });
    });
  }

  // ኮይን ማስተላለፊያ (Execute Transfer)
  void _executeTransfer() {
    String id = _targetIdController.text.trim();
    int? parsedCoins = int.tryParse(_coinAmountController.text.trim());

    if (id.isEmpty  parsedCoins == null  parsedCoins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎ ትክክለኛ መለያ (ID) እና የኮይን መጠን ያስገቡ')),
      );
      return;
    }

    int transferAmount = parsedCoins;

    if (transferAmount > _sellerBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('በቂ የኮይን ቀሪ ሂሳብ የለዎትም!'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('የኮይን ማስተላለፊያ ማረጋገጫ', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'ለተጠቃሚ፦ ${_verifiedUserName ?? id}\nየኮይን መጠን፦ $transferAmount ኮይን\n\nማስተላለፍ ይፈልጋሉ?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ይቅር', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7)),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sellerBalance = _sellerBalance - transferAmount;
              });
              widget.onCoinsUpdated(_sellerBalance);
              _coinAmountController.clear();

ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ለ ${_verifiedUserName ?? id} $transferAmount ኮይን በተሳካ ሁኔታ ተላልፏል!'),
                  backgroundColor: const Color(0xFF00C9A7),
                ),
              );
            },
            child: const Text('አረጋግጥ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Coin Seller Center', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= 1. የሴለር ዋና መረጃ ካርድ =================
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF00C9A7),
                        child: Icon(Icons.storefront, color: Colors.black, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NILE OFFICIAL SELLER',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            const Text('Merchant ID: 1000', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 3),
                            Text(
                              'Current level: $_sellerLevel',
                              style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9A7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                        onPressed: () {},
                        child: const Text('Level Up', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(

crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Balance', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '$_sellerBalance',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.amber),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {},
                        child: const Text('Details', style: TextStyle(color: Colors.amber, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2633),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.payment, color: Colors.orangeAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Payment Method (Telebirr, CBE, USDT)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2633),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.message, color: Color(0xFF00C9A7), size: 18),
                        SizedBox(width: 8),
                        Text('Greeting Message Settings', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= 2. ሶስቱ ታቦች (TabBar) =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00C9A7),
                labelColor: const Color(0xFF00C9A7),
                unselectedLabelColor: Colors.white54,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Transfer'),
                  Tab(text: 'Recharge'),
                  Tab(text: 'Exchange'),
                ],
              ),
            ),

// ================= 3. የታቦቹ ይዘት =================
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransferTab(),
                  _buildRechargeTab(),
                  _buildExchangeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: TRANSFER (ማስተላለፊያ)
  // -------------------------------------------------------------
  Widget _buildTransferTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Sales Method:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 14),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _isTransferToUser,
                    activeColor: const Color(0xFF00C9A7),
                    onChanged: (val) => setState(() => _isTransferToUser = val!),
                  ),
                  const Text('User', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: _isTransferToUser,
                    activeColor: const Color(0xFF00C9A7),
                    onChanged: (val) => setState(() => _isTransferToUser = val!),
                  ),
                  const Text('Coinseller', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _isTransferToUser ? 'Enter User ID' : 'Enter Coinseller ID',
                    filled: true,
                    fillColor: const Color(0xFF161B26),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2838),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isCheckingUser ? null : _checkUserId,
                child: _isCheckingUser
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C9A7)))
                    : const Text('Check', style: TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_verifiedUserName != null) ...[
            const SizedBox(height: 6),
            Text('✔ Verified: $_verifiedUserName', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          const Text('Coin Amount:', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _coinAmountController,
            keyboardType: TextInputType.number,

style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter amount (e.g. 10000)',
              prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber),
              filled: true,
              fillColor: const Color(0xFF161B26),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _executeTransfer,
            child: const Text('Transfer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Transfer Detail >', style: TextStyle(color: Color(0xFF00C9A7), fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: RECHARGE (ኮይን መሙያ / መግዣ)
  // -------------------------------------------------------------
  Widget _buildRechargeTab() {
    final bundles = [
      {'coins': '1,980,000', 'price': '\$200 (Standard)'},
      {'coins': '9,900,000', 'price': '\$1,000 (Standard)'},
      {'coins': '14,850,000', 'price': '\$1,500 (Standard)'},
      {'coins': '30,000,000', 'price': '\$3,000 (Senior)'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Official Recharge Bundles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bundles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) {
            final b = bundles[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(b['coins']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(b['price']!, style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 11)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2838),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,

children: [
              Text('Recharge Rules:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(height: 4),
              Text('• Beginner Seller: \$1 = 9,800 Coins', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text('• Standard Seller: \$1 = 9,900 Coins (Single recharge ≥ \$200)', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text('• Senior Seller: \$1 = 10,000 Coins (Single recharge ≥ \$1000)', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: EXCHANGE (ነጥብ ወደ ኮይን መቀየሪያ)
  // -------------------------------------------------------------
  Widget _buildExchangeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Points Balance:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Row(
                children: [
                  const Icon(Icons.diamond, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 6),
                  Text('$_sellerPoints', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Exchange to Coins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        _buildExchangeOption('960,000 Coins', '1,000,000 Points'),
        _buildExchangeOption('1,960,000 Coins', '2,000,000 Points'),
        _buildExchangeOption('9,800,000 Coins', '10,000,000 Points'),
        _buildExchangeOption('30,000,000 Coins', '30,000,000 Points (Full Rate)'),
      ],
    );
  }

  Widget _buildExchangeOption(String coins, String points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(coins, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exchange request submitted for $coins!')),
              );
            },
            child: Text(points, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
