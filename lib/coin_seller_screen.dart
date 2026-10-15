import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/user_service.dart';

class CoinSellerScreen extends StatefulWidget {
  const CoinSellerScreen({Key? key}) : super(key: key);

  @override
  State<CoinSellerScreen> createState() => _CoinSellerScreenState();
}

class _CoinSellerScreenState extends State<CoinSellerScreen> {
  final UserService _user = UserService();
  final String _sellerLevel = 'Standard Seller';
  String _selectedPaymentMethod = 'Telebirr';

  // የክፍያ መረጃዎች
  final String _telebirrPhone = '0943724560';
  final String _binanceUid = '1059643208';

  void _openTransferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SellerTransferSheet(),
    );
  }

  // በቀጥታ አዲሱን Recharge Sheet ይከፍታል
  void _openRechargeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellerRechargeSheet(
        telebirrPhone: _telebirrPhone,
        binanceUid: _binanceUid,
      ),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('የመክፈያ መንገድ ይምረጡ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.black12)),
                leading: const Icon(Icons.phone_android, color: Colors.blueAccent),
                title: const Text('Telebirr (ቴሌብር)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ስልክ: $_telebirrPhone'),
                trailing: _selectedPaymentMethod == 'Telebirr' ? const Icon(Icons.check_circle, color: Color(0xFF00C9A7)) : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'Telebirr');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.black12)),
                leading: const Icon(Icons.currency_bitcoin, color: Colors.amber),
                title: const Text('Binance Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('UID: $_binanceUid'),
                trailing: _selectedPaymentMethod == 'Binance Pay' ? const Icon(Icons.check_circle, color: Color(0xFF00C9A7)) : null,
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
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Coin Seller', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 19)),
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
            // Top Profile Card (3D)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.amber,
                      child: Text(
                        _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_user.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 3),
                        Text('ID: ${_user.userId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('Level: $_sellerLevel', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 3,
                    ),
                    onPressed: () {},
                    child: const Text('Level Up', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3D Balance Card (የኮይኑ ቁጥር በደማቅ አረንጓዴ)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFDF7), Color(0xFFFFF8E7)],
                  begin: Alignment.topLeft,

end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amber.withOpacity(0.35), width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8)),
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.monetization_on, color: Colors.amber, size: 22),
                      ),
                      const SizedBox(width: 8),
                      const Text('Total Balance', style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
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
                  const SizedBox(height: 12),
                  // ሳንቲም በአረንጓዴ ቁጥር
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_user.coins}',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00A884), // ደማቅ አረንጓዴ
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(color: Color(0x3300A884), blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Coins',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black12, height: 26),
                  GestureDetector(
                    onTap: _selectPaymentMethodDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.04)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),

const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(_selectedPaymentMethod, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Three Main Action Buttons (3D Rounded Buttons)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _build3DActionButton(icon: Icons.send_to_mobile, label: 'Transfer', onTap: _openTransferSheet),
                _build3DActionButton(icon: Icons.add_card, label: 'Recharge', onTap: _openRechargeSheet),
                _build3DActionButton(icon: Icons.currency_exchange, label: 'Exchange', onTap: _openExchangeSheet),
              ],
            ),
            const SizedBox(height: 24),

            // Greeting Message Settings
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                children: [
                  Text('Greeting Message Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
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

  Widget _build3DActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8FAF6), Color(0xFFD3F5EF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF00C9A7).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 5)),
                const BoxShadow(color: Colors.white, blurRadius: 4, offset: Offset(-2, -2)),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF009E83), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. TRANSFER SHEET
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
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Transfer Coins', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Coin Amount (x1,000)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Please enter a multiple of 1,000', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00C9A7).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coins Transferred Successfully!')),
                );
              },
              child: const Text('Transfer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. RECHARGE SHEET (TELEBIRR PHONE + BINANCE QR & UID)
// ---------------------------------------------------------------------------
class SellerRechargeSheet extends StatefulWidget {
  final String telebirrPhone;
  final String binanceUid;

  const SellerRechargeSheet({
    Key? key,
    required this.telebirrPhone,
    required this.binanceUid,
  }) : super(key: key);

  @override
  State<SellerRechargeSheet> createState() => _SellerRechargeSheetState();
}

class _SellerRechargeSheetState extends State<SellerRechargeSheet> {
  int _selectedTierIndex = 0;
  String _payMethod = 'Telebirr';
  final TextEditingController _txIdController = TextEditingController();

  final List<Map<String, dynamic>> _wholesaleTiers = const [
    {'coins': '1,980,000', 'priceUsd': '\$200', 'priceEtb': '24,000 ETB', 'badge': 'Standard Seller'},
    {'coins': '9,900,000', 'priceUsd': '\$1000', 'priceEtb': '120,000 ETB', 'badge': 'Standard Seller'},
    {'coins': '14,850,000', 'priceUsd': '\$1500', 'priceEtb': '180,000 ETB', 'badge': 'Senior Seller'},
    {'coins': '30,000,000', 'priceUsd': '\$3000', 'priceEtb': '360,000 ETB', 'badge': 'Senior Seller'},
  ];

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label ኮፒ ተደርጓል!')));
  }

  @override
  Widget build(BuildContext context) {
    final selectedTier = _wholesaleTiers[_selectedTierIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Wholesale Recharge (ሳንቲም በጅምላ መሙያ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),

          // 1. የጥቅል ካርዶች
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _wholesaleTiers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final item = _wholesaleTiers[idx];
                final isSelected = _selectedTierIndex == idx;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTierIndex = idx),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FAF8) : const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00C9A7) : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? const Color(0xFF00C9A7).withOpacity(0.2) : Colors.black.withOpacity(0.02),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),

