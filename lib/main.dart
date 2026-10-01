import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static String userId = "1000"; // Owner / Super Admin ID
  static const String ownerSecretPin = "1000"; // Secret Owner PIN Code
  
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

  static List<Map<String, dynamic>> systemUsers = [
    {'id': '1000', 'name': 'KEDIR ,,,, (Owner)', 'coins': 1500, 'isBanned': false},
    {'id': '1001', 'name': 'Abebe Host', 'coins': 5000, 'isBanned': false},
    {'id': '1002', 'name': 'Sara VIP', 'coins': 20000, 'isBanned': false},
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
// 4. Voice Room Screen (8 Seats)
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
// 5. Discover & Message Screens
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
        onTap: () {},
      ),
    );
  }
}

// ==========================================
// 6. Me Profile Screen with Secret 5-Tap Gesture & Admin PIN
// ==========================================
class MeProfileScreen extends StatefulWidget {
  const MeProfileScreen({Key? key}) : super(key: key);

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  int _secretTapCount = 0;
  Timer? _tapResetTimer;

  // Secret 5-Tap handler
  void _handleSecretAvatarTap() {
    // Only works if the active ID is 1000
    if (AppData.userId != "1000") return;

    _tapResetTimer?.cancel();
    _secretTapCount++;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _showSecretPinDialog();
    } else {
      _tapResetTimer = Timer(const Duration(seconds: 2), () {
        _secretTapCount = 0;
      });
    }
  }

  // Secret PIN Dialog
  void _showSecretPinDialog() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.security, color: Color(0xFF00E676)),
            SizedBox(width: 10),
            Text('Owner Verification', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your secret Master PIN to unlock the Owner Dashboard:', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,

keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Secret PIN',
                filled: true,
                fillColor: Color(0xFF0F121C),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            onPressed: () {
              if (pinController.text.trim() == AppData.ownerSecretPin) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuperOwnerAdminDashboard()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid PIN Code! Access Denied.')));
              }
            },
            child: const Text('Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = AppData.userId == "1000";

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        children: [
          Row(
            children: [
              // Secret 5-Tap Gesture on Avatar
              GestureDetector(
                onTap: _handleSecretAvatarTap,
                child: const CircleAvatar(radius: 35, backgroundColor: Colors.amber, child: Text('👑', style: TextStyle(fontSize: 32))),
              ),
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
                  child: Column(
                    children: [
                      const Text('Coins', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('${AppData.coins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    ],
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
              _gridMenu(context, Icons.store, 'Store', Colors.purpleAccent, const GenericDetailScreen(title: 'Store')),
              _gridMenu(context, Icons.card_giftcard, 'Invitation', Colors.pinkAccent, const GenericDetailScreen(title: 'Invitation')),
              _gridMenu(context, Icons.backpack, 'Backpack', Colors.cyan, const GenericDetailScreen(title: 'Backpack')),
              _gridMenu(context, Icons.casino, 'Games', Colors.green, const GenericDetailScreen(title: 'Games')),
              _gridMenu(context, Icons.star, 'Level', Colors.purple, const GenericDetailScreen(title: 'Level')),
              _gridMenu(context, Icons.task, 'Task', Colors.orange, const GenericDetailScreen(title: 'Task')),
              _gridMenu(context, Icons.shield, 'Badge', Colors.amberAccent, const GenericDetailScreen(title: 'Badge')),
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
                _gridMenu(context, Icons.mic_external_on, 'Host Center', Colors.lightBlue, const GenericDetailScreen(title: 'Host Center')),
                _gridMenu(context, Icons.business_center, 'Agency', Colors.teal, const GenericDetailScreen(title: 'Agency')),
                _gridMenu(context, Icons.monetization_on, 'Coin Seller', Colors.amber, const GenericDetailScreen(title: 'Coin Seller')),
                _gridMenu(context, Icons.info_outline, 'About Us', Colors.greenAccent, const GenericDetailScreen(title: 'About Us')),
                _gridMenu(context, Icons.settings, 'Setting', Colors.blueGrey, const GenericDetailScreen(title: 'Setting')),
                // Only visible to Owner ID 1000
                if (isOwner)
                  _gridMenu(context, Icons.admin_panel_settings, 'Owner Panel', Colors.redAccent, null, onTap: _showSecretPinDialog),
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
// 7. Hidden Master Owner / Admin Dashboard
// ==========================================
class SuperOwnerAdminDashboard extends StatefulWidget {
  const SuperOwnerAdminDashboard({Key? key}) : super(key: key);

@override
  State<SuperOwnerAdminDashboard> createState() => _SuperOwnerAdminDashboardState();
}

class _SuperOwnerAdminDashboardState extends State<SuperOwnerAdminDashboard> {
  final TextEditingController _mintAmountController = TextEditingController();
  final TextEditingController _targetUserIdController = TextEditingController();
  final TextEditingController _userCoinAmountController = TextEditingController();

  void _mintCoins() {
    int? amount = int.tryParse(_mintAmountController.text);
    if (amount != null && amount > 0) {
      setState(() {
        AppData.coins += amount;
      });
      _mintAmountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully minted $amount Coins into Owner Reserve!')));
    }
  }

  void _giveCoinsToUser() {
    String targetId = _targetUserIdController.text.trim();
    int? amount = int.tryParse(_userCoinAmountController.text);

    if (targetId.isNotEmpty && amount != null && amount > 0) {
      var user = AppData.systemUsers.firstWhere(
        (u) => u['id'] == targetId,
        orElse: () => {},
      );

      if (user.isNotEmpty) {
        setState(() {
          user['coins'] = (user['coins'] as int) + amount;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent $amount Coins to User $targetId!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target User ID not found.')));
      }
      _targetUserIdController.clear();
      _userCoinAmountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Owner Admin Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF161A28),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Owner Balance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFF880E4F)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👑 Master System Reserve', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${AppData.coins} Coins', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                const SizedBox(height: 6),
                Text('Admin / Owner ID: ${AppData.userId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 1. Direct Coin Mint Engine
          const Text('1. Coin Minting Engine (Generate New Coins)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mintAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter amount to mint',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),

onPressed: _mintCoins,
                  child: const Text('Mint Coins', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 2. Direct Credit/Debit to Any User
          const Text('2. Credit Coins to User Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                TextField(
                  controller: _targetUserIdController,
                  decoration: const InputDecoration(hintText: 'Target User ID (e.g. 1001)', border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _userCoinAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Coin Amount', border: InputBorder.none),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: _giveCoinsToUser,
                  child: const Text('Transfer to User', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 3. User & Host Moderator
          const Text('3. System Users & Hosts Registry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...AppData.systemUsers.map((u) => Card(
            color: const Color(0xFF161A28),
            child: ListTile(
              leading: Icon(Icons.person, color: u['id'] == '1000' ? Colors.amber : Colors.teal),
              title: Text(u['name']),
              subtitle: Text('ID: ${u['id']} • Balance: ${u['coins']} Coins'),
              trailing: u['id'] == '1000'
                  ? const Text('Owner', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
                  : IconButton(
                      icon: Icon(u['isBanned'] ? Icons.block : Icons.check_circle, color: u['isBanned'] ? Colors.red : Colors.green),
                      onPressed: () {
                        setState(() {
                          u['isBanned'] = !u['isBanned'];
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated status for User ${u['id']}')));
                      },
                    ),
            ),
          )),
        ],
      ),
    );
  }
}

// ==========================================
// 8. Recharge Screen (Step 1)
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
    {'coins': 70000, 'price': 10.00},
    {'coins': 210000, 'price': 30.00},
    {'coins': 350000, 'price': 50.00},
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
                      Text('\$${(p['price'] as double).toInt()}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
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
              var selectedPkg = _packages[_selectedPackage];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UsdtPaymentSelectScreen(
                    coins: selectedPkg['coins'],
                    usdAmount: selectedPkg['price'],
                  ),
                ),
              );
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
// 9. USDT Payment Select Screen
// ==========================================
class UsdtPaymentSelectScreen extends StatefulWidget {
  final int coins;
  final double usdAmount;
  const UsdtPaymentSelectScreen({Key? key, required this.coins, required this.usdAmount}) : super(key: key);

  @override
  State<UsdtPaymentSelectScreen> createState() => _UsdtPaymentSelectScreenState();
}

class _UsdtPaymentSelectScreenState extends State<UsdtPaymentSelectScreen> {
  String _selectedNetwork = 'USDT-TRC20';

  @override
  Widget build(BuildContext context) {
    double payAmount = widget.usdAmount + 0.02;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('TD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),

actions: const [
          Center(child: Padding(padding: EdgeInsets.only(right: 16), child: Text('English ∨', style: TextStyle(color: Colors.black54, fontSize: 14)))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 10),
                const Center(child: Text('Order Amount', style: TextStyle(color: Colors.black54, fontSize: 13))),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${widget.usdAmount.toStringAsFixed(2)} USD',
                    style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Payment Currency:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    Text('🟢 USDT ∨', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Recently Used', style: TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 8),
                _networkTile('USDT-TRC20'),
                const SizedBox(height: 16),
                const Text('DOK', style: TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 8),
                _networkTile('USDT-ERC20'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(24)),
                      child: const Text('More', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2962FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.verified_user, size: 18),
                        label: Text('Pay ${payAmount.toStringAsFixed(2)} USDT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UsdtQrCountdownScreen(
                                coins: widget.coins,
                                usdAmount: widget.usdAmount,
                                payAmount: payAmount,
                                network: _selectedNetwork,
                              ),
                            ),
                          );
                        },
                      ),

),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shield, color: Colors.black38, size: 16),
                    SizedBox(width: 4),
                    Text('PCI DSS COMPLIANT', style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkTile(String net) {
    bool isSel = _selectedNetwork == net;
    return GestureDetector(
      onTap: () => setState(() => _selectedNetwork = net),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isSel ? const Color(0xFF2962FF) : Colors.black12, width: isSel ? 1.5 : 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(isSel ? Icons.check_circle : Icons.radio_button_unchecked, color: isSel ? const Color(0xFF2962FF) : Colors.black26),
            const SizedBox(width: 12),
            Text(net, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFEDF2FF), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.link, size: 16, color: Color(0xFF2962FF)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 10. USDT QR Countdown Screen
// ==========================================
class UsdtQrCountdownScreen extends StatefulWidget {
  final int coins;
  final double usdAmount;
  final double payAmount;
  final String network;
  const UsdtQrCountdownScreen({
    Key? key,
    required this.coins,
    required this.usdAmount,
    required this.payAmount,
    required this.network,
  }) : super(key: key);

  @override
  State<UsdtQrCountdownScreen> createState() => _UsdtQrCountdownScreenState();
}

class _UsdtQrCountdownScreenState extends State<UsdtQrCountdownScreen> {
  late Timer _timer;
  int _secondsLeft = 7112;
  final String _depositAddress = "TKD9APJ2F3eVX3bZ8HDWz63ZaPiH5Lfeah";
  final String _orderNumber = "2026100115143194617539259268";

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSecs) {
    int h = totalSecs ~/ 3600;
    int m = (totalSecs % 3600) ~/ 60;
    int s = totalSecs % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied to clipboard!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('TD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),

actions: const [
          Center(child: Padding(padding: EdgeInsets.only(right: 16), child: Text('English ∨', style: TextStyle(color: Colors.black54, fontSize: 14)))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                      itemCount: 36,
                      itemBuilder: (ctx, i) => Container(
                        margin: const EdgeInsets.all(1.5),
                        color: (i % 2 == 0 || i % 5 == 0) ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFF009688), shape: BoxShape.circle),
                    child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFFF9C4), borderRadius: BorderRadius.circular(16)),
              child: Text(
                'Remaining Payment Time ${_formatTimer(_secondsLeft)}',
                style: const TextStyle(color: Color(0xFFF57F17), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment amount', style: TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 2),
                Text('${widget.payAmount.toStringAsFixed(2)} USDT', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                const Text('Network', style: TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(widget.network, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                const Text('TRON (TRC20)', style: TextStyle(color: Colors.black38, fontSize: 11)),
                const Divider(height: 20),
                const Text('Deposit Address', style: TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _depositAddress,
                        style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),

overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Colors.black45),
                      onPressed: () => _copy(_depositAddress, 'Deposit Address'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Merchant Order Number', style: TextStyle(color: Colors.black54, fontSize: 12)),
              Row(
                children: [
                  Text(_orderNumber.substring(0, 14), style: const TextStyle(color: Colors.black87, fontSize: 11)),
                  IconButton(icon: const Icon(Icons.copy, size: 16, color: Colors.black45), onPressed: () => _copy(_orderNumber, 'Order Number')),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Amount', style: TextStyle(color: Colors.black54, fontSize: 12)),
              Text('${widget.usdAmount.toStringAsFixed(2)} USD', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                AppData.coins += widget.coins;
              });
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF161A28),
                  title: const Text('Payment Confirmed!'),
                  content: Text('Successfully credited ${widget.coins} Coins to Account ID ${AppData.userId}.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('OK', style: TextStyle(color: Color(0xFF00E676))),
                    ),
                  ],
                ),
              );
            },
            child: const Text('I Have Completed Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 11. Generic Detail Screen
// ==========================================
class GenericDetailScreen extends StatelessWidget {
  final String title;
  const GenericDetailScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title Screen Loaded', style: const TextStyle(color: Colors.white54)),
      ),
    );
  }
}
