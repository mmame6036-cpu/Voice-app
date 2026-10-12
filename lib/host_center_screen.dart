import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';

class HostCenterScreen extends StatefulWidget {
  const HostCenterScreen({Key? key}) : super(key: key);

  @override
  State<HostCenterScreen> createState() => _HostCenterScreenState();
}

class _HostCenterScreenState extends State<HostCenterScreen> with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  late TabController _tabController;

  // Real-time host dynamic states
  int _giftIncome = 0;
  int _hourlyIncome = 0;
  int _totalIncome = 0;
  int _consumedPoints = 0;
  int _liveDurationMins = 0;
  String _agencyName = 'No agent';

  // Sub categories
  int _giftsPoints = 0;
  int _baseSalaryPoints = 0;
  int _invitationPoints = 0;
  int _tasksPoints = 0;
  int _otherPoints = 0;

  // Records lists (starts empty without dummy data)
  final List<Map<String, dynamic>> _todayRecords = [];
  final List<Map<String, dynamic>> _dailyStats = [];
  bool _isLoadingRecords = false;

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

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        title: const Text('Host Hourly Salary Rules', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          '1. Reach target points to increase your hourly income.\n2. Maintain consistent live broadcasting hours.\n3. Points are settled automatically based on platform regulations.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF00C9A7))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Host Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Rules',
            onPressed: _showRulesDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Purple Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // User info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.amber,
                        child: Text(
                          _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'H',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),

),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_user.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text('ID: ${_user.userId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(_agencyName, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gift Income & Hourly Income Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Gift Income (Last 7 days)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 6),
                                Text('$_giftIncome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                              ],
                            ),
                            Container(width: 1, height: 34, color: Colors.white24),
                            Column(
                              children: [
                                const Text('Hourly Income', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 6),
                                Text('$_hourlyIncome /h', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text('Progress', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showRulesDialog,
                              child: const Text('Rules >', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            value: 0.0,
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Points Overview Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: const Color(0xFF8E24AA)),
                      const SizedBox(width: 6),
                      const Text('Points Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Income', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text('$_totalIncome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Consume >', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text('$_consumedPoints', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sub categories tiles
                  Row(
                    children: [
                      _buildOverviewSubCard('Gifts >', _giftsPoints),
                      const SizedBox(width: 10),
                      _buildOverviewSubCard('Base Salary >', _baseSalaryPoints),
                    ],
                  ),
                  const SizedBox(height: 10),

Row(
                    children: [
                      _buildOverviewSubCard('Invitation >', _invitationPoints),
                      const SizedBox(width: 10),
                      _buildOverviewSubCard('Tasks >', _tasksPoints),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildOverviewSubCard('Other >', _otherPoints),
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Work Detail
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: const Color(0xFF8E24AA)),
                      const SizedBox(width: 6),
                      const Text('Work Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Live Duration', style: TextStyle(color: Colors.black54, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$_liveDurationMins mins', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Records Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF8E24AA),
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: const Color(0xFF8E24AA),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: "Today's live record"),
                      Tab(text: 'Daily Statistics'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRecordList(_todayRecords),
                        _buildRecordList(_dailyStats),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSubCard(String title, int points) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Row(
              children: [

const Icon(Icons.diamond, size: 14, color: Color(0xFF38B29C)),
                const SizedBox(width: 4),
                Text('$points', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordList(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('no data', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, idx) {
        final item = records[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['date'] ?? '', style: const TextStyle(fontSize: 12)),
              Text('${item['duration']} mins', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${item['points']} pts', style: const TextStyle(fontSize: 12, color: Color(0xFF38B29C))),
            ],
          ),
        );
      },
    );
  }
}
