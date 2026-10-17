import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({Key? key}) : super(key: key);

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  final UserService _user = UserService();
  bool _isLoading = true;
  Map<String, dynamic>? _taskData;

  final List<int> _rewardsMap = [20, 30, 40, 50, 60, 80, 100];

  @override
  void initState() {
    super.initState();
    _fetchTaskStatus();
  }

  Future<void> _fetchTaskStatus() async {
    setState(() => _isLoading = true);
    try {
      final url = UserService.serverUrl + '/api/tasks/today?userId=' + _user.userId;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _taskData = decoded['tasks'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIn() async {
    try {
      final url = UserService.serverUrl + '/api/tasks/check-in';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _user.userId}),
      );
      final decoded = jsonDecode(response.body);

      if (decoded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily bonus collected! +${decoded['rewardCoins']} Coins'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTaskStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Check-in failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _claimReward(String taskType) async {
    try {
      final url = UserService.serverUrl + '/api/tasks/claim';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _user.userId,
          'taskType': taskType,
        }),
      );
      final decoded = jsonDecode(response.body);

      if (decoded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reward claimed! +${decoded['rewardCoins']} Coins'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTaskStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Claim failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _shareAppInvitation() {
    Clipboard.setData(
      const ClipboardData(
        text: 'Join me on Nile Voice! Enjoy voice chat rooms and earn coins daily: https://nilevoice.com',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation link copied to clipboard!'),
        backgroundColor: Color(0xFF00C9A7),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = _taskData?['isCheckedIn'] ?? false;
    final int currentDay = _taskData?['checkInDay'] ?? 1;

final int stayMins = _taskData?['stayDurationMinutes'] ?? 0;
    final bool stay10Claimed = _taskData?['stay10Claimed'] ?? false;
    final bool stay30Claimed = _taskData?['stay30Claimed'] ?? false;

    final int giftSent = _taskData?['giftSentCount'] ?? 0;
    final bool giftClaimed = _taskData?['giftClaimed'] ?? false;

    final int msgsSent = _taskData?['messagesSentCount'] ?? 0;
    final bool msgClaimed = _taskData?['messageClaimed'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daily Tasks & Rewards',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
          : RefreshIndicator(
              onRefresh: _fetchTaskStatus,
              color: const Color(0xFF00C9A7),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C1958), Color(0xFF161B26)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '7-Day Check-in',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCheckedIn ? Colors.grey.shade700 : const Color(0xFF00C9A7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: isCheckedIn ? null : _checkIn,
                              child: Text(
                                isCheckedIn ? 'Completed' : 'Check In',
                                style: TextStyle(
                                  color: isCheckedIn ? Colors.white54 : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final dayNumber = index + 1;
                            final isPassed = isCheckedIn && dayNumber <= currentDay;
                            return Column(
                              children: [

CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isPassed
                                      ? const Color(0xFF00C9A7)
                                      : (dayNumber == currentDay ? Colors.amber : Colors.white10),
                                  child: isPassed
                                      ? const Icon(Icons.check, color: Colors.black, size: 18)
                                      : Text(
                                          '+${_rewardsMap[index]}',
                                          style: TextStyle(
                                            color: dayNumber == currentDay ? Colors.black : Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'D$dayNumber',
                                  style: TextStyle(
                                    color: dayNumber == currentDay ? Colors.amber : Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Daily Activities',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildActivityTile(
                    icon: Icons.headset_mic,
                    iconColor: Colors.cyanAccent,
                    title: 'Listen in Room for 10 Mins',
                    subtitle: 'Progress: $stayMins/10 mins',
                    reward: '+30 Coins',
                    isDone: stayMins >= 10,
                    isClaimed: stay10Claimed,
                    onClaim: () => _claimReward('stay10'),
                  ),
                  _buildActivityTile(
                    icon: Icons.timer,
                    iconColor: Colors.tealAccent,
                    title: 'Listen in Room for 30 Mins',
                    subtitle: 'Progress: $stayMins/30 mins',
                    reward: '+60 Coins',
                    isDone: stayMins >= 30,
                    isClaimed: stay30Claimed,
                    onClaim: () => _claimReward('stay30'),
                  ),
                  _buildActivityTile(
                    icon: Icons.card_giftcard,
                    iconColor: Colors.pinkAccent,
                    title: 'Send 1 Gift to Host',
                    subtitle: 'Progress: $giftSent/1 sent',
                    reward: '+50 Coins',
                    isDone: giftSent >= 1,
                    isClaimed: giftClaimed,
                    onClaim: () => _claimReward('gift'),
                  ),
                  _buildActivityTile(
                    icon: Icons.chat,
                    iconColor: Colors.purpleAccent,
                    title: 'Send 5 Direct Messages',
                    subtitle: 'Progress: $msgsSent/5 sent',
                    reward: '+20 Coins',
                    isDone: msgsSent >= 5,
                    isClaimed: msgClaimed,
                    onClaim: () => _claimReward('messages'),
                  ),
                  _buildActivityTile(
                    icon: Icons.share,
                    iconColor: Colors.orangeAccent,

title: 'Invite Friends / Share App',
                    subtitle: 'Share Nile Voice with friends',
                    reward: '+25 Coins',
                    isDone: true,
                    isClaimed: false,
                    customBtn: 'Copy Link',
                    onClaim: _shareAppInvitation,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String reward,
    required bool isDone,
    required bool isClaimed,
    required VoidCallback onClaim,
    String? customBtn,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor, size: 22),
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  reward,
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isClaimed
                  ? Colors.grey.shade800
                  : (isDone ? const Color(0xFF00C9A7) : Colors.white12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: isClaimed ? null : (isDone ? onClaim : null),
            child: Text(
              isClaimed
                  ? 'Claimed'
                  : (customBtn ?? (isDone ? 'Claim' : 'Go')),
              style: TextStyle(
                color: isClaimed
                    ? Colors.white38
                    : (isDone ? Colors.black : Colors.white38),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
