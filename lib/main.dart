import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const HalaExactCloneApp());
}

class HalaExactCloneApp extends StatelessWidget {
  const HalaExactCloneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hala Voice',
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
// App State & Data
// ==========================================
class AppData {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static String userName = "KEDIR ,,,\n";
  static String userId = "1753925";
  static int followedCount = 3118;
  static int followingCount = 519;
  static int friendsCount = 104;
  static int coins = 0;
  static double points = 23903.91;

  static List<Map<String, dynamic>> activeRooms = [
    {
      'id': 'room_1042',
      'title': '🇪🇹 አዲስ Coin አገኘን እንዳያመልጣችሁ...',
      'host': 'Ousman',
      'category': 'FRIENDS',
      'users': '4.58k',
    },
    {
      'id': 'room_1043',
      'title': '👑 Fish 🪙 ፕሬዝ አሸናፊዎች እን...',
      'host': 'Coin Seller',
      'category': 'EMOTION',
      'users': '2.34k',
    },
    {
      'id': 'room_1044',
      'title': '🎵 Coin አለ ኧር አዳራሾች ቤት',
      'host': 'Nate Fams',
      'category': 'FASHION',
      'users': '2.23k',
    },
  ];
}

// ==========================================
// Splash Screen
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
    Future.delayed(const Duration(milliseconds: 1400), () {
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
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFF00E676),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 60, color: Colors.black),
            ),
            const SizedBox(height: 20),
            const Text('Hala Live Voice', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Main Navigation Hub (Bottom Navigation)
// ==========================================
class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({Key? key}) : super(key: key);

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const PartyHomeScreen(),
      const Center(child: Text('Moment Feed', style: TextStyle(color: Colors.white))),
      const MessageScreen(),
      MeProfileScreen(onUpdate: () => setState(() {})),
    ];

return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: const Color(0xFF131722),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Room'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Moment'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }
}

// ==========================================
// 1. Party Home Screen
// ==========================================
class PartyHomeScreen extends StatelessWidget {
  const PartyHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F121C),
        elevation: 0,
        title: Row(
          children: const [
            Text('Follow', style: TextStyle(fontSize: 16, color: Colors.white54, fontWeight: FontWeight.bold)),
            SizedBox(width: 14),
            Text('Party', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: () {}),
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
                      Text('New Host No-target warning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('አዲስ አስተናጋጅ ያለ ላምፕ ማስታወቂያ', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.redeem, size: 45, color: Colors.amberAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ranking & Events Center
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF4081), Color(0xFFFF80AB)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.emoji_events, color: Colors.amberAccent, size: 28),
                      SizedBox(width: 8),
                      Text('Ranking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5252)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.card_giftcard, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text('Events Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Active Rooms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),

          ...AppData.activeRooms.map((r) => _buildRoomCard(context, r)).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text('Start Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveVoiceRoomScreen(roomId: r['id'] ?? 'room_1042', title: 'Live Voice Party'),
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
        subtitle: Text('Host: ${r['host']} • ${r['category']}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
        trailing: Text(r['users'], style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveVoiceRoomScreen(roomId: r['id'], title: r['title']),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. Message Screen
// ==========================================
class MessageScreen extends StatelessWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _msgTile(context, Icons.mark_email_unread, 'System Message', 'Withdrawal received', '08-25 14:21:11', Colors.cyan),
          _msgTile(context, Icons.notifications_active, 'Official Notification', 'Hala 1st Anniversary event alert', 'New', Colors.amber),
          _msgTile(context, Icons.receipt_long, 'Order Messages', 'Coin purchase & transaction records', 'Update', Colors.deepOrange),
          _msgTile(context, Icons.headset_mic, 'Customer Service', '24/7 Support & help desk assistance', 'Online', Colors.green),
        ],
      ),
    );
  }

Widget _msgTile(BuildContext context, IconData icon, String title, String subtitle, String time, Color color) {
    return Card(
      color: const Color(0xFF161A28),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        trailing: Text(time, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $title...')));
        },
      ),
    );
  }
}

// ==========================================
// 3. Me Profile Screen (All features clickable)
// ==========================================
class MeProfileScreen extends StatelessWidget {
  final VoidCallback onUpdate;
  const MeProfileScreen({Key? key, required this.onUpdate}) : super(key: key);

  void _openPage(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text('$title Screen Loaded Successfully', style: const TextStyle(fontSize: 16, color: Color(0xFF00E676)))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        children: [
          // Profile Header
          Row(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.amber,
                child: Text('👑', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppData.userName.replaceAll('\n', ''), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ID:${AppData.userId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16), onPressed: () => _openPage(context, 'Edit Profile')),
            ],
          ),
          const SizedBox(height: 16),

          // Follow Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('${AppData.followedCount}', 'Followed'),
              _statItem('${AppData.followingCount}', 'Following'),
              _statItem('${AppData.friendsCount}', 'Friends'),
            ],
          ),
          const SizedBox(height: 16),

          // VIP Club Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3E2723), Color(0xFF8D6E63)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('VIP Club', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amberAccent)),
                    SizedBox(height: 2),
                    Text('Upgrade to VIP and get free coins daily', style: TextStyle(fontSize: 11, color: Colors.white70)),

],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  onPressed: () => _openPage(context, 'VIP Club'),
                  child: const Text('Get VIP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Coins & Points Container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Coins', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${AppData.coins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.white12),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Points', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${AppData.points}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid Menu Items (Recharge, Store, etc.)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _gridMenu(context, Icons.account_balance_wallet, 'Recharge', Colors.amber),
              _gridMenu(context, Icons.store, 'Store', Colors.purpleAccent),
              _gridMenu(context, Icons.card_giftcard, 'Invitation', Colors.pinkAccent),
              _gridMenu(context, Icons.backpack, 'Backpack', Colors.cyan),
              _gridMenu(context, Icons.waves, 'Lucky Island', Colors.green),
              _gridMenu(context, Icons.star, 'Level', Colors.purple),
              _gridMenu(context, Icons.task, 'Task', Colors.orange),
              _gridMenu(context, Icons.shield, 'Badge', Colors.amberAccent),
            ],
          ),
          const SizedBox(height: 20),

          // Second Section Grid (Host Center, Agency, etc.)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(14)),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _gridMenu(context, Icons.mic_external_on, 'Host Center', Colors.lightBlue),
                _gridMenu(context, Icons.business_center, 'Agency', Colors.teal),
                _gridMenu(context, Icons.monetization_on, 'Coin Seller', Colors.amber),
                _gridMenu(context, Icons.support_agent, 'Support', Colors.indigoAccent),
                _gridMenu(context, Icons.info_outline, 'About', Colors.greenAccent),
                _gridMenu(context, Icons.settings, 'Setting', Colors.blueGrey),
                _gridMenu(context, Icons.settings_input_antenna, 'Network Line', Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _gridMenu(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => _openPage(context, label),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ==========================================
// 4. Live Voice Room Screen
// ==========================================
class LiveVoiceRoomScreen extends StatefulWidget {
  final String roomId;
  final String title;
  const LiveVoiceRoomScreen({Key? key, required this.roomId, required this.title}) : super(key: key);

  @override
  State<LiveVoiceRoomScreen> createState() => _LiveVoiceRoomScreenState();
}

class _LiveVoiceRoomScreenState extends State<LiveVoiceRoomScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMicOn = true;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: AppData.agoraAppId,
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

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF00E676), child: Icon(Icons.mic, size: 45, color: Colors.black)),
            const SizedBox(height: 16),
            Text(_isJoined ? '🟢 Connected to Live Room' : '⏳ Connecting...', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
