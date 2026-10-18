import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';
import 'room_screen.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({Key? key}) : super(key: key);

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  late TabController _tabController;
  bool _isLoading = true;

  int _normalSeatMinutes = 0;
  int _normalSeatRewardRate = 1000;
  int _crownSeatMinutes = 0;
  int _crownGiftCoins = 0;
  int _dailyFollowersCount = 0;
  int _coinsSent = 0;
  int _gameBetting = 0;
  List<String> _claimedTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTaskStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTaskStatus() async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/tasks/status/${_user.userId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          final data = resData['data'];
          if (mounted) {
            setState(() {
              _normalSeatMinutes = data['normalSeatMinutes'] ?? 0;
              _normalSeatRewardRate = data['normalSeatRewardRate'] ?? 1000;
              _crownSeatMinutes = data['crownSeatMinutes'] ?? 0;
              _crownGiftCoins = data['crownGiftCoins'] ?? 0;
              _dailyFollowersCount = data['dailyFollowersCount'] ?? 0;
              _coinsSent = data['coinsSent'] ?? 0;
              _gameBetting = data['gameBetting'] ?? 0;
              _claimedTasks = List<String>.from(data['claimedTasks'] ?? []);
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching status: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _claimTask(String taskId) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/tasks/claim');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _user.userId,
          'taskId': taskId,
        }),
      );

      final resData = jsonDecode(response.body);
      if (resData['success'] == true) {
        setState(() {
          _claimedTasks.add(taskId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resData['message'] ?? 'Claim successful!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resData['message'] ?? 'Requirement not met'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Go to personal room or public room to complete task
  Future<void> _goToRoom() async {
    try {
      await http.post(
        Uri.parse('https://voice-app-2-jd95.onrender.com/api/rooms/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': _user.userId,
          'title': "${_user.userName}'s Room",
          'category': 'Party',
          'hostId': _user.userId,
          'hostName': _user.userName,
        }),
      );
    } catch (_) {}

    if (!mounted) return;

Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomScreen(
          roomId: _user.userId,
          roomTitle: "${_user.userName}'s Room",
          hostName: _user.userName,
        ),
      ),
    ).then((_) => _fetchTaskStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF110E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF110E27),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF231B4D),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF7B4DFF),
                borderRadius: BorderRadius.circular(20),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.diamond_outlined, size: 16, color: Colors.purpleAccent),
                      SizedBox(width: 8),
                      Text('Points'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('Coins'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B4DFF)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPointsTab(),
                _buildCoinsTab(),
              ],
            ),
    );
  }

  Widget _buildPointsTab() {
    return RefreshIndicator(
      onRefresh: _fetchTaskStatus,
      color: const Color(0xFF7B4DFF),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 7-Day New User Bonus
          _buildTaskCard(
            icon: Icons.mic_none,
            iconColor: Colors.blueAccent,
            title: '7-Day New User Reward',
            subtitle: 'Seat Duration: ${_normalSeatMinutes > 120 ? 120 : _normalSeatMinutes}/120 min',
            rewardText: '8k Points',
            isCompleted: _normalSeatMinutes >= 120,
            isClaimed: _claimedTasks.contains('new_user_7day'),
            onClaim: () => _claimTask('new_user_7day'),
            onGo: _goToRoom,
          ),

          // 2. Normal Seat Daily Hourly Reward
          _buildTaskCard(
            icon: Icons.timer,
            iconColor: Colors.tealAccent,
            title: 'Normal Seat: 1 Hour',
            subtitle: 'Seat Duration: ${_normalSeatMinutes > 60 ? 60 : _normalSeatMinutes}/60 min',

rewardText: '$_normalSeatRewardRate Points',
            isCompleted: _normalSeatMinutes >= 60,
            isClaimed: _claimedTasks.contains('normal_seat_daily'),
            onClaim: () => _claimTask('normal_seat_daily'),
            onGo: _goToRoom,
          ),

          // 3. Crown Seat Reward
          _buildTaskCard(
            icon: Icons.military_tech,
            iconColor: Colors.amber,
            title: 'Crown Seat: 1 Hour',
            subtitle: 'Crown Duration: ${_crownSeatMinutes > 60 ? 60 : _crownSeatMinutes}/60 min\nGift Coins: ${_crownGiftCoins > 600 ? 600 : _crownGiftCoins}/600',
            rewardText: '1k Points',
            isCompleted: _crownSeatMinutes >= 60 && _crownGiftCoins >= 600,
            isClaimed: _claimedTasks.contains('crown_seat_task'),
            onClaim: () => _claimTask('crown_seat_task'),
            onGo: _goToRoom,
          ),

          // 4. Crown Room Reward (Host Live)
          _buildTaskCard(
            icon: Icons.meeting_room,
            iconColor: Colors.deepPurpleAccent,
            title: 'Crown Room Reward',
            subtitle: 'Live Duration: ${_crownSeatMinutes > 60 ? 60 : _crownSeatMinutes}/60 min',
            rewardText: '1k Points',
            isCompleted: _crownSeatMinutes >= 60,
            isClaimed: _claimedTasks.contains('crown_room_reward'),
            onClaim: () => _claimTask('crown_room_reward'),
            onGo: _goToRoom,
          ),

          // 5. Gain Followers Task
          _buildTaskCard(
            icon: Icons.favorite_border,
            iconColor: Colors.pinkAccent,
            title: 'Gain Followers',
            subtitle: 'Received Followers: ${_dailyFollowersCount > 3 ? 3 : _dailyFollowersCount}/3',
            rewardText: '1k Points',
            isCompleted: _dailyFollowersCount >= 3,
            isClaimed: _claimedTasks.contains('followers_task'),
            onClaim: () => _claimTask('followers_task'),
            onGo: _goToRoom,
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Stay in Room Task
        _buildTaskCard(
          icon: Icons.meeting_room_outlined,
          iconColor: Colors.greenAccent,
          title: 'Stay in a Room for 10 Minutes',
          subtitle: 'Total time spent: ${_normalSeatMinutes > 10 ? 10 : _normalSeatMinutes}/10 min',
          rewardText: '100 Coins',
          isCompleted: _normalSeatMinutes >= 10,
          isClaimed: _claimedTasks.contains('stay_10_coins'),
          onClaim: () => _claimTask('stay_10_coins'),
          onGo: _goToRoom,
        ),

        // 2. Bonus Gifts Sent Flow (100k)
        _buildTaskCard(
          icon: Icons.card_giftcard,
          iconColor: Colors.pinkAccent,
          title: 'Bonus Gifts: Sent 100k Coins',
          subtitle: 'Lucky Gift Flow: ${_coinsSent > 100000 ? 100000 : _coinsSent}/100k',
          rewardText: '1k Coins',
          isCompleted: _coinsSent >= 100000,
          isClaimed: _claimedTasks.contains('gift_flow_100k'),
          onClaim: () => _claimTask('gift_flow_100k'),
          onGo: _goToRoom,
        ),

        // 3. Game Betting Flow
        _buildTaskCard(
          icon: Icons.sports_esports,
          iconColor: Colors.purpleAccent,
          title: 'Game: Bet 100k Coins',
          subtitle: 'Game Flow: ${_gameBetting > 100000 ? 100000 : _gameBetting}/100k',
          rewardText: '1k Coins',
          isCompleted: _gameBetting >= 100000,
          isClaimed: _claimedTasks.contains('game_flow_100k'),
          onClaim: () => _claimTask('game_flow_100k'),
          onGo: _goToRoom,
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required IconData icon,
    required Color iconColor,
    required String title,

required String subtitle,
    required String rewardText,
    required bool isCompleted,
    required bool isClaimed,
    required VoidCallback onClaim,
    required VoidCallback onGo,
  }) {
    String buttonText = isClaimed ? 'Claimed' : (isCompleted ? 'Claim' : 'Go');
    Color btnColor = isClaimed
        ? Colors.grey[800]!
        : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF6B46C1));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1742),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      rewardText,
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isClaimed ? null : (isCompleted ? onClaim : onGo),
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
