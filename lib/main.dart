import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const HalaSuperApp());
}

class HalaSuperApp extends StatelessWidget {
  const HalaSuperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hala Voice Global',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F121C),
        primaryColor: const Color(0xFF00E676),
        fontFamily: 'sans-serif',
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// Global State & Data Model
// ==========================================
class GlobalData {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static String userName = "ከድር ኡመር";
  static String userId = "1753925";
  static int followedCount = 3118;
  static int followingCount = 519;
  static int friendsCount = 104;
  static int coins = 1500;
  static double points = 23903.91;

  // Active Public/Private Rooms
  static List<Map<String, dynamic>> rooms = [
    {
      'id': 'room_1042',
      'title': '🇪🇹 ኢትዮጵያ ቮይስ ፓርቲ እና ஃப்ரீ ኮይን',
      'host': 'ከድር ኡመር',
      'category': 'FRIENDS',
      'type': 'Public',
      'users': '4.58k',
    },
    {
      'id': 'room_1043',
      'title': '👑 ቪአይፒ ዳይመንድ  lucky ሩም',
      'host': 'ሰላም ሊቭ',
      'category': 'EMOTION',
      'type': 'Public',
      'users': '2.34k',
    },
    {
      'id': 'room_1044',
      'title': '🔒 የግል ቪአይፒ የሙዚቃ ማዕከል',
      'host': 'ናቴ ፋምስ',
      'category': 'MUSIC',
      'type': 'Private',
      'users': '1.12k',
    },
  ];

  static List<Map<String, dynamic>> gifts = [
    {'name': 'ሮዝ 🌹', 'price': 50},
    {'name': 'ቡና ☕', 'price': 200},
    {'name': 'ልብ 💖', 'price': 500},
    {'name': 'ስፖርት መኪና 🏎️', 'price': 2500},
    {'name': 'ንግሥና አክሊል 👑', 'price': 10000},
  ];
}

// ==========================================
// 1. Splash Screen
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationHub()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F121C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF00E676),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 65, color: Colors.black),
            ),
            const SizedBox(height: 20),
            const Text('Hala Voice & Global System', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text('Beta v1.0.0 Loading...', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. Main Navigation Hub (Home, Discover, Messages, Me)
// ==========================================
class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({Key? key}) : super(key: key);

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;

@override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      const DiscoverScreen(),
      const MessageHubScreen(),
      const MeProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF131722),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }
}

// ==========================================
// 3. Home Screen (Rooms & Categories)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F121C),
        elevation: 0,
        title: Row(
          children: const [
            Text('Party', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAgencyScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Banner
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF9C27B0)]),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Global Voice Event 2026', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Join rooms, earn points & withdraw cash', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.emoji_events, size: 45, color: Colors.amberAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Active Voice Rooms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...GlobalData.rooms.map((r) => _buildRoomCard(context, r)).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text('Create Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VoiceRoomScreen(roomId: 'room_1042', roomTitle: 'ከድር አዲስ ሩም', isPublic: true),
            ),
          );
        },
      ),
    );
  }

