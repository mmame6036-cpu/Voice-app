import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class RechargeScreen extends StatefulWidget {
  final dynamic socket;
  final VoidCallback? onCoinsUpdated;

  const RechargeScreen({
    Key? key,
    this.socket,
    this.onCoinsUpdated,
  }) : super(key: key);

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> packages = [
    {'coins': 1000, 'price': '50 ETB', 'bonus': 0},
    {'coins': 2500, 'price': '120 ETB', 'bonus': 100},
    {'coins': 5000, 'price': '240 ETB', 'bonus': 300},
    {'coins': 10000, 'price': '480 ETB', 'bonus': 800},
    {'coins': 25000, 'price': '1,150 ETB', 'bonus': 2500},
    {'coins': 50000, 'price': '2,200 ETB', 'bonus': 6000},
  ];

  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _transferStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _targetIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _buyCoins(int coins) {
    setState(() {
      AppData.userCoins += coins;
    });
    widget.onCoinsUpdated?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 $coins ሳንቲም በተሳካ ሁኔታ ተሞልቷል!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _transferCoins() {
    final targetId = _targetIdController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (targetId.isEmpty) {
      setState(() => _transferStatus = 'እባክዎ የተጠቃሚውን መለያ (ID) ያስገቡ');
      return;
    }
    if (amount <= 0) {
      setState(() => _transferStatus = 'ትክክለኛ የሳንቲም መጠን ያስገቡ');
      return;
    }
    if (amount > AppData.userCoins) {
      setState(() => _transferStatus = 'በቂ ሳንቲም የለዎትም!');
      return;
    }

    setState(() {
      AppData.userCoins -= amount;
      _transferStatus = '✅ $amount ሳንቲም ወደ ID: $targetId ተላልፏል!';
      _amountController.clear();
      _targetIdController.clear();
    });
    widget.onCoinsUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('የሳንቲም ማዕከል (Wallet)', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'ሳንቲም ሙላ (Recharge)'),
            Tab(text: 'ሳንቲም አስተላልፍ (Transfer)'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF880E4F), Color(0xFF4A148C)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('የእርስዎ ቀሪ ሳንቲም፦', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${AppData.userCoins}',

style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: packages.length,
                  itemBuilder: (context, idx) {
                    final p = packages[idx];
                    return Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                        title: Text('${p['coins']} ሳንቲም', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: p['bonus'] > 0 ? Text('+${p['bonus']} ቦነስ', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)) : null,
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                          onPressed: () => _buyCoins(p['coins']),
                          child: Text(p['price'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _targetIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'የተቀባይ መለያ (User ID)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'የሳንቲም መጠን',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_transferStatus.isNotEmpty)
                        Text(_transferStatus, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _transferCoins,
                        child: const Text('አስተላልፍ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