child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item['badge'], style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          item['coins'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF00A884) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _payMethod == 'Telebirr' ? item['priceEtb'] : item['priceUsd'],
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 2. የመክፈያ መንገድ መምረጫ
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('ቴሌብር (Telebirr)')),
                  selected: _payMethod == 'Telebirr',
                  selectedColor: const Color(0xFF00C9A7),
                  onSelected: (_) => setState(() => _payMethod = 'Telebirr'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Binance Pay')),
                  selected: _payMethod == 'Binance',
                  selectedColor: Colors.amber,
                  onSelected: (_) => setState(() => _payMethod = 'Binance'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. የክፍያ መረጃ ሳጥን
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: _payMethod == 'Telebirr'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('በቴሌብር ለመክፈል፦', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ስልክ ቁጥር: ${widget.telebirrPhone}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20, color: Color(0xFF00C9A7)),
                            onPressed: () => _copy(widget.telebirrPhone, 'የቴሌብር ስልክ ቁጥር'),
                          ),
                        ],
                      ),
                      Text('የሚከፍሉት፦ ${selectedTier['priceEtb']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('በባይናንስ ለመክፈል፦', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(height: 6),

// QR Code Card
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade400, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/binance_qr.png',
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.qr_code_2,
                            size: 80,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text('በ Binance App ስካን (Scan) አድርገው ይክፈሉ', style: TextStyle(fontSize: 10, color: Colors.black54)),
                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Binance UID: ${widget.binanceUid}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18, color: Colors.amber),
                            onPressed: () => _copy(widget.binanceUid, 'Binance UID'),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('የሚከፍሉት፦ ${selectedTier['priceUsd']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13)),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),

          // 4. ማረጋገጫ ማስገቢያ
          TextField(
            controller: _txIdController,
            decoration: InputDecoration(
              labelText: _payMethod == 'Telebirr' ? 'የቴሌብር ግብይት ቁጥር (Transaction ID)' : 'የባይናንስ TxID / Order ID',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const Spacer(),

          // Confirm Button
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00C9A7).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              onPressed: () {
                if (_txIdController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('እባክዎ የግብይት ማረጋገጫ ቁጥሩን ያስገቡ!')),
                  );
                  return;
                }
                Navigator.pop(context);

ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('የጅምላ ግዢ ጥያቄዎ ደርሷል፤ ተረጋግጦ ይሞላልዎታል!')),
                );
              },
              child: const Text('ክፍያውን አረጋግጥ (Confirm)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. EXCHANGE SHEET
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
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -6)),
        ],
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
                    color: const Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['level'], style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        '${item['coins']} Coins',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                      ),
                      const SizedBox(height: 4),
                      Text('${item['points']} Pts', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),

boxShadow: [
                BoxShadow(color: const Color(0xFF00C9A7).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
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
