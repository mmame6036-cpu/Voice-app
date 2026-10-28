import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoinPackage {
  final int coins;
  final String priceUsd;
  final String? bonus;

  const CoinPackage({
    required this.coins,
    required this.priceUsd,
    this.bonus,
  });
}

class WalletScreen extends StatefulWidget {
  final int currentCoins;
  final int currentDiamonds;
  final Function(int) onCoinsRecharged;

  const WalletScreen({
    super.key,
    required this.currentCoins,
    this.currentDiamonds = 0,
    required this.onCoinsRecharged,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late int _coins;
  late int _diamonds;
  int _selectedPackageIndex = 0;

  static const String binancePayId = "849201842";
  static const String usdtTrc20Address = "TXaB84KL92kLqP192MNbvRx782JqLkP12Z";

  final List<CoinPackage> _packages = const [
    CoinPackage(coins: 1000, priceUsd: "\$1.00", bonus: null),
    CoinPackage(coins: 5500, priceUsd: "\$5.00", bonus: "+500 Free"),
    CoinPackage(coins: 12000, priceUsd: "\$10.00", bonus: "+2,000 Free"),
    CoinPackage(coins: 38000, priceUsd: "\$30.00", bonus: "+8,000 Free"),
    CoinPackage(coins: 65000, priceUsd: "\$50.00", bonus: "+15,000 Free"),
    CoinPackage(coins: 140000, priceUsd: "\$100.00", bonus: "+40,000 Free"),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _diamonds = widget.currentDiamonds;
  }

  void _showBinancePaymentSheet(CoinPackage pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.currency_bitcoin, color: Color(0xFFF0B90B), size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Binance Pay / USDT",
                    style: TextStyle(
                      color: Color(0xFFF0B90B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recharge Package:", style: TextStyle(color: Colors.white70)),
                        Text("${pkg.coins} Coins",
                            style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(

mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Amount Due:", style: TextStyle(color: Colors.white70)),
                        Text("${pkg.priceUsd} (USDT)",
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Binance Pay ID", style: TextStyle(color: Colors.white60, fontSize: 12)),
                subtitle: const Text(binancePayId, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFFF0B90B)),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: binancePayId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Binance Pay ID copied!")),
                    );
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("USDT Deposit (TRC20)", style: TextStyle(color: Colors.white60, fontSize: 12)),
                subtitle: const Text(
                  usdtTrc20Address,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFFF0B90B)),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: usdtTrc20Address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("USDT Address copied!")),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0B90B),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Payment submitted. Coins will be credited once verified on blockchain!"),
                      ),
                    );
                  },
                  child: const Text("I Have Transferred", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141226),
        elevation: 0,
        title: const Text(
          "My Wallet",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(

padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E2452), Color(0xFF1B1633)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 22),
                          SizedBox(width: 6),
                          Text("Coins Balance", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$_coins",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 45, color: Colors.white12),
                  Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.diamond, color: Colors.cyanAccent, size: 22),
                          SizedBox(width: 6),
                          Text("Diamonds", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$_diamonds",
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Select Recharge Package (USDT)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _packages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final pkg = _packages[index];
                final isSelected = _selectedPackageIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedPackageIndex = index),
                  child: Container(

padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF261E47) : const Color(0xFF161329),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF0B90B) : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              "${pkg.coins}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (pkg.bonus != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pkg.bonus!,
                              style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          pkg.priceUsd,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFF0B90B) : Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0B90B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 5,
                ),
                onPressed: () => _showBinancePaymentSheet(_packages[_selectedPackageIndex]),
                child: const Text(
                  "Pay via Binance (USDT)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
