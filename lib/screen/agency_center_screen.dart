import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/user_service.dart';

class AgencyCenterScreen extends StatefulWidget {
  final String userId;

  const AgencyCenterScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AgencyCenterScreen> createState() => _AgencyCenterScreenState();
}

class _AgencyCenterScreenState extends State<AgencyCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _agencyData;
  List<dynamic> _hosts = [];
  List<dynamic> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAgencyData();
  }

  Future<void> _fetchAgencyData() async {
    setState(() => _isLoading = true);
    try {
      final url = UserService.serverUrl + '/api/agency/dashboard?ownerId=' + widget.userId;
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        setState(() {
          _agencyData = data['agency'];
          _hosts = data['hosts'];
          _pendingRequests = data['pendingRequests'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApplication(String hostUserId, String action) async {
    try {
      final url = UserService.serverUrl + '/api/agency/manage-application';
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ownerId': widget.userId,
          'userId': hostUserId,
          'action': action,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _fetchAgencyData();
      }
    } catch (e) {}
  }

  Future<void> _removeHost(String hostUserId) async {
    try {
      final url = UserService.serverUrl + '/api/agency/remove-host';
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ownerId': widget.userId,
          'userId': hostUserId,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _fetchAgencyData();
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF16171E),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (_agencyData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF16171E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: const Text('Agency Center', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text(
            'No Agency Found For This User',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF16171E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        title: const Text('Agency Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header Card
          Container(

margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _agencyData!['agencyName'] ?? 'Agency',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _agencyData!['agencyId']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Agency ID Copied!'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'ID: ' + _agencyData!['agencyId'],
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol('Balance Points', _agencyData!['balancePoints'].toString()),
                    _buildStatCol('Active Hosts', _agencyData!['activeHostsCount'].toString()),
                    _buildStatCol('Rate', _agencyData!['commissionRate'].toString() + '%'),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Hosts (' + _hosts.length.toString() + ')'),
              Tab(text: 'Requests (' + _pendingRequests.length.toString() + ')'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHostsList(),
                _buildRequestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHostsList() {

if (_hosts.isEmpty) {
      return const Center(child: Text('No active hosts yet', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hosts.length,
      itemBuilder: (ctx, i) {
        final host = _hosts[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  (host['userName'] != null && host['userName'].isNotEmpty) ? host['userName'][0] : 'H',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(host['userName'] ?? 'Host', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('ID: ' + host['userId'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.redAccent, size: 20),
                onPressed: () => _removeHost(host['userId']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    if (_pendingRequests.isEmpty) {
      return const Center(child: Text('No pending requests', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (ctx, i) {
        final req = _pendingRequests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  (req['userName'] != null && req['userName'].isNotEmpty) ? req['userName'][0] : 'H',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req['userName'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('ID: ' + req['userId'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 26),
                onPressed: () => _handleApplication(req['userId'], 'approve'),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 26),
                onPressed: () => _handleApplication(req['userId'], 'reject'),
              ),
            ],
          ),
        );
      },
    );
  }
}