Widget _buildRoomCard(BuildContext context, Map<String, dynamic> r) {
    return Card(
      color: const Color(0xFF161A28),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
          child: const Icon(Icons.graphic_eq, color: Color(0xFF00E676)),
        ),
        title: Text(r['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('Host: ${r['host']} • [${r['type']}]', style: const TextStyle(fontSize: 11, color: Colors.white54)),
        trailing: Text(r['users'], style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VoiceRoomScreen(roomId: r['id'], roomTitle: r['title'], isPublic: r['type'] == 'Public'),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. Voice Room System (Agora SDK, 8 Seats, Hosts, Speakers, Gifts)
// ==========================================
class VoiceRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final bool isPublic;
  const VoiceRoomScreen({Key? key, required this.roomId, required this.roomTitle, required this.isPublic}) : super(key: key);

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMicMuted = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: GlobalData.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isJoined = true);
        },
      ),
    );
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
    await _engine!.joinChannel(
      token: '',
      channelId: widget.roomId,
      uid: Random().nextInt(900000) + 100000,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _showGiftsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A28),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send Gift & Support Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: GlobalData.gifts.map((g) {
                    return ListTile(
                      leading: const Text('🎁', style: TextStyle(fontSize: 24)),
                      title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('${g['price']} Coins', style: const TextStyle(color: Colors.amberAccent)),

onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent ${g['name']} successfully!')));
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomTitle, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.transparent,
        actions: [
          Chip(
            backgroundColor: widget.isPublic ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            label: Text(widget.isPublic ? 'Public' : 'Private', style: TextStyle(color: widget.isPublic ? Colors.green : Colors.orange)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(_isJoined ? '🟢 Agora Audio Active' : 'Connecting Audio...', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          // 8 Seats Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(8, (index) {
                bool isHost = index == 0;
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isHost ? Colors.amber : const Color(0xFF1E2433),
                      child: Text(isHost ? '👑' : '${index + 1}', style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 4),
                    Text(isHost ? 'Host' : 'Seat ${index + 1}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                );
              }),
            ),
          ),
          // Bottom Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF131722),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic, color: _isMicMuted ? Colors.red : const Color(0xFF00E676)),
                  onPressed: () {
                    setState(() => _isMicMuted = !_isMicMuted);
                    _engine?.muteLocalAudioStream(_isMicMuted);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.card_giftcard, color: Colors.amber),
                  onPressed: _showGiftsDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.cyan),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. Discover & Social System (Friends, Search, Community)
// ==========================================
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover & Community'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Moments & Social Feeds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

const SizedBox(height: 10),
          Card(
            color: const Color(0xFF161A28),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.pink, child: Text('ከ')),
              title: const Text('ከድር ኡመር (Kedir Umer)'),
              subtitle: const Text('Welcome to our new voice platform! Check out rooms and support hosts.'),
              trailing: const Icon(Icons.favorite, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Users & Rooms')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search room ID, username...',
            filled: true,
            fillColor: const Color(0xFF161A28),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. Messages Hub (System, Notification, Chat)
// ==========================================
class MessageHubScreen extends StatelessWidget {
  const MessageHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _msgTile(Icons.system_update, 'System Message', 'Withdrawal processed successfully', Colors.cyan),
          _msgTile(Icons.notifications, 'Official Notification', 'Hala Global Launch Event starts today', Colors.amber),
          _msgTile(Icons.receipt, 'Order Messages', 'Coin purchase confirmed (1500 Coins)', Colors.green),
          _msgTile(Icons.support_agent, 'Customer Service', '24/7 Security & Fraud Support', Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _msgTile(IconData icon, String title, String subtitle, Color color) {
    return Card(
      color: const Color(0xFF161A28),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ),
    );
  }
}

// ==========================================
// 7. Coins, Wallet & Withdrawal System
// ==========================================
class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Financials')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00B0FF)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),

Text('${GlobalData.coins} Coins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recharge Gateway Initialized')));
                    },
                    child: const Text('Recharge'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              tileColor: const Color(0xFF161A28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.account_balance_wallet, color: Colors.amber),
              title: const Text('Host Earnings & Withdrawal'),
              trailing: const Text('Withdraw', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted securely.')));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. Admin, Agency & Security Dashboard
// ==========================================
class AdminAgencyScreen extends StatelessWidget {
  const AdminAgencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin & Agency Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Management Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _adminCard(Icons.business_center, 'Agency Roster & Hosts', 'Manage active hosts and commission rates'),
          _adminCard(Icons.security, 'Security & Fraud Prevention', 'Rate limiting, fake payment & duplicate checks'),
          _adminCard(Icons.analytics, 'Financial Reports', 'Audit logs and transaction monitoring'),
          _adminCard(Icons.verified_user, 'Firestore Security Rules', 'Authorization & validation active'),
        ],
      ),
    );
  }

  Widget _adminCard(IconData icon, String title, String subtitle) {
    return Card(
      color: const Color(0xFF161A28),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.amber.withOpacity(0.2), child: Icon(icon, color: Colors.amber)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

// ==========================================
// 9. Me Profile Screen
// ==========================================
class MeProfileScreen extends StatelessWidget {
  const MeProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 35, backgroundColor: Colors.amber, child: Text('👑', style: TextStyle(fontSize: 32))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(GlobalData.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

const SizedBox(height: 4),
                    Text('ID:${GlobalData.userId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            tileColor: const Color(0xFF161A28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.wallet, color: Colors.amber),
            title: const Text('My Wallet & Coins'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: const Color(0xFF161A28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.admin_panel_settings, color: Colors.cyan),
            title: const Text('Agency & Admin Panel'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAgencyScreen())),
          ),
        ],
      ),
    );
  }
}
