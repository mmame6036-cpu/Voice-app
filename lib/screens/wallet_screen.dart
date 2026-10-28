import 'package:flutter/material.dart';

class CoinPackage {
  final int coins;
  final String priceText;
  final String? bonus;

  const CoinPackage({
    required this.coins,
    required this.priceText,
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

  final List<CoinPackage> _packages = const [
    CoinPackage(coins: 1000, priceText: "ETB 100", bonus: null),
    CoinPackage(coins: 5500, priceText: "ETB 500", bonus: "+500 Free"),
    CoinPackage(coins: 12000, priceText: "ETB 1,000", bonus: "+2,000 Free"),
    CoinPackage(coins: 38000, priceText: "ETB 3,000", bonus: "+8,000 Free"),
    CoinPackage(coins: 65000, priceText: "ETB 5,000", bonus: "+15,000 Free"),
    CoinPackage(coins: 140000, priceText: "ETB 10,000", bonus: "+40,000 Free"),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _diamonds = widget.currentDiamonds;
  }

  void _handleRecharge() {
    final selectedPkg = _packages[_selectedPackageIndex];
    setState(() {
      _coins += selectedPkg.coins;
    });
    widget.onCoinsRecharged(_coins);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text("Recharge Successful", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          "Successfully added ${selectedPkg.coins} Coins to your wallet!",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
            // Balance Card
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
              "Select Recharge Package",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 14),

            // Packages Grid
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
                        color: isSelected ? const Color(0xFFFFD700) : Colors.white10,
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
                          pkg.priceText,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFFFD700) : Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 5,
                ),
                onPressed: _handleRecharge,
                child: const Text(
                  "Confirm Recharge",
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
