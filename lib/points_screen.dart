import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({Key? key}) : super(key: key);

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  late TabController _tabController;

  // Controllers
  final TextEditingController _cashoutAmountController = TextEditingController();
  final TextEditingController _exchangeAmountController = TextEditingController();
  final TextEditingController _transferIdController = TextEditingController();
  final TextEditingController _transferAmountController = TextEditingController();

  int _pointsBalance = 0;
  int _frozenPoints = 0;
  bool _isEyeOpen = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashoutAmountController.dispose();
    _exchangeAmountController.dispose();
    _transferIdController.dispose();
    _transferAmountController.dispose();
    super.dispose();
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DetailOfPointsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Points',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Points Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF38B29C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Points Balance',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.help_outline, color: Colors.white70, size: 15),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openDetails,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Text('Details', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(

padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.diamond, color: Color(0xFF38B29C), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEyeOpen ? '$_pointsBalance' : '**',
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Frozen Points: *  $_frozenPoints',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _isEyeOpen = !_isEyeOpen),
                        child: Icon(
                          _isEyeOpen ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.white70,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Buttons: Cash out | Exchange | Transfer
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF38B29C),
              unselectedLabelColor: Colors.black54,
              indicatorColor: const Color(0xFF38B29C),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Cash out'),
                Tab(text: 'Exchange'),
                Tab(text: 'Transfer'),
              ],
            ),
            const SizedBox(height: 16),

            // Dynamic Tab Views
            SizedBox(
              height: 440,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCashOutTab(),
                  _buildExchangeTab(),
                  _buildTransferTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. CASH OUT TAB
  Widget _buildCashOutTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionTile(title: 'Currency Type', value: 'ETB (Ethiopian Birr)'),
        const SizedBox(height: 12),
        _buildSelectionTile(title: 'Payment Method', value: 'Telebirr / CBE'),
        const SizedBox(height: 16),
        const Text(
          'Points amount for cashing out',
          style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.diamond, color: Color(0xFF38B29C), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cashoutAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Please enter the quantity',

hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _cashoutAmountController.text = '$_pointsBalance';
                },
                child: const Text('All', style: TextStyle(color: Color(0xFF38B29C), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter a multiple of 100,000',
          style: TextStyle(color: Colors.redAccent, fontSize: 11),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38B29C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: () {},
            child: const Text('Withdraw', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // 2. EXCHANGE TAB
  Widget _buildExchangeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Exchange rate: 10,000 Points = 9,000 Coins', style: TextStyle(fontSize: 11, color: Colors.black45)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _exchangeAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter Amount',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Text('×100,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              const SizedBox(width: 6),
              const Icon(Icons.diamond, color: Color(0xFF38B29C), size: 18),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.amber, size: 20),
            SizedBox(width: 6),
            Text('Estimated Coins: 0', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38B29C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: () {},
            child: const Text('Exchange Points', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // 3. TRANSFER TAB
  Widget _buildTransferTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('User ID:', style: TextStyle(fontSize: 12, color: Colors.black54)),

const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _transferIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter User ID',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Check', style: TextStyle(color: Color(0xFF38B29C), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('Amount', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const Text('Fee: 2%', style: TextStyle(fontSize: 11, color: Colors.black45)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _transferAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter Amount',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Text('×100,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              const SizedBox(width: 6),
              const Icon(Icons.diamond, color: Color(0xFF38B29C), size: 18),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '1. Transfer fee: 2%. Minimum transfer >= 100,000 points.\n2. Click transfer button to transfer corresponding points.\n3. After the transfer is completed, it cannot be canceled.',
          style: TextStyle(fontSize: 10, color: Colors.black45, height: 1.4),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38B29C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: () {},
            child: const Text('Transfer Points', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSelectionTile({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.black45)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.black38),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DETAIL OF POINTS (HISTORY TABS: ALL | CASH OUT | TRANSFER)
// ---------------------------------------------------------------------------
class DetailOfPointsScreen extends StatefulWidget {
  const DetailOfPointsScreen({Key? key}) : super(key: key);

  @override
  State<DetailOfPointsScreen> createState() => _DetailOfPointsScreenState();
}

class _DetailOfPointsScreenState extends State<DetailOfPointsScreen> with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail of Points',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _subTabController,
            labelColor: const Color(0xFF38B29C),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFF38B29C),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Cash out'),
              Tab(text: 'Transfer'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Text('Select Date', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _subTabController,
              children: [
                _buildEmptyState(),
                _buildEmptyState(),
                _buildEmptyState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 58, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'no data',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
