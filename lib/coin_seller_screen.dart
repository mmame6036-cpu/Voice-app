import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';

class CoinSellerScreen extends StatefulWidget {
  const CoinSellerScreen({Key? key}) : super(key: key);

  @override
  State<CoinSellerScreen> createState() => _CoinSellerScreenState();
}

class _CoinSellerScreenState extends State<CoinSellerScreen> {
  final UserService _user = UserService();
  final String _sellerLevel = 'Standard Seller';
  String _selectedPaymentMethod = 'Binance Pay';
  String _greetingMessage = 'Welcome to Nile Voice Official Coin Store!';

  final String _telebirrPhone = '0943724560';
  final String _binanceUid = '1059643208';

  @override
  void initState() {
    super.initState();
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    try {
      final res = await http.get(
        Uri.parse('${UserService.serverUrl}/api/search-user?userId=${_user.userId}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['user'] != null && mounted) {
          setState(() {
            _user.coins = data['user']['coins'] ?? _user.coins;
            _user.points = data['user']['points'] ?? _user.points;
          });
        }
      }
    } catch (_) {}
  }

  void _openTransferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellerTransferSheet(
        agentId: _user.userId,
        currentCoins: _user.coins,
        onTransferSuccess: _refreshUserData,
      ),
    );
  }

  void _openRechargeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellerRechargeSheet(
        telebirrPhone: _telebirrPhone,
        binanceUid: _binanceUid,
        userId: _user.userId,
        userName: _user.userName,
      ),
    );
  }

  void _openExchangeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellerExchangeSheet(
        userId: _user.userId,
        currentPoints: _user.points,
        onExchangeSuccess: _refreshUserData,
      ),
    );
  }

  void _openAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPaymentScreen()),
    );
  }

  void _showTransactionDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsSheet(userId: _user.userId),
    );
  }

  void _showLevelUpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('Seller Level', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Tier: Standard Seller',
              style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            const Text(
              'To upgrade to Senior Seller:\n• Transfer over 10,000,000 coins monthly\n• Enjoy wholesale discounts & priority verification.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),

),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGreetingSettings() {
    final controller = TextEditingController(text: _greetingMessage);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFF141620),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFFFFD700), width: 1.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Greeting Message Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter greeting message for buyers...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1D2B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  onPressed: () {
                    setState(() => _greetingMessage = controller.text.trim());
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Greeting message saved!'), backgroundColor: Color(0xFF00C9A7)),
                    );
                  },
                  child: const Text('Save Message', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF161824),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 14),

ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedPaymentMethod == 'Telebirr' ? const Color(0xFF00C9A7) : Colors.white12,
                  ),
                ),
                tileColor: const Color(0xFF1E212D),
                leading: const Icon(Icons.phone_android, color: Color(0xFF00C9A7)),
                title: const Text('Telebirr', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('Phone: $_telebirrPhone', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: _selectedPaymentMethod == 'Telebirr' ? const Icon(Icons.check_circle, color: Color(0xFF00C9A7)) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'Telebirr');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedPaymentMethod == 'Binance Pay' ? const Color(0xFFFFD700) : Colors.white12,
                  ),
                ),
                tileColor: const Color(0xFF1E212D),
                leading: const Icon(Icons.currency_bitcoin, color: Color(0xFFFFD700)),
                title: const Text('Binance Pay', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('UID: $_binanceUid', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: _selectedPaymentMethod == 'Binance Pay' ? const Icon(Icons.check_circle, color: Color(0xFFFFD700)) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'Binance Pay');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141D),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Coin Seller',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD700), size: 22),
            onPressed: _refreshUserData,
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFFFD700), size: 24),
            onPressed: _openAdminPanel,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B1E2B), Color(0xFF13151F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),

],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFFFD700),
                      child: Text(
                        _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user.userName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text('ID: ${_user.userId}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        const SizedBox(height: 2),
                        Text(
                          'Level: $_sellerLevel',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                    ),
                    onPressed: _showLevelUpDialog,
                    child: const Text('Level Up', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF242017), Color(0xFF171618)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Total Balance',
                        style: TextStyle(fontSize: 13, color: Color(0xFFFFE082), fontWeight: FontWeight.w600),

),
                      const Spacer(),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFD700)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        ),
                        onPressed: _showTransactionDetails,
                        child: const Text('Details', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_user.coins}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD700),
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(color: Color(0x66FFD700), blurRadius: 10, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Coins',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 22),
                  GestureDetector(
                    onTap: _selectPaymentMethodDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Color(0xFFFFD700), size: 18),
                          const SizedBox(width: 8),
                          const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Spacer(),
                          Text(_selectedPaymentMethod, style: const TextStyle(fontSize: 11, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionItem(icon: Icons.send_to_mobile, label: 'Transfer', onTap: _openTransferSheet),
                _buildActionItem(icon: Icons.add_card, label: 'Recharge', onTap: _openRechargeSheet),
                _buildActionItem(icon: Icons.currency_exchange, label: 'Exchange', onTap: _openExchangeSheet),
              ],
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _showGreetingSettings,
              child: Container(

padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141620),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Text('Greeting Message Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF262217), Color(0xFF171616)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. RECHARGE SHEET
// ---------------------------------------------------------------------------
class SellerRechargeSheet extends StatefulWidget {
  final String telebirrPhone;
  final String binanceUid;
  final String userId;
  final String userName;

  const SellerRechargeSheet({
    Key? key,
    required this.telebirrPhone,
    required this.binanceUid,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<SellerRechargeSheet> createState() => _SellerRechargeSheetState();
}

class _SellerRechargeSheetState extends State<SellerRechargeSheet> {
  int _selectedTierIndex = 0;
  String _payMethod = 'Binance';

  final List<Map<String, dynamic>> _wholesaleTiers = const [
    {'coins': '1,980,000', 'priceUsd': '\$200', 'priceEtb': '24,000 ETB', 'badge': 'Standard Seller', 'amountUsd': 200, 'amountCoins': 1980000},
    {'coins': '9,900,000', 'priceUsd': '\$1000', 'priceEtb': '120,000 ETB', 'badge': 'Standard Seller', 'amountUsd': 1000, 'amountCoins': 9900000},
    {'coins': '14,850,000', 'priceUsd': '\$1500', 'priceEtb': '180,000 ETB', 'badge': 'Senior Seller', 'amountUsd': 1500, 'amountCoins': 14850000},
    {'coins': '30,000,000', 'priceUsd': '\$3000', 'priceEtb': '360,000 ETB', 'badge': 'Senior Seller', 'amountUsd': 3000, 'amountCoins': 30000000},
  ];

  void _proceedToPayment() {
    final selectedTier = _wholesaleTiers[_selectedTierIndex];
    Navigator.pop(context);

    if (_payMethod == 'Binance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BinancePaymentScreen(
            userId: widget.userId,
            userName: widget.userName,
            coinQuantity: selectedTier['coins'],
            priceUsd: selectedTier['priceUsd'],
            orderAmount: selectedTier['amountCoins'].toString(),
            amountCoins: selectedTier['amountCoins'],
          ),
        ),
      );

} else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TelebirrPaymentScreen(
            userId: widget.userId,
            userName: widget.userName,
            telebirrPhone: widget.telebirrPhone,
            priceEtb: selectedTier['priceEtb'],
            coinQuantity: selectedTier['coins'],
            amountCoins: selectedTier['amountCoins'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141620),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFFFD700), width: 1.5)),
        boxShadow: [
          BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Wholesale Recharge',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _wholesaleTiers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final item = _wholesaleTiers[idx];
                final isSelected = _selectedTierIndex == idx;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTierIndex = idx),
                  child: Container(
                    width: 105,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2C2619) : const Color(0xFF1E212D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
                        width: isSelected ? 1.8 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['badge'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 8, color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['coins'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,

color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _payMethod == 'Telebirr' ? item['priceEtb'] : item['priceUsd'],
                          style: const TextStyle(fontSize: 9, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _payMethod = 'Telebirr'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _payMethod == 'Telebirr' ? const Color(0xFF00C9A7) : const Color(0xFF1E212D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _payMethod == 'Telebirr' ? const Color(0xFF00C9A7) : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Telebirr',
                        style: TextStyle(
                          color: _payMethod == 'Telebirr' ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _payMethod = 'Binance'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _payMethod == 'Binance' ? const Color(0xFFFFD700) : const Color(0xFF1E212D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _payMethod == 'Binance' ? const Color(0xFFFFD700) : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Binance Pay',
                        style: TextStyle(
                          color: _payMethod == 'Binance' ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 4,
              ),
              onPressed: _proceedToPayment,
              child: Text(
                'Proceed with $_payMethod',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. BINANCE PAYMENT SCREEN
// ---------------------------------------------------------------------------
class BinancePaymentScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String coinQuantity;
  final String priceUsd;
  final String orderAmount;
  final int amountCoins;

const BinancePaymentScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.coinQuantity,
    required this.priceUsd,
    required this.orderAmount,
    required this.amountCoins,
  }) : super(key: key);

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label Copied!')));
  }

  Future<void> _submitBinancePayment(BuildContext context, String orderId) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/recharge-request');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'paymentMethod': 'Binance Pay',
          'txId': orderId,
          'amountCoins': amountCoins,
          'pricePaid': priceUsd,
        }),
      );
      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Binance Payment Submitted Successfully! Awaiting Verification.'),
            backgroundColor: Color(0xFF00C9A7),
          ),
        );
      }
    } catch (_) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String orderId = 'BIN${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141620),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Binance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF161824),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.currency_bitcoin, color: Color(0xFFFFD700), size: 36),
                  const SizedBox(height: 6),
                  const Text('Binance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  const Text('Scan to pay', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 10),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/binance_qr.png',
                      height: 140,
                      width: 140,
                      fit: BoxFit.contain,

errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.qr_code_2,
                        size: 140,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Order ID: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Flexible(
                        child: Text(
                          orderId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 14, color: Color(0xFFFFD700)),
                        onPressed: () => _copy(context, orderId, 'Order ID'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161824),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildDetailRow('User ID', userId),
                  const Divider(color: Colors.white10, height: 16),
                  _buildDetailRow('Quantity', priceUsd),
                  const Divider(color: Colors.white10, height: 16),
                  _buildDetailRow('Order Amount', orderAmount, isGold: true),
                  const Divider(color: Colors.white10, height: 16),
                  _buildDetailRow('Date', '2026-10-15 05:48:03'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
                onPressed: () => _submitBinancePayment(context, orderId),
                child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isGold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: isGold ? const Color(0xFFFFD700) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. TELEBIRR PAYMENT SCREEN
// ---------------------------------------------------------------------------
class TelebirrPaymentScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String telebirrPhone;
  final String priceEtb;
  final String coinQuantity;
  final int amountCoins;

  const TelebirrPaymentScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.telebirrPhone,
    required this.priceEtb,
    required this.coinQuantity,
    required this.amountCoins,
  }) : super(key: key);

void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label Copied!')));
  }

  Future<void> _submitTelebirrPayment(BuildContext context, String txId) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/recharge-request');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'paymentMethod': 'Telebirr',
          'txId': txId.trim(),
          'amountCoins': amountCoins,
          'pricePaid': priceEtb,
        }),
      );
      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recharge Request Submitted Successfully!'),
            backgroundColor: Color(0xFF00C9A7),
          ),
        );
      }
    } catch (_) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController txController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141620),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Telebirr Payment', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161824),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Details', style: TextStyle(color: Color(0xFF00C9A7), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Receiver: $telebirrPhone', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF00C9A7), size: 18),
                        onPressed: () => _copy(context, telebirrPhone, 'Phone Number'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Amount: $priceEtb', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Coins to receive: $coinQuantity', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: txController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Transaction ID',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF161824),

border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  if (txController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter transaction ID')),
                    );
                    return;
                  }
                  _submitTelebirrPayment(context, txController.text);
                },
                child: const Text('Confirm Payment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. ADMIN PAYMENT SCREEN
// ---------------------------------------------------------------------------
class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({Key? key}) : super(key: key);

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  bool _isLoading = true;
  List<dynamic> _pendingList = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingPayments();
  }

  Future<void> _fetchPendingPayments() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/admin/pending-payments');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _pendingList = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _approvePayment(String paymentId, int amountCoins, String userId) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/admin/approve-payment');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentId': paymentId}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Approved! Added $amountCoins coins to User $userId'),
              backgroundColor: const Color(0xFF00C9A7),
            ),
          );
          _fetchPendingPayments();
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve payment'), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D12),

