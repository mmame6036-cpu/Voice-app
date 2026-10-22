import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';
import 'face_verification_screen.dart';

class TaskScreen extends StatefulWidget {
  final dynamic userId;
  final dynamic userData;

  const TaskScreen({
    Key? key,
    this.userId,
    this.userData,
  }) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final UserService _user = UserService();
  bool _isLoading = true;

  int totalPoints = 0;
  int streakDays = 0;
  int liveMinutesToday = 0;
  int chairMinutesToday = 0;
  int giftCoinsReceived = 0;

  @override
  void initState() {
    super.initState();
    _fetchTaskData();
  }

  Future<void> _fetchTaskData() async {
    setState(() => _isLoading = true);
    final currentUserId = widget.userId?.toString() ?? _user.userId;

    try {
      final url = UserService.serverUrl + '/api/tasks/today?userId=' + currentUserId;
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final t = data['tasks'];
          setState(() {
            liveMinutesToday = t['stayDurationMinutes'] ?? 0;
            chairMinutesToday = t['stayDurationMinutes'] ?? 0;
            giftCoinsReceived = t['giftSentCount'] ?? 0;
            streakDays = t['checkInDay'] ?? 1;
            totalPoints = _user.coins;
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A2B3D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openFaceVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaceVerificationScreen(),
      ),
    );

    if (result == true) {
      setState(() {
        _user.isFaceVerified = true;
      });
      _notify('Face verified! Tasks unlocked and active.');
      _fetchTaskData();
    }
  }

  void _onGoPressed() {
    if (!_user.isFaceVerified) {
      _notify('Please verify your face first to access voice room seats.');
      _openFaceVerification();
    } else {
      _notify('Redirecting to live voice room...');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = _user.isFaceVerified;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1017),
      appBar: AppBar(
        title: const Text(
          'Host Task Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF181926),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            onPressed: _fetchTaskData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPointsHeader(),
                  const SizedBox(height: 20),
                  _buildFaceVerificationCard(),

const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily & Weekly Targets',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, color: Colors.redAccent, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'LOCKED',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTaskCard(
                    title: '7-Day Live Streak',
                    points: '8,000 Points',
                    requirement: 'Stream 2 hours (120 mins) daily for 7 consecutive days',
                    progressText: isUnlocked
                        ? '$streakDays / 7 Days completed'
                        : 'Locked: Verify face to start streak',
                    progressValue: isUnlocked ? (streakDays / 7.0) : 0.0,
                    icon: Icons.local_fire_department,
                    accentColor: Colors.deepOrangeAccent,
                    isLocked: !isUnlocked,
                    onGo: _onGoPressed,
                  ),
                  const SizedBox(height: 14),
                  _buildTaskCard(
                    title: 'Daily Live Streaming',
                    points: '1,000+ Points',
                    requirement: 'Stream 1 hour (60 mins) daily in voice room',
                    progressText: isUnlocked
                        ? '$liveMinutesToday / 60 Mins completed'
                        : 'Locked: Counter starts after face verification',
                    progressValue: isUnlocked ? (liveMinutesToday / 60.0).clamp(0.0, 1.0) : 0.0,
                    icon: Icons.videocam,
                    accentColor: Colors.cyanAccent,
                    isLocked: !isUnlocked,
                    onGo: _onGoPressed,
                  ),
                  const SizedBox(height: 14),
                  _buildTaskCard(
                    title: 'Golden Chair & Gifts',
                    points: '1,000 Points',
                    requirement: 'Take seat for 1 hour + receive 600 coins in gifts',
                    progressText: isUnlocked
                        ? 'Seat: $chairMinutesToday/60 mins | Gifts: $giftCoinsReceived/600 coins'
                        : 'Locked: Take seat and track gifts after verification',
                    progressValue: isUnlocked
                        ? (((chairMinutesToday / 60.0) + (giftCoinsReceived / 600.0)) / 2.0).clamp(0.0, 1.0)

: 0.0,
                    icon: Icons.event_seat,
                    accentColor: Colors.amberAccent,
                    isLocked: !isUnlocked,
                    onGo: _onGoPressed,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C194D), Color(0xFF1F1C38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Points Earned', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                '$totalPoints',
                style: const TextStyle(color: Colors.amberAccent, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars, color: Colors.amberAccent, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceVerificationCard() {
    final bool isVerified = _user.isFaceVerified;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? Colors.greenAccent : Colors.tealAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isVerified ? Colors.greenAccent.withOpacity(0.15) : Colors.tealAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified ? Icons.verified_user : Icons.face_retouching_natural,
              color: isVerified ? Colors.greenAccent : Colors.tealAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Face Verified' : 'Face Verification Required',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  isVerified
                      ? 'Verification complete. Task counter is actively tracking.'
                      : 'Verify your face to unlock daily tasks and host rewards.',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isVerified)
            ElevatedButton(
              onPressed: _openFaceVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

Widget _buildTaskCard({
    required String title,
    required String points,
    required String requirement,
    required String progressText,
    required double progressValue,
    required IconData icon,
    required Color accentColor,
    required bool isLocked,
    required VoidCallback onGo,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? Colors.white10 : accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLocked ? Colors.white10 : accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? Icons.lock : icon,
                  color: isLocked ? Colors.white38 : accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isLocked ? Colors.white54 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      points,
                      style: TextStyle(
                        color: isLocked ? Colors.white38 : accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onGo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLocked ? const Color(0xFF2C2F48) : Colors.amber,
                  foregroundColor: isLocked ? Colors.white70 : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLocked) ...[
                      const Icon(Icons.lock, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isLocked ? 'Unlock' : 'Go',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(requirement, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF232538),
              valueColor: AlwaysStoppedAnimation<Color>(
                isLocked ? Colors.white24 : accentColor,
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 8),

Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progressText, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Text(
                '${(progressValue.clamp(0.0, 1.0) * 100).toInt()}%',
                style: TextStyle(
                  color: isLocked ? Colors.white38 : accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
