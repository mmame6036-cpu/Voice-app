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
  static String userName = "KEDIR ,,,,";
  static String userId = "1000"; // Changed starting ID to 1000
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
      'title': 'Global Voice Party & Lucky Room',
      'host': 'KEDIR ,,,,',
      'category': 'FRIENDS',
      'type': 'Public',
      'users': '4.58k',
      'country': 'Ethiopia 🇪🇹',
    },
    {
      'id': 'room_1043',
      'title': 'VIP Diamond Audio Center',
      'host': 'Selam Live',
      'category': 'EMOTION',
      'type': 'Public',
      'users': '2.34k',
      'country': 'Philippines 🇵🇭',
    },
  ];

  static List<Map<String, String>> supportMessages = [
    {'sender': 'Support', 'text': 'Hello Kedir! How can we assist you today?'},
  ];
  static List<Map<String, String>> systemMessages = [
    {'title': 'Security Verification', 'time': '10:45 AM', 'desc': 'Your account has been securely verified.'},
    {'title': 'Coin Generation Complete', 'time': 'Yesterday', 'desc': 'Admin coins added to the master ledger.'},
  ];
  static List<Map<String, String>> orderMessages = [
    {'title': 'Coin Purchase #8921', 'time': '09:12 AM', 'desc': '70,000 Coins via USDT - Success'},
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
            const SizedBox(height: 8),
            const Text('v3.7.7 Online', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
// 4. Voice Room Screen (8 Interactive Seats with Animations)
// ==========================================
class VoiceRoomScreen extends StatefulWidget {
  final String roomId;
  final String title;
  const VoiceRoomScreen({Key? key, required this.roomId, required this.title}) : super(key: key);

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> with SingleTickerProviderStateMixin {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMicMuted = false;
  int? _myCurrentSeat;

  late List<String?> _seats;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _seats = List.filled(8, null);
    _seats[0] = AppData.userName;
    _myCurrentSeat = 0;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

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

  void _onSeatTapped(int index) {
    setState(() {
      if (_seats[index] == AppData.userName) {
        _seats[index] = null;
        _myCurrentSeat = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left the seat')));
      } else if (_seats[index] == null) {
        if (_myCurrentSeat != null) {
          _seats[_myCurrentSeat!] = null;
        }
        _seats[index] = AppData.userName;
        _myCurrentSeat = index;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seated on Seat ${index + 1}!')));
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
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
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                String? occupant = _seats[index];
                bool isMe = occupant == AppData.userName;
                bool isSpeaking = isMe && !_isMicMuted;

                return GestureDetector(
                  onTap: () => _onSeatTapped(index),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          double scale = isSpeaking ? (1.0 + (_animController.value * 0.15)) : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSpeaking
                                      ? const Color(0xFF00E676)
                                      : (occupant != null ? Colors.amber : Colors.transparent),
                                  width: isSpeaking ? 3 : 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: occupant != null ? const Color(0xFF1E2433) : const Color(0xFF141824),
                                child: occupant != null
                                    ? (isMe ? const Text('👑', style: TextStyle(fontSize: 22)) : const Icon(Icons.person, color: Colors.white70))
                                    : const Icon(Icons.event_seat, color: Colors.white24),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        occupant ?? 'Seat ${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: occupant != null ? Colors.amber : Colors.white54,
                          fontWeight: occupant != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
// 5. Discover Screen
// ==========================================
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: const Center(child: Text('Moments and Posts', style: TextStyle(color: Colors.white54))),
    );
  }
}

// ==========================================
// 6. Message Hub Screen
// ==========================================
class MessageHubScreen extends StatelessWidget {
  const MessageHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Center'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _menuTile(context, Icons.notifications_active, 'System Message', 'System and account alerts', Colors.cyan),
          const SizedBox(height: 10),
          _menuTile(context, Icons.receipt_long, 'Order Messages', 'Coin purchases and ledger details', Colors.amber),
          const SizedBox(height: 10),
          _menuTile(context, Icons.headset_mic, 'Customer Service', '24/7 Official Support Chat', const Color(0xFF00E676)),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Card(
      color: const Color(0xFF161A28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opened $title')));
        },
      ),
    );
  }
}

// ==========================================
// 7. Me Profile Screen (All 11 Image Features Integrated)
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
            const Text('Enter coin amount to mint into the system:', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Amount (e.g. 100000)',
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully minted $val Coins!')));
              }
            },
            child: const Text('Generate'),
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
                    Text('ID: ${AppData.userId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                        const Text('Coins (Tap to Mint)', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
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
          // User Grid Functions (Recharge, Store, Invitation, Backpack, Games, Level, Task, Badge)
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

_gridMenu(context, Icons.casino, 'Games', Colors.green, const GamesScreen()),
              _gridMenu(context, Icons.star, 'Level', Colors.purple, const LevelScreen()),
              _gridMenu(context, Icons.task, 'Task', Colors.orange, const TaskScreen()),
              _gridMenu(context, Icons.shield, 'Badge', Colors.amberAccent, const BadgeWallScreen()),
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
                _gridMenu(context, Icons.business_center, 'Agency', Colors.teal, const AgencyCenterScreen()),
                _gridMenu(context, Icons.monetization_on, 'Coin Seller', Colors.amber, const CoinSellerScreen()),
                _gridMenu(context, Icons.precision_manufacturing, 'Coin Engine', Colors.greenAccent, null, onTap: _openAdminCoinEngine),
                _gridMenu(context, Icons.info_outline, 'About Us', Colors.greenAccent, const AboutUsScreen()),
                _gridMenu(context, Icons.settings, 'Setting', Colors.blueGrey, const SettingScreen()),
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
// 8. Recharge Screen (Matching Image 1000013440)
// ==========================================
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({Key? key}) : super(key: key);

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _idController = TextEditingController(text: AppData.userId);
  String _selectedCountry = 'All country';
  String _selectedPayment = 'Epay';
  int _selectedPackage = 0;

  final List<Map<String, dynamic>> _packages = [
    {'coins': 70000, 'price': 10},
    {'coins': 210000, 'price': 30},
    {'coins': 350000, 'price': 50},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Recharge', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),

),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('User ID', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _idController, style: const TextStyle(color: Colors.black), decoration: const InputDecoration(border: InputBorder.none))),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Confirmed'))),
                  child: const Text('Confirm', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Country/Region', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                items: ['All country', 'Ethiopia', 'Philippines', 'Kenya'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _selectedCountry = val!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: const [
                Icon(Icons.percent, color: Colors.deepOrange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Official Agency Recharge', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
                Text('20% off >', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recharge', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              _payTab('Epay', Icons.payment, Colors.blue),
              const SizedBox(width: 12),
              _payTab('USDT', Icons.currency_bitcoin, Colors.teal),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_packages.length, (i) {
              var p = _packages[i];
              bool isSel = _selectedPackage == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedPackage = i),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 56) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: isSel ? const Color(0xFF00E676) : Colors.black12, width: 1.5),

borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                      const SizedBox(height: 8),
                      Text('${p['coins']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('\$${p['price']}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              int added = _packages[_selectedPackage]['coins'];
              setState(() => AppData.coins += added);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully recharged $added Coins!')));
              Navigator.pop(context);
            },
            child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _payTab(String name, IconData icon, Color col) {
    bool isSel = _selectedPayment == name;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPayment = name),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: isSel ? const Color(0xFF00E676) : Colors.black12, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: col, size: 24),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 9. Store Screen (Matching Image 1000013442)
// ==========================================
class StoreScreen extends StatelessWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'name': 'Shark Moto', 'price': 300000, 'type': 'Vehicle'},
      {'name': 'Ice-Fire Soul', 'price': 400000, 'type': 'Beast'},
      {'name': 'Star of Fortune', 'price': 30000, 'type': 'Frame'},
      {'name': 'Lucky Bless', 'price': 30000, 'type': 'Frame'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Store', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _StoreCategory(icon: Icons.whatshot, label: 'Popular', col: Colors.red),
              _StoreCategory(icon: Icons.filter_frames, label: 'Frame', col: Colors.cyan),
              _StoreCategory(icon: Icons.flight_takeoff, label: 'Entry', col: Colors.orange),
              _StoreCategory(icon: Icons.badge, label: 'Special ID', col: Colors.amber),

],
          ),
          const SizedBox(height: 16),
          const Text('New This Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (ctx, i) {
              var it = items[i];
              return Container(
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, size: 55, color: Colors.purpleAccent),
                    const SizedBox(height: 8),
                    Text(it['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('${it['price']} Coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StoreCategory extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color col;
  const _StoreCategory({required this.icon, required this.label, required this.col});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 20, backgroundColor: col.withOpacity(0.15), child: Icon(icon, color: col, size: 20)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
      ],
    );
  }
}