appBar: AppBar(
        backgroundColor: const Color(0xFF141620),
        elevation: 0,
        title: const Text(
          'Admin Payment Approval',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
            onPressed: _fetchPendingPayments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : _pendingList.isEmpty
              ? const Center(
                  child: Text(
                    'No pending payment requests',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: _pendingList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final item = _pendingList[idx];
                    final String paymentId = item['_id'] ?? '';
                    final String userId = item['userId'] ?? 'Unknown';
                    final String userName = item['userName'] ?? 'User';
                    final String method = item['paymentMethod'] ?? 'Telebirr';
                    final String txId = item['txId'] ?? '';
                    final int coins = item['amountCoins'] ?? 0;
                    final String price = item['pricePaid'] ?? '';
                    final bool isBinance = method.toLowerCase().contains('binance');

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161824),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBinance ? const Color(0xFFFFD700).withOpacity(0.5) : const Color(0xFF00C9A7).withOpacity(0.5),
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isBinance ? const Color(0xFF332A15) : const Color(0xFF113028),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  method,
                                  style: TextStyle(
                                    color: isBinance ? const Color(0xFFFFD700) : const Color(0xFF00C9A7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                price,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),

),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'User: $userName (ID: $userId)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coins to add: $coins Coins',
                            style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('TxID: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              Expanded(
                                child: Text(
                                  txId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                                onPressed: () => _copyToClipboard(txId, 'TxID'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C9A7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.check, color: Colors.black, size: 18),
                                  label: const Text(
                                    'Approve',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _approvePayment(paymentId, coins, userId),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. TRANSFER SHEET
// ---------------------------------------------------------------------------
class SellerTransferSheet extends StatefulWidget {
  final String agentId;
  final int currentCoins;
  final VoidCallback onTransferSuccess;

  const SellerTransferSheet({
    Key? key,
    required this.agentId,
    required this.currentCoins,
    required this.onTransferSuccess,
  }) : super(key: key);

  @override
  State<SellerTransferSheet> createState() => _SellerTransferSheetState();
}

class _SellerTransferSheetState extends State<SellerTransferSheet> {
  bool _isTransferToUser = true;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isTransferring = false;
  String? _verifiedUserName;

  Future<void> _checkRecipient() async {
    final targetId = _idController.text.trim();
    if (targetId.isEmpty) return;

try {
      final res = await http.get(
        Uri.parse('${UserService.serverUrl}/api/search-user?userId=$targetId'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['user'] != null) {
          setState(() {
            _verifiedUserName = data['user']['name'] ?? 'User';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User found: $_verifiedUserName (ID: $targetId)'),
                backgroundColor: const Color(0xFF00C9A7),
              ),
            );
          }
          return;
        }
      }
      if (mounted) {
        setState(() => _verifiedUserName = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (_) {}
  }

  Future<void> _executeTransfer() async {
    final targetId = _idController.text.trim();
    final amountText = _amountController.text.trim();

    if (targetId.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final int? amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid coin amount')),
      );
      return;
    }

    if (amount > widget.currentCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient coin balance!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isTransferring = true);

    try {
      final res = await http.post(
        Uri.parse('${UserService.serverUrl}/api/wallet/agent-transfer-coins'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'agentId': widget.agentId,
          'targetUserId': targetId,
          'amountCoins': amount,
        }),
      );

      final data = jsonDecode(res.body);

      if (mounted) {
        if (res.statusCode == 200 && data['success'] == true) {
          Navigator.pop(context);
          widget.onTransferSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Coins Transferred Successfully!'),
              backgroundColor: const Color(0xFF00C9A7),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Transfer failed'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFF141620),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFFFD700), width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Transfer Coins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
              const Spacer(),

IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Sales Method: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('User'),
                selected: _isTransferToUser,
                selectedColor: const Color(0xFFFFD700),
                onSelected: (val) => setState(() => _isTransferToUser = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Coinseller'),
                selected: !_isTransferToUser,
                selectedColor: const Color(0xFFFFD700),
                onSelected: (val) => setState(() => _isTransferToUser = false),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _idController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isTransferToUser ? 'User ID' : 'Coinseller ID',
              labelStyle: const TextStyle(color: Colors.white54),
              suffixIcon: TextButton(
                onPressed: _checkRecipient,
                child: const Text('Check', style: TextStyle(color: Color(0xFFFFD700))),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFF1A1D2B),
            ),
          ),
          if (_verifiedUserName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Recipient: $_verifiedUserName',
              style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Coin Amount (x1,000)',
              labelStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFF1A1D2B),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Please enter a multiple of 1,000', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              ),
              onPressed: _isTransferring ? null : _executeTransfer,
              child: _isTransferring
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Text('Transfer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. EXCHANGE SHEET (Fully Interactive)
// ---------------------------------------------------------------------------
class SellerExchangeSheet extends StatefulWidget {
  final String userId;
  final int currentPoints;
  final VoidCallback onExchangeSuccess;

const SellerExchangeSheet({
    Key? key,
    required this.userId,
    required this.currentPoints,
    required this.onExchangeSuccess,
  }) : super(key: key);

  @override
  State<SellerExchangeSheet> createState() => _SellerExchangeSheetState();
}

class _SellerExchangeSheetState extends State<SellerExchangeSheet> {
  int _selectedIndex = 0;
  bool _isExchanging = false;

  final List<Map<String, dynamic>> _exchangeTiers = const [
    {'coins': '960,000', 'points': '1,000,000', 'ptsValue': 1000000, 'coinValue': 960000, 'level': 'Standard Seller'},
    {'coins': '1,960,000', 'points': '2,000,000', 'ptsValue': 2000000, 'coinValue': 1960000, 'level': 'Standard Seller'},
    {'coins': '9,800,000', 'points': '10,000,000', 'ptsValue': 10000000, 'coinValue': 9800000, 'level': 'Standard Seller'},
    {'coins': '30,000,000', 'points': '30,000,000', 'ptsValue': 30000000, 'coinValue': 30000000, 'level': 'Senior Seller'},
  ];

  Future<void> _processExchange() async {
    final selected = _exchangeTiers[_selectedIndex];
    final int requiredPts = selected['ptsValue'];

    if (widget.currentPoints < requiredPts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient points! You need ${selected['points']} Pts to exchange.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isExchanging = true);
    // Simulated Exchange API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isExchanging = false);
      Navigator.pop(context);
      widget.onExchangeSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully exchanged ${selected['points']} Pts for ${selected['coins']} Coins!'),
          backgroundColor: const Color(0xFF00C9A7),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFF141620),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFFFD700), width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Exchange Points to Coins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              itemCount: _exchangeTiers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (ctx, idx) {
                final item = _exchangeTiers[idx];
                final isSelected = _selectedIndex == idx;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = idx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2C2619) : const Color(0xFF1A1D2B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFFD700) : Colors.white10,

width: isSelected ? 1.8 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            blurRadius: 8,
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item['level'], style: const TextStyle(fontSize: 9, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${item['coins']} Coins',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('${item['points']} Pts', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              ),
              onPressed: _isExchanging ? null : _processExchange,
              child: _isExchanging
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Exchange', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. TRANSACTION DETAILS SHEET
// ---------------------------------------------------------------------------
class TransactionDetailsSheet extends StatelessWidget {
  final String userId;

  const TransactionDetailsSheet({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFF141620),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFFFD700), width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              const Text('Transaction Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                _buildTxItem('Wholesale Recharge', '+1,980,000 Coins', 'Binance Pay', 'Approved', true),
                _buildTxItem('Agent Transfer to User 1002', '-10,000 Coins', 'Direct Sale', 'Completed', false),
                _buildTxItem('Welcome Bonus', '+1,000 Coins', 'System', 'Completed', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildTxItem(String title, String amount, String method, String status, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.arrow_downward : Icons.arrow_upward,
            color: isPositive ? const Color(0xFF00C9A7) : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('$method • $status', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? const Color(0xFFFFD700) : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
