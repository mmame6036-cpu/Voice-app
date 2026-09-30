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
// Central App State & Database
// ==========================================
class AppData {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static String userName = "ከድር ኡመር";
  static String userId = "1753925";
  static int followedCount = 3118;
  static int followingCount = 519;
  static int friendsCount = 104;
  static int coins = 1500;
  static double points = 23903.91;
  static String selectedCountry = "All";

  static const List<String> countries = [
    'All', 'Ethiopia 🇪🇹', 'Philippines 🇵🇭', 'Angola 🇦🇴', 
    'Benin 🇧🇯', 'United Kingdom 🇬🇧', 'Ghana 🇬🇭', 'Kenya 🇰🇪', 'Malawi 🇲🇼', 'Rwanda 🇷🇼', 'Burma 🇲🇲'
  ];

  static List<Map<String, dynamic>> rooms = [
    {
      'id': 'room_1042',
      'title': '🇪🇹 ኢትዮጵያ ቮይስ ፓርቲ እና ஃப்ሪ ኮይን',
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
  ];

  static List<String> backpackItems = ['VIP Avatar Frame', 'Gold Entrance Car'];
  static List<Map<String, dynamic>> agencyHosts = [
    {'name': 'አበበ ደስታ', 'id': '984120', 'hours': '24 hrs', 'points': 4500},
    {'name': 'ማርታ ካሳ', 'id': '541290', 'hours': '38 hrs', 'points': 8900},
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
    Future.delayed(const Duration(milliseconds: 1200), () {
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
// 3. Party Home Screen
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
        title: const Text('Party', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
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
                  child: ChoiceChip(
                    label: Text(country, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00E676),
                    backgroundColor: const Color(0xFF161A28),
                    onSelected: (bool selected) {
                      setState(() => AppData.selectedCountry = country);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          ...filteredRooms.map((r) => Card(
            color: const Color(0xFF161A28),
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1E2433),
                child: Icon(Icons.graphic_eq, color: Color(0xFF00E676)),
              ),
              title: Text(r['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Host: ${r['host']} • ${r['country']}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
              trailing: Text(r['users'], style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(

context,
                  MaterialPageRoute(builder: (_) => VoiceRoomScreen(roomId: r['id'], title: r['title'])),
                );
              },
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text('Start Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VoiceRoomScreen(roomId: 'room_1042', title: 'Live Voice Party')),
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. Voice Room Screen
// ==========================================
class VoiceRoomScreen extends StatefulWidget {
  final String roomId;
  final String title;
  const VoiceRoomScreen({Key? key, required this.roomId, required this.title}) : super(key: key);

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

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(_isJoined ? '🟢 Agora Voice Online' : 'Connecting...', style: const TextStyle(color: Colors.white54)),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              padding: const EdgeInsets.all(16),
              children: List.generate(8, (index) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: index == 0 ? Colors.amber : const Color(0xFF1E2433),
                      child: Text(index == 0 ? '👑' : '${index + 1}'),
                    ),
                    const SizedBox(height: 4),
                    Text(index == 0 ? 'Host' : 'Seat ${index + 1}', style: const TextStyle(fontSize: 10)),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gift sent successfully!')));
                  },
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
      appBar: AppBar(title: const Text('Discover')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: const [
          Card(
            color: Color(0xFF161A28),
            child: ListTile(
              leading: CircleAvatar(child: Text('H')),
              title: Text('Welcome to Hala Voice Global'),
              subtitle: Text('Discover friends and rooms from around the world!'),
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
      appBar: AppBar(title: const Text('Message')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            tileColor: const Color(0xFF161A28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.campaign, color: Colors.amber),
            title: const Text('System Notification'),
            subtitle: const Text('Welcome to Hala Official Agency Portal'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. Me Profile Screen with All Real Modules
// ==========================================
class MeProfileScreen extends StatefulWidget {
  const MeProfileScreen({Key? key}) : super(key: key);

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  void _openAdminCoinEngine() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A28),
        title: const Text('🪙 Admin Coin Generation Engine', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('አስተዳዳሪ ሆይ! አዲስ ኮይን አምርተህ ወደ ሲስተሙ ለማስገባት መጠኑን ጻፍ፦', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'የኮይን መጠን (ለምሳሌ 100000)',
                filled: true,
                fillColor: Color(0xFF0F121C),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            onPressed: () {
              int? val = int.tryParse(amountController.text);
              if (val != null && val > 0) {
                setState(() => AppData.coins += val);

Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$val ኮይኖች በተሳካ ሁኔታ ተመርተዋል!')));
              }
            },
            child: const Text('አምርት (Generate)'),
          ),
        ],
      ),
    );
  }

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
                    Text(AppData.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ID:${AppData.userId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
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
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _openAdminCoinEngine,
                    child: Column(
                      children: [
                        const Text('Coins (ለመፍጠር ንካ)', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${AppData.coins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                      ],
                    ),
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.white12),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Points', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('${AppData.points}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // User Grid Functions
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _gridMenu(context, Icons.account_balance_wallet, 'Recharge', Colors.amber, const RechargeScreen()),
              _gridMenu(context, Icons.store, 'Store', Colors.purpleAccent, const StoreScreen()),
              _gridMenu(context, Icons.card_giftcard, 'Invitation', Colors.pinkAccent, const InvitationScreen()),
              _gridMenu(context, Icons.backpack, 'Backpack', Colors.cyan, const BackpackScreen()),
              _gridMenu(context, Icons.waves, 'Lucky Island', Colors.green, const LuckyIslandScreen()),
              _gridMenu(context, Icons.star, 'Level', Colors.purple, const LevelScreen()),

_gridMenu(context, Icons.task, 'Task', Colors.orange, const TaskScreen()),
              _gridMenu(context, Icons.shield, 'Badge', Colors.amberAccent, const BadgeScreen()),
            ],
          ),
          const SizedBox(height: 16),
          // Agency & Settings Management Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(14)),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _gridMenu(context, Icons.mic_external_on, 'Host Center', Colors.lightBlue, const HostCenterScreen()),
                _gridMenu(context, Icons.business_center, 'Agency', Colors.teal, const AgencyScreen()),
                _gridMenu(context, Icons.precision_manufacturing, 'Coin Engine', Colors.greenAccent, null, onTap: _openAdminCoinEngine),
                _gridMenu(context, Icons.support_agent, 'Support', Colors.indigoAccent, const SupportScreen()),
                _gridMenu(context, Icons.info_outline, 'About', Colors.greenAccent, const AboutScreen()),
                _gridMenu(context, Icons.settings, 'Setting', Colors.blueGrey, const SettingScreen()),
                _gridMenu(context, Icons.network_check, 'Network', Colors.redAccent, const NetworkLineScreen()),
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

  Widget _gridMenu(BuildContext context, IconData icon, String label, Color color, Widget? target, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target!)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 22, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ==========================================
// 7. Store Screen (Avatar Frames & Cars)
// ==========================================
class StoreScreen extends StatelessWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'name': 'Dragon Frame 🐉', 'type': 'Frame', 'price': 5000},
      {'name': 'Super Ferrari 🏎️', 'type': 'Vehicle', 'price': 15000},
      {'name': 'Royal Crown Ring 👑', 'type': 'Entrance', 'price': 8000},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Item Store')),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        itemBuilder: (context, i) {
          var item = items[i];
          return Card(
            color: const Color(0xFF161A28),
            child: ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.purpleAccent),
              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item['type']} • ${item['price']} Coins'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),

onPressed: () {
                  if (AppData.coins >= item['price']) {
                    AppData.coins -= (item['price'] as int);
                    AppData.backpackItems.add(item['name']);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} ተገዝቷል!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('በቂ ኮይን የለዎትም!')));
                  }
                },
                child: const Text('Buy'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 8. Invitation Screen
// ==========================================
class InvitationScreen extends StatelessWidget {
  const InvitationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitation Center')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.share, size: 70, color: Colors.pinkAccent),
            const SizedBox(height: 16),
            const Text('ጓደኞችህን ጋብዝ እና በነፃ ኮይን አሸንፍ!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('አዳዲስ ተጠቃሚዎችን ሲጋብዙ 20,000 ኮይን ሽልማት ያገኛሉ።', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('የግብዣ ኮድህ: ${AppData.userId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF00E676)),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('የግብዣ ኮድ ተቀድቷል!'))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 9. Backpack Screen
// ==========================================
class BackpackScreen extends StatelessWidget {
  const BackpackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Backpack')),
      body: AppData.backpackItems.isEmpty
          ? const Center(child: Text('ቦርሳህ ባዶ ነው! ከ Store ዕቃ ግዛ።', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: AppData.backpackItems.length,
              itemBuilder: (ctx, i) {
                return Card(
                  color: const Color(0xFF161A28),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Color(0xFF00E676)),
                    title: Text(AppData.backpackItems[i]),
                    trailing: const Text('Active', style: TextStyle(color: Color(0xFF00E676))),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// 10. Lucky Island Mini-Game
// ==========================================
class LuckyIslandScreen extends StatefulWidget {
  const LuckyIslandScreen({Key? key}) : super(key: key);

  @override
  State<LuckyIslandScreen> createState() => _LuckyIslandScreenState();
}

class _LuckyIslandScreenState extends State<LuckyIslandScreen> {
  int _lastWon = 0;

void _spinWheel() {
    if (AppData.coins < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ለመጫወት 100 ኮይን ያስፈልጋል!')));
      return;
    }
    setState(() {
      AppData.coins -= 100;
      List<int> rewards = [0, 50, 150, 300, 1000];
      _lastWon = rewards[Random().nextInt(rewards.length)];
      AppData.coins += _lastWon;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lucky Island Wheel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 20),
            Text('ቀሪ ኮይን: ${AppData.coins}', style: const TextStyle(fontSize: 18, color: Colors.amberAccent)),
            const SizedBox(height: 10),
            Text('ያሸነፉት: $_lastWon Coins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: _spinWheel,
              child: const Text('Spin (100 Coins)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 11. Level & Task Screen
// ==========================================
class LevelScreen extends StatelessWidget {
  const LevelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level & VIP Status')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('የአሁን ደረጃ: Lv. 24 Elite', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
            SizedBox(height: 10),
            LinearProgressIndicator(value: 0.75, backgroundColor: Colors.white12, color: Color(0xFF00E676)),
            SizedBox(height: 20),
            Text('ወደ Lv. 25 ለማደግ 2,500 EXP ያስፈልግዎታል!', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class TaskScreen extends StatelessWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Tasks')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: const [
          Card(
            color: Color(0xFF161A28),
            child: ListTile(
              leading: Icon(Icons.mic, color: Color(0xFF00E676)),
              title: Text('በድምፅ ክፍል 30 ደቂቃ ቆይ'),
              subtitle: Text('ሽልማት: 500 Coins'),
              trailing: Text('ተጠናቋል', style: TextStyle(color: Color(0xFF00E676))),
            ),
          ),
          Card(
            color: Color(0xFF161A28),
            child: ListTile(
              leading: Icon(Icons.card_giftcard, color: Colors.amber),
              title: Text('1 ስጦታ ላክ'),
              subtitle: Text('ሽልማት: 1,000 Coins'),
              trailing: Text('ያልተጠናቀቀ', style: TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 12. Badge Screen
// ==========================================
class BadgeScreen extends StatelessWidget {
  const BadgeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

appBar: AppBar(title: const Text('Badges & Achievements')),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        children: const [
          Column(children: [Icon(Icons.shield, size: 50, color: Colors.amber), Text('VIP Master')]),
          Column(children: [Icon(Icons.military_tech, size: 50, color: Colors.cyan), Text('Top Gifter')]),
          Column(children: [Icon(Icons.stars, size: 50, color: Colors.purple), Text('Room King')]),
        ],
      ),
    );
  }
}

// ==========================================
// 13. Host Center Screen
// ==========================================
class HostCenterScreen extends StatelessWidget {
  const HostCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host Center & Performance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('የወሩ የቀጥታ ስርጭት ሰዓት: 42 ሰዓት', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('የተሰበሰበ ነጥብ (Target Points): 23,903.91', style: TextStyle(color: Color(0xFF00E676))),
                SizedBox(height: 6),
                Text('የታርጌት ሁኔታ: Completed (ብቁ)', style: TextStyle(color: Colors.amber)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 14. Agency Management Screen
// ==========================================
class AgencyScreen extends StatelessWidget {
  const AgencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agency Management')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(12)),
            child: const Text('የኤጀንሲ ኮሚሽን ተመን: 20% Discount & Commission', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text('የተመዘገቡ ሆስቶች (Active Hosts)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...AppData.agencyHosts.map((h) => Card(
            color: const Color(0xFF161A28),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.teal),
              title: Text(h['name']),
              subtitle: Text('ID: ${h['id']} • ስርጭት: ${h['hours']}'),
              trailing: Text('${h['points']} Pts', style: const TextStyle(color: Colors.amber)),
            ),
          )),
        ],
      ),
    );
  }
}

// ==========================================
// 15. Support Screen
// ==========================================
class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Support Desk')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: const [
          ListTile(
            tileColor: Color(0xFF161A28),
            leading: Icon(Icons.headset_mic, color: Colors.indigoAccent),
            title: Text('24/7 የክፍያ እና የአካውንት ድጋፍ'),
            subtitle: Text('ከቴክኒክ ቡድኑ ጋር በቀጥታ ይነጋገሩ'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 16. About Screen
// ==========================================
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Hala Global')),
      body: const Center(
        child: Text('Hala Voice Global App\nVersion: 1.0.1+2\nAll Rights Reserved 2026', textAlign: TextAlign.center),
      ),
    );
  }
}

// ==========================================
// 17. Settings Screen
// ==========================================
class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Security')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const ListTile(
            tileColor: Color(0xFF161A28),
            leading: Icon(Icons.lock, color: Colors.amber),
            title: Text('የይለፍ ቃል ቀይር (Change Password)'),
          ),
          const SizedBox(height: 10),
          const ListTile(
            tileColor: Color(0xFF161A28),
            leading: Icon(Icons.security, color: Color(0xFF00E676)),
            title: Text('የአካውንት ደህንነት (Two-Factor Auth)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: const Text('ውጣ (Log Out)'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 18. Network Line Diagnostic
// ==========================================
class NetworkLineScreen extends StatelessWidget {
  const NetworkLineScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Diagnostic')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: const [
          Card(
            color: Color(0xFF161A28),
            child: ListTile(
              leading: Icon(Icons.network_wifi, color: Color(0xFF00E676)),
              title: Text('መስመር 1: Africa Server (Ethiopia)'),
              subtitle: Text('Ping: 42ms (እጅግ በጣም ፈጣን)'),
              trailing: Icon(Icons.check_circle, color: Color(0xFF00E676)),
            ),
          ),
          Card(
            color: Color(0xFF161A28),
            child: ListTile(
              leading: Icon(Icons.network_wifi, color: Colors.amber),
              title: Text('መስመር 2: Global Edge (Europe)'),
              subtitle: Text('Ping: 120ms (መካከለኛ)'),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 19. Recharge Screen (ID, Country, 20% Off, Epeay/USDT, Packages)
// ==========================================
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({Key? key}) : super(key: key);

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _idController = TextEditingController(text: AppData.userId);
  String _selectedCountry = 'All country';
  String _selectedPayment = 'USDT';
  int _selectedPackage = 0;

  final List<Map<String, dynamic>> _packages = [
    {'coins': 70000, 'price': 5},
    {'coins': 210000, 'price': 30},
    {'coins': 350000, 'price': 50},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharge Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),

children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00B0FF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '% official Agency Recharge 20% off',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          const Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 6),
          TextField(
            controller: _idController,
            decoration: InputDecoration(
              hintText: 'Enter ID',
              filled: true,
              fillColor: const Color(0xFF161A28),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Country / Region', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                dropdownColor: const Color(0xFF161A28),
                items: ['All country', 'Ethiopia 🇪🇹', 'Philippines 🇵🇭', 'Kenya 🇰🇪'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _selectedCountry = val!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recharge Gateway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              _payOption('Epeay'),
              const SizedBox(width: 12),
              _payOption('USDT'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Coin Packages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Column(
            children: List.generate(_packages.length, (i) {
              var p = _packages[i];
              bool isSel = _selectedPackage == i;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A28),
                  border: Border.all(color: isSel ? const Color(0xFF00E676) : Colors.transparent, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.monetization_on, color: Colors.amber),
                  title: Text('${p['coins']} Coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('\$${p['price']}', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () => setState(() => _selectedPackage = i),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              int added = _packages[_selectedPackage]['coins'];
              setState(() => AppData.coins += added);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ID ${_idController.text} ላይ $added Coins በተሳካ ሁኔታ ተሞልቷል!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _payOption(String name) {
    bool isSel = _selectedPayment == name;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPayment = name),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFF161A28),
            border: Border.all(color: isSel ? const Color(0xFF00E676) : Colors.white12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF00E676) : Colors.white)),
        ),
      ),
    );
  }
}
