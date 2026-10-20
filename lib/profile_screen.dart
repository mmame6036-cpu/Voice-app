import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'daily_tasks_screen.dart';
import 'settings_screen.dart';
import 'coin_seller_screen.dart';
import 'host_center_screen.dart';
import 'agency_screen.dart';
import 'store_screen.dart';
import 'invite_screen.dart';
import 'wallet_screen.dart';
import 'backpack_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  Future<void> _checkAndOpenCoinSeller(BuildContext context) async {
    if (userId.trim() == '1000') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CoinSellerScreen()),
      );
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('https://voice-app-backend.onrender.com/api/search-user?userId=$userId'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bool isAgent = data['user']?['isAgent'] ?? false;
        if (isAgent) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoinSellerScreen()),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access restricted. Authorized Coin Sellers (Agents) only!'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } else {
        throw Exception();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to verify agent permission. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMasterAdmin = (userId.trim() == '1000');
    final userObj = UserService();

    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1F2E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: isMasterAdmin ? Colors.amber : Colors.blueAccent,
                  child: Icon(
                    isMasterAdmin ? Icons.workspace_premium : Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ID: $userId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isMasterAdmin)
                  Container(
                    margin: const EdgeInsets.top(6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Text(
                      '👑 Master Admin',
                      style: TextStyle(

color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          if (isMasterAdmin) ...[
            _buildMenuItem(
              icon: Icons.admin_panel_settings,
              iconColor: Colors.amber,
              title: 'Master Admin Control',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InAppAdminScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          _buildMenuItem(
            icon: Icons.assignment_turned_in_rounded,
            iconColor: const Color(0xFF7B4DFF),
            title: 'Daily Tasks & Rewards',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DailyTasksScreen(
                    user: UserModel(
                      userId: userId,
                      name: userObj.userName.isNotEmpty ? userObj.userName : 'User_$userId',
                      avatar: userObj.avatar,
                      coins: userObj.coins,
                      points: userObj.points,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.mic_external_on,
            iconColor: Colors.purpleAccent,
            title: 'Host Center',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HostCenterScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.account_balance_wallet,
            iconColor: Colors.orangeAccent,
            title: 'Wallet & Recharge',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.storefront,
            iconColor: Colors.greenAccent,
            title: 'Coin Seller Center',
            onTap: () => _checkAndOpenCoinSeller(context),
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.business,
            iconColor: Colors.blueAccent,
            title: 'Agency Center',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgencyScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.shopping_bag,
            iconColor: Colors.amberAccent,
            title: 'Store',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoreScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.deepOrangeAccent,
            title: 'Backpack',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackpackScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.person_add_alt_1,

iconColor: Colors.tealAccent,
            title: 'Invite Friends',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InviteScreen(
                    userId: userId,
                    userName: userObj.userName.isNotEmpty ? userObj.userName : 'User_$userId',
                    onRewardClaimed: (bonusCoins) {
                      userObj.coins += bonusCoins;
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.settings,
            iconColor: Colors.grey,
            title: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      tileColor: const Color(0xFF222436),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
      onTap: onTap,
    );
  }
}

class InAppAdminScreen extends StatefulWidget {
  const InAppAdminScreen({super.key});

  @override
  State<InAppAdminScreen> createState() => _InAppAdminScreenState();
}

class _InAppAdminScreenState extends State<InAppAdminScreen> {
  final TextEditingController _agentIdController = TextEditingController();
  List<dynamic> _pendingPayments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingPayments();
  }

  Future<void> _fetchPendingPayments() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('https://voice-app-backend.onrender.com/api/admin/pending-payments'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _pendingPayments = data['data'] ?? [];
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _toggleAgent(bool isAgent) async {
    final targetId = _agentIdController.text.trim();
    if (targetId.isEmpty) return;

    try {
      final res = await http.post(
        Uri.parse('https://voice-app-backend.onrender.com/api/admin/toggle-agent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': targetId, 'isAgent': isAgent}),
      );
      final data = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Action completed'),
            backgroundColor: data['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
      _agentIdController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _approvePayment(String paymentId) async {
    try {
      final res = await http.post(
        Uri.parse('https://voice-app-backend.onrender.com/api/admin/approve-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentId': paymentId}),
      );
      final data = jsonDecode(res.body);

if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Payment Approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _fetchPendingPayments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: const Text(
          '👑 Master Admin Panel',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF1E1F2E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _fetchPendingPayments,
            icon: const Icon(Icons.refresh, color: Colors.amber),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF1E1F2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign / Revoke Agent (Coin Seller)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _agentIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'User ID (e.g. 1002)...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF13141C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _toggleAgent(true),
                          child: const Text('Make Agent', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => _toggleAgent(false),
                          child: const Text('Revoke Agent', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Pending Recharge Requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(

child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            )
          else if (_pendingPayments.isEmpty)
            const Card(
              color: Color(0xFF1E1F2E),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No pending recharge requests found.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            )
          else
            ..._pendingPayments.map((p) {
              return Card(
                color: const Color(0xFF1E1F2E),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    'User ID: ${p['userId']} (${p['amountCoins']} Coins)',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Method: ${p['paymentMethod']}\nTxID: ${p['txId']}\nPaid: ${p['pricePaid']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _approvePayment(p['_id']),
                    child: const Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
