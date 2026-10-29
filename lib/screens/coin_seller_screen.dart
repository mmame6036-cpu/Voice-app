import 'package:flutter/material.dart';

class CoinSellerScreen extends StatefulWidget {
  const CoinSellerScreen({super.key});

  @override
  State<CoinSellerScreen> createState() => _CoinSellerScreenState();
}

class _CoinSellerScreenState extends State<CoinSellerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _salesMethod = 0; // 0: User, 1: Coinseller
  int _selectedPayment = 0; // 0: Binance Pay, 1: Telebirr

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Coin Seller",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. የሻጩ መረጃ እና የባላንስ ካርድ
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // የነጋዴው ፕሮፋይል
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD700),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.storefront, color: Colors.black87, size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "SELLER ACCOUNT",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text("ID: ------", style: TextStyle(color: Colors.black45, fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Icon(Icons.copy, size: 12, color: Colors.black38),
                                  ],
                                ),

const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "Beginner Seller",
                                    style: TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C9A7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              "Level Up",
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // የሳንቲም ባላንስ እና የክፍያ ዘዴዎች ሳጥን
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF9E6), Color(0xFFFFF3CC)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Seller Balance",
                                style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orangeAccent),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "Details",
                                  style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Icon(Icons.monetization_on, color: Color(0xFFFFB800), size: 28),
                              SizedBox(width: 8),
                              Text(
                                "0",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),

),
                            ],
                          ),
                          const Divider(color: Colors.black12, height: 20),
                          // Payment Method Row (Telebirr & Binance)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.account_balance_wallet, color: Colors.deepOrange, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Payment Method (Telebirr / Binance)",
                                    style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black45),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. TabBar Header (Transfer, Recharge, Exchange)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SellerTabDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF00C9A7),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF00C9A7),
                  unselectedLabelColor: Colors.black54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: "Transfer"),
                    Tab(text: "Recharge"),
                    Tab(text: "Exchange"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTransferTab(),
            _buildRechargeTab(),
            _buildExchangeTab(),
          ],
        ),
      ),
    );
  }

  // 1. Transfer Tab (ሳንቲም ማስተላለፊያ ገጽ)
  Widget _buildTransferTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales Method (User or Coinseller)
          Row(
            children: [
              const Text("Sales Method:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _salesMethod = 0),
                child: Row(
                  children: [
                    Icon(
                      _salesMethod == 0 ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: const Color(0xFF00C9A7),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    const Text("User", style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _salesMethod = 1),
                child: Row(
                  children: [
                    Icon(
                      _salesMethod == 1 ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: const Color(0xFF00C9A7),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    const Text("Coinseller", style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

// User ID Input Slot
          const Text("User ID:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Enter receiver User ID",
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("Check", style: TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Coin Amount Input Slot
          const Text("Coin Amount:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter amount × 1,000 🪙",
                hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text("Please enter a multiple of 1,000", style: TextStyle(color: Colors.redAccent, fontSize: 11)),

          const SizedBox(height: 24),

          // Transfer Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {},
              child: const Text("Transfer", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text("Transfer Detail >", style: TextStyle(color: Color(0xFF00C9A7), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // 2. Recharge Tab (ነጋዴው ለራሱ በጅምላ የሚገዛበት ገጽ)
  Widget _buildRechargeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Method Selector (Binance vs Telebirr)
          const Text("Select Payment Method:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPayment = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),

border: Border.all(
                        color: _selectedPayment == 0 ? const Color(0xFF00C9A7) : Colors.black12,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.currency_bitcoin, color: Colors.amber, size: 24),
                        SizedBox(height: 4),
                        Text("Binance Pay", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPayment = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedPayment == 1 ? const Color(0xFF00C9A7) : Colors.black12,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.phone_android, color: Colors.blueAccent, size: 24),
                        SizedBox(height: 4),
                        Text("Telebirr", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Wholesale Packages
          const Text("Wholesale Packages:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _buildPackageCard("1,980,000", "\$200", "Standard"),
              _buildPackageCard("9,900,000", "\$1000", "Standard"),
              _buildPackageCard("14,850,000", "\$1500", "Standard"),
              _buildPackageCard("30,000,000", "\$3000", "Senior"),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {},
              child: const Text("Recharge Now", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Exchange Tab (ከሆስቶች ነጥብ ወደ ሳንቲም መቀየሪያ)
  Widget _buildExchangeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Display
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("My Available Points:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text("0 Points", style: TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),

const SizedBox(height: 16),

          const Text("Exchange Tiers:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _buildPackageCard("960,000 Coins", "1,000,000 Pts", ""),
              _buildPackageCard("1,960,000 Coins", "2,000,000 Pts", ""),
              _buildPackageCard("9,800,000 Coins", "10,000,000 Pts", ""),
              _buildPackageCard("30,000,000 Coins", "30,000,000 Pts", ""),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {},
              child: const Text("Exchange to Coins", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(String coins, String price, String tag) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFB800), size: 16),
              const SizedBox(width: 4),
              Text(coins, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SellerTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SellerTabDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SellerTabDelegate oldDelegate) => false;
}
