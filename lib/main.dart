import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';
import 'room_screen.dart';
import 'messages_screen.dart';
import 'recharge_screen.dart';
import 'points_screen.dart';
import 'host_center_screen.dart';
import 'agency_screen.dart';
import 'coin_seller_screen.dart';
import 'daily_tasks_screen.dart';
import 'face_verification_screen.dart';
import 'screen/login_screen.dart';
import 'screens/start_live_screen.dart';
import 'screens/live_audio_room_screen.dart';

import 'store_screen.dart';
import 'backpack_screen.dart';
import 'level_screen.dart';
import 'support_screen.dart';
import 'settings_screen.dart';
import 'invite_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserService().initializeUser();
  runApp(const NileVoiceApp());
}

class NileVoiceApp extends StatelessWidget {
  const NileVoiceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nile Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F141C),
        primaryColor: const Color(0xFF00C9A7),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/face_verification': (context) => const FaceVerificationScreen(),
        '/store': (context) => const StoreScreen(),
        '/backpack': (context) => const BackpackScreen(),
        '/level': (context) => const LevelScreen(),
        '/support': (context) => const SupportScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePartyScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF161B26),
        selectedItemColor: const Color(0xFF00C9A7),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.headset),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

// 3D Party Screen በቀጥታ እዚህ ተካትቷል (ከውጪ ፋይል መፈለግ አይጠበቅበትም)
class HomePartyScreen extends StatefulWidget {
  const HomePartyScreen({Key? key}) : super(key: key);

  @override
  State<HomePartyScreen> createState() => _HomePartyScreenState();
}

class _HomePartyScreenState extends State<HomePartyScreen> {
  final List<Map<String, dynamic>> _liveRooms = [
    {
      'title': 'Habesha Chill & Music 🎵',
      'host': 'Sara_Des',
      'listeners': '1.2k',
      'tag': 'Music',
      'gradient': [const Color(0xFF4F46E5), const Color(0xFF06B6D4)],
    },
    {
      'title': 'Coffee & Life Chat ☕',
      'host': 'Aman_Voice',
      'listeners': '840',
      'tag': 'Chat',
      'gradient': [const Color(0xFFD97706), const Color(0xFFDC2626)],

},
    {
      'title': 'Night Owls Gaming 🎮',
      'host': 'Rediet_Pro',
      'listeners': '2.5k',
      'tag': 'Game',
      'gradient': [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
    },
    {
      'title': 'Friendship & Fun Lounge ✨',
      'host': 'Kedir_O',
      'listeners': '620',
      'tag': 'Friendly',
      'gradient': [const Color(0xFF059669), const Color(0xFF10B981)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Party Lounge',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Host 3D Voice Rooms 🎙️',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Go live, invite friends, and receive gifts daily!',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 48),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final room = _liveRooms[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveAudioRoomScreen(
                            roomTitle: room['title'],
                            channelName: 'room_${index + 1}',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: room['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              room['tag'],
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            room['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            room['host'],
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _liveRooms.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StartLiveScreen()),
          );
        },
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text('Go Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _user = UserService();

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    await _user.initializeUser();
    if (mounted) setState(() {});
  }

  Future<void> _openFaceVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerificationScreen()),
    );
    if (result == true && mounted) {
      await _refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = _user.isFaceVerified;

    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: const Color(0xFF00C9A7),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF00C9A7),
                      child: Text(
                        _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(

crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user.userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161B26),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  'ID: ${_user.userId}',
                                  style: const TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: isVerified ? null : _openFaceVerification,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? const Color(0xFF00C9A7).withOpacity(0.18)
                                        : Colors.orangeAccent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isVerified ? const Color(0xFF00C9A7) : Colors.orangeAccent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isVerified ? Icons.verified : Icons.error_outline,
                                        color: isVerified ? const Color(0xFF00C9A7) : Colors.orangeAccent,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isVerified ? 'Verified' : 'Verify Face',
                                        style: TextStyle(
                                          color: isVerified ? const Color(0xFF00C9A7) : Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(
                          context,

MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E2415), Color(0xFF161B26)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VIP Club', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Upgrade to VIP and get free daily coins', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {},
                        child: const Text('Get VIP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RechargeScreen()),
                          );
                          _refreshProfile();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B26),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Coins', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_user.coins}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),

const CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.amber,
                                child: Icon(Icons.monetization_on, color: Colors.black, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PointsScreen()),
                          );
                          _refreshProfile();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B26),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Points', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_user.points}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF38B29C),
                                child: Icon(Icons.diamond, color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HostCenterScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildActionItem(icon: Icons.mic_external_on, label: 'Host Center'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),

onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AgencyScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildActionItem(icon: Icons.groups_outlined, label: 'Agency'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CoinSellerScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildActionItem(icon: Icons.storefront_outlined, label: 'Coin Seller'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 10,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyTasksScreen(),
                            ),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.task_alt, label: 'Task'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InviteScreen(
                                userId: _user.userId,
                                userName: _user.userName.isNotEmpty ? _user.userName : 'User_${_user.userId}',
                                onRewardClaimed: (bonusCoins) {
                                  _user.coins += bonusCoins;
                                  _refreshProfile();
                                },
                              ),
                            ),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.person_add_alt, label: 'Invite'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StoreScreen()),
                          );

},
                        child: _buildGridMenuItem(icon: Icons.shopping_bag_outlined, label: 'Store'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BackpackScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.backpack_outlined, label: 'Backpack'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LevelScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.military_tech_outlined, label: 'Level'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InternalMedalWallScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.shield_outlined, label: 'Medal Wall'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SupportScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.headset_mic_outlined, label: 'Support'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.tune, label: 'Settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF00C9A7), size: 26),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildGridMenuItem({required IconData icon, required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class InternalMedalWallScreen extends StatelessWidget {
  const InternalMedalWallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(

backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Medal Wall', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text(
          'Medals & Achievements Coming Soon!',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
    );
  }
}
