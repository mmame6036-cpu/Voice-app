import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({Key? key}) : super(key: key);

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  late TabController _tabController;

  bool _isLoading = true;
  String _agencyId = '';
  int _last30DaysPoints = 0;
  int _commissionRate = 4;
  int _hostCount = 0;
  int _agentsCount = 0;
  int _chatroomsCount = 0;

  final String _supporterId = '1008149';
  final String _supporterWhatsapp = '+14070000000';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final url = UserService.serverUrl + '/api/agency/dashboard?ownerId=' + _user.userId;
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        final agency = data['agency'];
        final hosts = data['hosts'] ?? [];

        setState(() {
          _agencyId = agency['agencyId'] ?? '';
          _commissionRate = agency['commissionRate'] ?? 4;
          _last30DaysPoints = agency['totalEarnings'] ?? 0;
          _hostCount = hosts.length;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        title: const Text('Commission Rules', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          '1. Base Commission starts at 4%.\n2. Reach 2M points for 8%.\n3. Reach 10M points for 12%.\n4. Reach 50M points for 16%.\n5. Reach 150M points for 20%.\nCommissions are calculated based on monthly performance.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Color(0xFF00C9A7))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120E22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1633),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agency Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
          : SingleChildScrollView(

padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Incentive Plan',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Weekly qualification unlocks rewards up to millions in points!',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.workspace_premium, color: Colors.amber, size: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1836),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFF00C9A7),
                              child: Text(
                                _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'A',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_user.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 3),
                                Text('ID: ${_user.userId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                if (_agencyId.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _copyToClipboard(_agencyId, 'Agency ID'),
                                    child: Row(
                                      children: [
                                        Text('Agency: $_agencyId', style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 12)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.copy, size: 12, color: Color(0xFF00C9A7)),
                                      ],

),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _showRulesDialog,
                              child: const Row(
                                children: [
                                  Text('Details', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        Row(
                          children: [
                            Text('Last 30 Days Points: $_last30DaysPoints', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Commission Rate: $_commissionRate%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showRulesDialog,
                              child: const Text('Rules >', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMilestoneNode('4%', '0', _last30DaysPoints >= 0),
                            _buildMilestoneLine(_last30DaysPoints >= 2000000),
                            _buildMilestoneNode('8%', '2M', _last30DaysPoints >= 2000000),
                            _buildMilestoneLine(_last30DaysPoints >= 10000000),
                            _buildMilestoneNode('12%', '10M', _last30DaysPoints >= 10000000),
                            _buildMilestoneLine(_last30DaysPoints >= 50000000),
                            _buildMilestoneNode('16%', '50M', _last30DaysPoints >= 50000000),
                            _buildMilestoneLine(_last30DaysPoints >= 150000000),
                            _buildMilestoneNode('20%', '150M', _last30DaysPoints >= 150000000),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1836),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Host', '$_hostCount'),
                        Container(width: 1, height: 28, color: Colors.white10),
                        _buildStatItem('Agents', '$_agentsCount'),
                        Container(width: 1, height: 28, color: Colors.white10),
                        _buildStatItem('Chatrooms', '$_chatroomsCount'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [

Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C4AB6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            if (_agencyId.isNotEmpty) {
                              _copyToClipboard(_agencyId, 'Agency ID');
                            }
                          },
                          icon: const Icon(Icons.person_add_alt, size: 18, color: Colors.white),
                          label: const Text('Invite Host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C4AB6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            if (_agencyId.isNotEmpty) {
                              _copyToClipboard(_agencyId, 'Agency ID');
                            }
                          },
                          icon: const Icon(Icons.group_add_outlined, size: 18, color: Colors.white),
                          label: const Text('Invite Sub-agents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    indicatorColor: const Color(0xFF00C9A7),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: 'S+ Rewards'),
                      Tab(text: 'Commission Data'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRewardsTab(),
                        _buildCommissionDataTab(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1836),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent, color: Color(0xFF00C9A7), size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Official Supporter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('ID: $_supporterId', style: const TextStyle(color: Colors.white54, fontSize: 12)),

],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                          onPressed: () => _copyToClipboard(_supporterWhatsapp, 'Supporter WhatsApp'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMilestoneNode(String rate, String target, bool isAchieved) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isAchieved ? const Color(0xFF00C9A7) : Colors.white24,
          child: Text(
            rate,
            style: TextStyle(
              color: isAchieved ? Colors.black : Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          target,
          style: TextStyle(
            color: isAchieved ? const Color(0xFF00C9A7) : Colors.white38,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneLine([bool isAchieved = false]) {
    return Expanded(
      child: Container(
        height: 2,
        color: isAchieved ? const Color(0xFF00C9A7) : Colors.white12,
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildRewardsTab() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1836),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Develop more high-performing sub-agents to unlock greater rewards.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCommissionDataTab() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1836),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'No commission data recorded for this cycle yet.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
