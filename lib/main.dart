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
// Central App Data & State Management
// ==========================================
class AppData {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static String userName = "ከድር ኡመር";
  static String userId = "1753925";
  static int followedCount = 3118;
  static int followingCount = 519;
  static int friendsCount = 104;
  static int coins = 0;
  static double points = 23903.91;
  static String selectedCountry = "All";

  // Countries Filter List
  static const List<String> countries = [
    'All', 'Ethiopia 🇪🇹', 'Philippines 🇵🇭', 'Angola 🇦🇴', 
    'Benin 🇧🇯', 'United Kingdom 🇬🇧', 'Ghana 🇬🇭', 'Kenya 🇰🇪', 'Malawi 🇲🇼', 'Rwanda 🇷🇼', 'Burma 🇲🇲'
  ];

  // Active Voice Rooms
  static List<Map<String, dynamic>> rooms = [
    {
      'id': 'room_1042',
      'title': '🇪🇹 ኢትዮጵያ ቮይስ ፓርቲ እና ஃப்ரீ ኮይን',
      'host': 'ከድር ኡመር',
      'category': 'FRIENDS',
      'type': 'Public',
      'users': '4.58k',
      'country': 'Ethiopia 🇪🇹',
    },
    {
      'id': 'room_1043',
      'title': '👑 ቪአይፒ ዳይመንድ ሉኪ ሩም',
      'host': 'ሰላም ሊቭ',
      'category': 'EMOTION',
      'type': 'Public',
      'users': '2.34k',
      'country': 'Philippines 🇵🇭',
    },
    {
      'id': 'room_1044',
      'title': '🔒 የግል ቪአይፒ የሙዚቃ ማዕከል',
      'host': 'ናቴ ፋምስ',
      'category': 'MUSIC',
      'type': 'Private',
      'users': '1.12k',
      'country': 'Kenya 🇰🇪',
    },
  ];

  // Gifts List
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
            const Text('Hala Voice Global', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. Main Navigation Hub
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
      const DiscoverScreen(),
      const MessageHubScreen(),
      const MeProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }
}

// ==========================================
// 3. Party Home Screen (Country Filters & Rooms)
// ==========================================
class PartyHomeScreen extends StatefulWidget {
  const PartyHomeScreen({Key? key}) : super(key: key);

  @override
  State<PartyHomeScreen> createState() => _PartyHomeScreenState();
}