// ==========================================
// 10. Backpack Screen (Matching Image 1000013446)
// ==========================================
class BackpackScreen extends StatelessWidget {
  const BackpackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> frames = ['Meowlet', 'MerryChristmas', 'Anniv. Gallery', 'Anniv. Frame', 'Halloween Party', 'VIP1'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Backpack', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Frame', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
              Text('Entry', style: TextStyle(color: Colors.black54)),
              Text('Special ID', style: TextStyle(color: Colors.black54)),
              Text('Theme', style: TextStyle(color: Colors.black54)),
              Text('Room Card', style: TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: frames.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,

childAspectRatio: 0.85,
              ),
              itemBuilder: (ctx, i) {
                return Container(
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Icon(Icons.pets, color: Colors.pinkAccent)),
                      const SizedBox(height: 8),
                      Text(frames[i], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      const Text('Expired', style: TextStyle(color: Colors.orange, fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 11. Invitation Screen (Matching Image 1000013444)
// ==========================================
class InvitationScreen extends StatelessWidget {
  const InvitationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hala Center', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.redAccent, Colors.orangeAccent]), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: const [
                  Text('INVITE FRIENDS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 6),
                  Text('Generous Game Reward', style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Invitation Code: ${AppData.userId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(width: 8),
                  const Text('Copy', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 48)),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent!'))),
              child: const Text('Invitation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 12. Games Screen (Matching Image 1000013448)
// ==========================================
class GamesScreen extends StatelessWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> games = ['Ocean Hunt', 'Jungle Hunt', 'Royal Battle', 'Fruit Party', 'JungleDelight', 'GaroGemsII'];

return Scaffold(
      backgroundColor: const Color(0xFF062B22),
      appBar: AppBar(
        title: const Text('Games', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _GameTopItem(icon: Icons.inventory_2, label: 'Chest'),
              _GameTopItem(icon: Icons.emoji_events, label: 'Ranking'),
              _GameTopItem(icon: Icons.verified, label: 'G-VIP'),
              _GameTopItem(icon: Icons.storefront, label: 'Store'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Games', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (ctx, i) {
              return Container(
                decoration: BoxDecoration(color: const Color(0xFF0F4A3C), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_esports, size: 40, color: Colors.amber),
                    const SizedBox(height: 6),
                    Text(games[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GameTopItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GameTopItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

// ==========================================
// 13. Level Screen (Matching Image 1000013450)
// ==========================================
class LevelScreen extends StatelessWidget {
  const LevelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B241C),
      appBar: AppBar(title: const Text('Wealth & Charm'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF143D31), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Lv.18', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text('Current Wealth Value: 2287851', style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 8),
                LinearProgressIndicator(value: 0.6, color: Color(0xFF00E676), backgroundColor: Colors.white12),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Level Privileges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

const SizedBox(height: 12),
          _privilegeCard('Lv.5', 'Room Red Packet', 'Can be sent after reaching Level 5'),
          _privilegeCard('Lv.10', 'Visible in Audio Room', 'Hide your information in the Audio room'),
          _privilegeCard('Lv.20', 'Visible in Audio Room', 'Customized tag visible to audience'),
        ],
      ),
    );
  }

  Widget _privilegeCard(String lvl, String title, String subtitle) {
    return Card(
      color: const Color(0xFF143D31),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.white12, child: Text(lvl, style: const TextStyle(color: Color(0xFF00E676), fontSize: 12))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ),
    );
  }
}

// ==========================================
// 14. Task Center (Matching Image 1000013452)
// ==========================================
class TaskScreen extends StatelessWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Task Center', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _taskEarning('Today\'s Task Earnings', '0'),
                _taskEarning('This Week\'s Task Earnings', '0'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _taskItem('Stay in a Room for 5 Minutes', '(5/5)', 'Done', true),
          _taskItem('Follow 5 Hosts', '(4/5)', 'Go', false),
          _taskItem('Recharge Once', '(1/1)', 'Done', true),
        ],
      ),
    );
  }

  Widget _taskEarning(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _taskItem(String title, String count, String btnLabel, bool isDone) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(count, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDone ? Colors.grey[200] : const Color(0xFF00E676),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(btnLabel, style: TextStyle(color: isDone ? Colors.black45 : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}

// ==========================================
// 15. Badge Wall (Matching Image 1000013454)
// ==========================================
class BadgeWallScreen extends StatelessWidget {
  const BadgeWallScreen({Key? key}) : super(key: key);

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1326),
      appBar: AppBar(title: const Text('Badge Wall'), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(radius: 35, backgroundColor: Colors.amber, child: Text('👑', style: TextStyle(fontSize: 30))),
            const SizedBox(height: 8),
            Text(AppData.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Total Badge Collected: 0', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFF261D38), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Column(
                  children: [
                    const Text('MY BADGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 4,
                        children: List.generate(8, (i) => Container(margin: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 16. Host Center (Matching Image 1000013456)
// ==========================================
class HostCenterScreen extends StatelessWidget {
  const HostCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Host Center', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 25, backgroundColor: Colors.amber, child: Text('👑')),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppData.userName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('ID: ${AppData.userId}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _HostStat(title: 'Gift Income', val: '0'),
                _HostStat(title: 'Hourly Income', val: '0 /h'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Points Overview', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
          const SizedBox(height: 10),

Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Total Income: 1.61', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                Text('Consume: 0', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HostStat extends StatelessWidget {
  final String title;
  final String val;
  const _HostStat({required this.title, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}

// ==========================================
// 17. Agency Center (Matching Image 1000013458)
// ==========================================
class AgencyCenterScreen extends StatelessWidget {
  const AgencyCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Agency Center', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent[700], foregroundColor: Colors.white),
                  onPressed: () {},
                  child: const Text('Invite Host'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  onPressed: () {},
                  child: const Text('Invite Agency'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Total Host Points: 187,929.6', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Commission Rate: 4%', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _agencyCard('Host Number', '304'),
              const SizedBox(width: 12),
              _agencyCard('Sub-agency Number', '45'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _agencyCard(String title, String count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

children: [
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11)),
            const SizedBox(height: 6),
            Text(count, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 18. Coin Seller Screen (Matching Image 1000013460)
// ==========================================
class CoinSellerScreen extends StatelessWidget {
  const CoinSellerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Coin Seller', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 25, backgroundColor: Colors.amber, child: Text('👑')),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppData.userName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('ID: ${AppData.userId}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const Text('Current level: Beginner Seller', style: TextStyle(color: Colors.black54, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFFF9C4), borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Balance', style: TextStyle(color: Colors.black54)),
                    Text('${AppData.coins}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  onPressed: () {},
                  child: const Text('Details'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _SellerAction(icon: Icons.send, label: 'Transfer'),
              _SellerAction(icon: Icons.account_balance_wallet, label: 'Recharge'),
              _SellerAction(icon: Icons.swap_horiz, label: 'Exchange'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SellerAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 24, backgroundColor: Colors.teal[50], child: Icon(icon, color: Colors.teal)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

// ==========================================
// 19. Setting Screen (Matching Image 1000013464)
// ==========================================
class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Setting', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingItem('Account Manager'),
          _settingItem('Message Settings'),
          _settingItem('Language Setting'),
          _settingItem('Network Line'),
          const SizedBox(height: 14),
          _settingItem('Privilege settings'),
          _settingItem('Blocked Users'),
          const SizedBox(height: 14),
          _settingItem('Clear Cache', trailing: '330.50MB'),
          _settingItem('About Us', trailing: 'v3.7.7', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen()))),
          _settingItem('Delete Account'),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, elevation: 0.5),
            onPressed: () => Navigator.pop(context),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _settingItem(String title, {String? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.black45, fontSize: 12)),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ==========================================
// 20. About Us Screen (Matching Image 1000013462)
// ==========================================
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(16)),
                  child: const Text('Hala', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                const Text('Hala V3.7.7', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _aboutItem('Privacy Policy'),
          _aboutItem('User Service Terms'),
          _aboutItem('Streaming Protocol'),
          _aboutItem('Child Safety Policy'),
          _aboutItem('User Recharge Agreement'),
        ],
      ),
    );
  }

Widget _aboutItem(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
      ),
    );
  }
}
