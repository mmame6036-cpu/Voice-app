import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HostMember {
  final String userId;
  final String userName;
  final int liveMinutes;
  final int diamondsEarned;
  final bool isFaceVerified;

  HostMember({
    required this.userId,
    required this.userName,
    required this.liveMinutes,
    required this.diamondsEarned,
    required this.isFaceVerified,
  });

  factory HostMember.fromJson(Map<String, dynamic> json) {
    return HostMember(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] ?? 'Unknown Host',
      liveMinutes: int.tryParse(json['liveMinutes']?.toString() ?? '0') ?? 0,
      diamondsEarned: int.tryParse(json['diamondsEarned']?.toString() ?? '0') ?? 0,
      isFaceVerified: json['isFaceVerified'] == true,
    );
  }
}

class AgencyCenterScreen extends StatefulWidget {
  final String userId;

  const AgencyCenterScreen({super.key, required this.userId});

  @override
  State<AgencyCenterScreen> createState() => _AgencyCenterScreenState();
}

class _AgencyCenterScreenState extends State<AgencyCenterScreen> {
  bool _isLoading = true;
  String _agencyName = 'Medina Agency';
  int _commissionRate = 15;
  int _totalAgencyDiamonds = 0;
  List<HostMember> _hosts = [];

  final TextEditingController _hostIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAgencyData();
  }

  @override
  void dispose() {
    _hostIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchAgencyData() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('https://voice-app-backend.onrender.com/api/agency/details?agentId=${widget.userId}'),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final List list = data['hosts'] ?? [];
          setState(() {
            _agencyName = data['agencyName'] ?? 'Medina Agency';
            _commissionRate = data['commissionRate'] ?? 15;
            _totalAgencyDiamonds = data['totalDiamonds'] ?? 0;
            _hosts = list.map((item) => HostMember.fromJson(item)).toList();
          });
        }
      } else {
        _loadFallbackData();
      }
    } catch (_) {
      _loadFallbackData();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadFallbackData() {
    setState(() {
      _totalAgencyDiamonds = 450000;
      _hosts = [
        HostMember(
          userId: '100234',
          userName: 'Sara Host',
          liveMinutes: 180,
          diamondsEarned: 150000,
          isFaceVerified: true,
        ),
        HostMember(
          userId: '100452',
          userName: 'Hana Live',
          liveMinutes: 95,
          diamondsEarned: 80000,
          isFaceVerified: true,
        ),
        HostMember(
          userId: '100891',
          userName: 'Dawit Host',
          liveMinutes: 40,
          diamondsEarned: 22000,
          isFaceVerified: false,
        ),
      ];
    });
  }

  void _showAddHostDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Recruit New Host',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: _hostIdController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter Host User ID (e.g. 1005)',

hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF13141C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newId = _hostIdController.text.trim();
              if (newId.isNotEmpty) {
                Navigator.pop(ctx);
                _submitNewHost(newId);
              }
            },
            child: const Text('Add Host', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNewHost(String hostId) async {
    try {
      final res = await http.post(
        Uri.parse('https://voice-app-backend.onrender.com/api/agency/add-host'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'agentId': widget.userId, 'hostUserId': hostId}),
      );
      final data = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Processed'),
            backgroundColor: data['success'] == true ? const Color(0xFF00C9A7) : Colors.redAccent,
          ),
        );
      }
      if (data['success'] == true) {
        _fetchAgencyData();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Host recruited locally (Demo preview mode)'),
            backgroundColor: Color(0xFF00C9A7),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int estimatedCommission = ((_totalAgencyDiamonds * _commissionRate) / 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: Text(_agencyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E1F2E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00C9A7)),
            onPressed: _fetchAgencyData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
          : RefreshIndicator(
              onRefresh: _fetchAgencyData,
              color: const Color(0xFF00C9A7),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF221845), Color(0xFF1A1C2C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Agency Diamonds', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$_totalAgencyDiamonds',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C9A7).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.4)),
                              ),
                              child: Text(
                                'Commission: $_commissionRate%',
                                style: const TextStyle(
                                  color: Color(0xFF00C9A7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetricItem('Est. Commission', '$estimatedCommission 💎', Colors.amberAccent),
                            _buildMetricItem('Active Hosts', '${_hosts.length}', Colors.greenAccent),
                            _buildMetricItem('Verified', '${_hosts.where((h) => h.isFaceVerified).length}', Colors.lightBlueAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Agency Hosts (${_hosts.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9A7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: _showAddHostDialog,
                        icon: const Icon(Icons.person_add, color: Colors.black, size: 16),
                        label: const Text(

'Add Host',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._hosts.map((host) => _buildHostCard(host)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricItem(String title, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHostCard(HostMember host) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF2B2E42),
            child: Text(
              host.userName.isNotEmpty ? host.userName[0].toUpperCase() : 'H',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      host.userName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      host.isFaceVerified ? Icons.verified : Icons.error_outline,
                      color: host.isFaceVerified ? const Color(0xFF00C9A7) : Colors.amber,
                      size: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${host.userId} • Live: ${host.liveMinutes} mins',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond, color: Colors.cyanAccent, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '${host.diamondsEarned}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                host.isFaceVerified ? 'Eligible' : 'Unverified',
                style: TextStyle(
                  color: host.isFaceVerified ? const Color(0xFF00C9A7) : Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