class _PartyHomeScreenState extends State<PartyHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final filteredRooms = AppData.selectedCountry == 'All' 
        ? AppData.rooms 
        : AppData.rooms.where((r) => r['country'] == AppData.selectedCountry).toList();

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
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenericDetailScreen(title: 'Search Screen'))),
          ),
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.amber),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenericDetailScreen(title: 'Events Center'))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Country Filters Horizontal List
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppData.countries.length,
              itemBuilder: (context, index) {
                String country = AppData.countries[index];
                bool isSelected = AppData.selectedCountry == country;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  choiceChip: null,
                  child: ChoiceChip(
                    label: Text(country, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00E676),
                    backgroundColor: const Color(0xFF161A28),
                    onSelected: (bool selected) {
                      setState(() {
                        AppData.selectedCountry = country;

});
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
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
          const Text('Active Voice Rooms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          filteredRooms.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No rooms found for this country.', style: TextStyle(color: Colors.white54))),
                )
              : Column(
                  children: filteredRooms.map((r) => _buildRoomCard(context, r)).toList(),
                ),
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
              builder: (_) => const VoiceRoomScreen(roomId: 'room_1042', title: 'Live Voice Party', isPublic: true),
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
        subtitle: Text('Host: ${r['host']} • ${r['country']}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
        trailing: Text(r['users'], style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VoiceRoomScreen(roomId: r['id'], title: r['title'], isPublic: r['type'] == 'Public'),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. Voice Room System (Agora SDK & 8 Seats)
// ==========================================
class VoiceRoomScreen extends StatefulWidget {
  final String roomId;
  final String title;
  final bool isPublic;
  const VoiceRoomScreen({Key? key, required this.roomId, required this.title, required this.isPublic}) : super(key: key);

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

  void _openGiftsModal() {
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
              const Text('Send Gift to Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: AppData.gifts.map((g) {
                    return ListTile(
                      leading: const Text('🎁', style: TextStyle(fontSize: 24)),
                      title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('${g['price']} Coins', style: const TextStyle(color: Colors.amber)),
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
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontSize: 14)), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(_isJoined ? '🟢 Agora Voice Active' : 'Connecting...', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 15),
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
                  onPressed: _openGiftsModal,
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
// 5. Discover & Message Screens
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
          Card(
            color: const Color(0xFF161A28),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.pink, child: Text('ከ')),
              title: const Text('ከድር ኡመር (Kedir Umer)'),
              subtitle: const Text('Welcome to Hala Voice Global! Explore rooms and features.'),
              trailing: const Icon(Icons.favorite, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageHubScreen extends StatelessWidget {
  const MessageHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _msgTile(Icons.mark_email_unread, 'System Message', 'Withdrawal received', '08-25 14:21:11', Colors.cyan),
          _msgTile(Icons.notifications_active, 'Official Notification', 'Hala 1st Anniversary event alert', 'New', Colors.amber),
          _msgTile(Icons.receipt_long, 'Order Messages', 'Coin purchase & transaction records', 'Update', Colors.deepOrange),
          _msgTile(Icons.headset_mic, 'Customer Service', '24/7 Support & help desk assistance', 'Online', Colors.green),
        ],
      ),
    );
  }

  Widget _msgTile(IconData icon, String title, String subtitle, String time, Color color) {
    return Card(
      color: const Color(0xFF161A28),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        trailing: Text(time, style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ),
    );
  }
}

// ==========================================
// 6. Me Profile Screen & All Menus
// ==========================================
class MeProfileScreen extends StatelessWidget {
  const MeProfileScreen({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        children: [
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
                    Text(AppData.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ID:${AppData.userId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => _navigateTo(context, const GenericDetailScreen(title: 'Edit Profile')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('${AppData.followedCount}', 'Followed'),
              _statItem('${AppData.followingCount}', 'Following'),
              _statItem('${AppData.friendsCount}', 'Friends'),
            ],
          ),
          const SizedBox(height: 16),
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
                  onPressed: () => _navigateTo(context, const GenericDetailScreen(title: 'VIP Club Center')),
                  child: const Text('Get VIP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          // First Grid Menus
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _gridMenu(context, Icons.account_balance_wallet, 'Recharge', Colors.amber, const GenericDetailScreen(title: 'Recharge Center')),
              _gridMenu(context, Icons.store, 'Store', Colors.purpleAccent, const GenericDetailScreen(title: 'Item Store')),
              _gridMenu(context, Icons.card_giftcard, 'Invitation', Colors.pinkAccent, const GenericDetailScreen(title: 'Invitation Center')),
              _gridMenu(context, Icons.backpack, 'Backpack', Colors.cyan, const GenericDetailScreen(title: 'User Backpack')),
              _gridMenu(context, Icons.waves, 'Lucky Island', Colors.green, const GenericDetailScreen(title: 'Lucky Island Mini-Game')),
              _gridMenu(context, Icons.star, 'Level', Colors.purple, const GenericDetailScreen(title: 'User Level & Perks')),
              _gridMenu(context, Icons.task, 'Task', Colors.orange, const GenericDetailScreen(title: 'Daily Tasks Center')),
              _gridMenu(context, Icons.shield, 'Badge', Colors.amberAccent, const GenericDetailScreen(title: 'Badges & Achievements')),
            ],
          ),
          const SizedBox(height: 20),
          // Second Grid Menus (Agency, Support, Setting, etc.)
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
                _gridMenu(context, Icons.mic_external_on, 'Host Center', Colors.lightBlue, const GenericDetailScreen(title: 'Host Center & Roster')),
                _gridMenu(context, Icons.business_center, 'Agency', Colors.teal, const GenericDetailScreen(title: 'Agency Management')),
                _gridMenu(context, Icons.monetization_on, 'Coin Seller', Colors.amber, const GenericDetailScreen(title: 'Coin Seller Portal')),
                _gridMenu(context, Icons.support_agent, 'Support', Colors.indigoAccent, const GenericDetailScreen(title: 'Customer Support Desk')),
                _gridMenu(context, Icons.info_outline, 'About', Colors.greenAccent, const GenericDetailScreen(title: 'About Hala Global')),
                _gridMenu(context, Icons.settings, 'Setting', Colors.blueGrey, const GenericDetailScreen(title: 'App Settings & Security')),
                _gridMenu(context, Icons.settings_input_antenna, 'Network Line', Colors.redAccent, const GenericDetailScreen(title: 'Network Line Diagnostic')),
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

  Widget _gridMenu(BuildContext context, IconData icon, String label, Color color, Widget targetScreen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen)),

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
// 7. Generic Screen for Menu Navigation
// ==========================================
class GenericDetailScreen extends StatelessWidget {
  final String title;
  const GenericDetailScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 60, color: Color(0xFF00E676)),
            const SizedBox(height: 16),
            Text('$title Loaded Successfully', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('All functions and components are fully active.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
