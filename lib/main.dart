import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const HalaLiveGlobalApp());
}

class HalaLiveGlobalApp extends StatelessWidget {
  const HalaLiveGlobalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hala Voice Global',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0B18),
        primaryColor: const Color(0xFF00E676),
        fontFamily: 'sans-serif',
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// 1. Data Models & Global State Engine
// ==========================================
class UserProfile {
  String id;
  String name;
  String avatar;
  int coins;
  int diamonds;
  bool isHost;

  UserProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.coins,
    required this.diamonds,
    this.isHost = false,
  });
}

class AppState {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static const String currentChannel = "room_1042";

  // Current logged in user
  static UserProfile currentUser = UserProfile(
    id: "1042001",
    name: "KEDIR (Boss)",
    avatar: "👑",
    coins: 75000,
    diamonds: 180000,
    isHost: true,
  );

  // Agency Records
  static String agencyName = "Global Elite Star Agency";
  static String agencyCode = "GL-9002";
  static double totalEarningsUSD = 1845.50;

  static List<Map<String, dynamic>> agencyRoster = [
    {'name': 'Sara Live', 'id': '1042002', 'hours': '48.2 hrs', 'target': '92%', 'diamonds': '350,000 💎'},
    {'name': 'Alex Voice', 'id': '1042003', 'hours': '35.0 hrs', 'target': '75%', 'diamonds': '180,000 💎'},
    {'name': 'Sophia Music', 'id': '1042004', 'hours': '52.1 hrs', 'target': '100%', 'diamonds': '520,000 💎'},
  ];

  // Global Rooms
  static List<Map<String, dynamic>> activeRooms = [
    {
      'id': 'room_1042',
      'title': '🎉 Global Voice Party & Free Coins',
      'host': 'KEDIR (Boss)',
      'country': '🇺🇸 USA',
      'members': '5.2K',
    },
    {
      'id': 'room_1043',
      'title': '👑 VIP Diamonds & Lucky Wheel',
      'host': 'Sara Live',
      'country': '🇬🇧 UK',
      'members': '3.8K',
    },
    {
      'id': 'room_1044',
      'title': '🎵 Acoustic Night & Talents',
      'host': 'Alex Voice',
      'country': '🇦🇪 UAE',
      'members': '2.9K',
    },
  ];

  // International Gifts
  static final List<Map<String, dynamic>> giftStore = [
    {'name': 'Rose 🌹', 'price': 50, 'diamonds': 50},
    {'name': 'Heart 💖', 'price': 200, 'diamonds': 200},
    {'name': 'Ring 💍', 'price': 1000, 'diamonds': 1000},
    {'name': 'Sports Car 🏎️', 'price': 5000, 'diamonds': 5000},
    {'name': 'Yacht 🛥️', 'price': 15000, 'diamonds': 15000},
    {'name': 'Private Jet ✈️', 'price': 50000, 'diamonds': 5000},
  ];

  // International Payment Packages
  static final List<Map<String, dynamic>> globalPackages = [
    {'coins': 5000, 'priceUSD': 0.99, 'badge': 'Starter'},
    {'coins': 28000, 'priceUSD': 4.99, 'badge': 'Popular'},
    {'coins': 60000, 'priceUSD': 9.99, 'badge': 'Hot'},
    {'coins': 320000, 'priceUSD': 49.99, 'badge': 'VIP'},
    {'coins': 700000, 'priceUSD': 99.99, 'badge': 'Legend'},
  ];
}

// ==========================================
// 2. Splash Screen
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
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B18),
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
              child: const Icon(Icons.record_voice_over, size: 60, color: Colors.black),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hala Voice Global',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text('Connect • Speak • Earn', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. Auth Screen (Login / Guest Profile)
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Kedir Boss");

  void _proceedToApp() {
    if (_nameController.text.trim().isNotEmpty) {
      AppState.currentUser.name = _nameController.text.trim();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationHub()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B18),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.public, size: 80, color: Color(0xFF00E676)),
                const SizedBox(height: 16),
                const Text('Welcome to Hala Global', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Sign in with social account or continue as guest', style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 32),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nickname',
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF00E676)),
                    filled: true,
                    fillColor: const Color(0xFF1E1742),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.login, color: Colors.black),
                  label: const Text('Quick Login / Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: _proceedToApp,
                ),
                const SizedBox(height: 12),

OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.redAccent),
                  label: const Text('Sign in with Google'),
                  onPressed: _proceedToApp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. Main Navigation Hub
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
      const HalaPartyHomeScreen(),
      const AgencyManagementScreen(),
      GlobalWalletScreen(onUpdate: () => setState(() {})),
    ];

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: const Color(0xFF131124),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Party'),
          BottomNavigationBarItem(icon: Icon(Icons.corporate_fare_rounded), label: 'Agency'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet & Me'),
        ],
      ),
    );
  }
}

// ==========================================
// 5. Party Home Screen
// ==========================================
class HalaPartyHomeScreen extends StatelessWidget {
  const HalaPartyHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B18),
        elevation: 0,
        title: Row(
          children: const [
            Text('Trending', style: TextStyle(fontSize: 16, color: Colors.white54, fontWeight: FontWeight.bold)),
            SizedBox(width: 14),
            Text('Party', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1E1742), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${AppState.currentUser.coins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF00B0FF)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(

child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('INTERNATIONAL STAR LEAGUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                      SizedBox(height: 4),
                      Text('Top Agency Hosts Win 5,000 USD!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                const Icon(Icons.military_tech, size: 44, color: Colors.amberAccent),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Live Rooms Around the World', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ...AppState.activeRooms.map((r) => _buildRoomCard(context, r)).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text('Go Live', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveVoiceRoomScreen(
                roomId: AppState.currentChannel,
                roomTitle: 'My Global Party',
                hostName: AppState.currentUser.name,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, Map<String, dynamic> r) {
    return Card(
      color: const Color(0xFF181432),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
          child: const Icon(Icons.graphic_eq, color: Color(0xFF00E676)),
        ),
        title: Text(r['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Host: ${r['host']} • ${r['country']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
          child: const Text('Enter', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveVoiceRoomScreen(
                  roomId: r['id'],
                  roomTitle: r['title'],
                  hostName: r['host'],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// 6. Live Voice Room with Realtime Sound Waves & 8 Seats
// ==========================================
class LiveVoiceRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String hostName;

  const LiveVoiceRoomScreen({
    Key? key,
    required this.roomId,
    required this.roomTitle,
    required this.hostName,
  }) : super(key: key);

  @override
  State<LiveVoiceRoomScreen> createState() => _LiveVoiceRoomScreenState();
}

class _LiveVoiceRoomScreenState extends State<LiveVoiceRoomScreen> with SingleTickerProviderStateMixin {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMicOn = true;

  // Sound ripple animation controller
  late AnimationController _animController;

  // 8 Seat list (null = empty, string = name, 'LOCKED' = locked)
  List<String?> _seats = List.filled(8, null);
  int? _mySeatIndex;

  // In-room live chat
  final List<Map<String, String>> _messages = [];
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

@override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _initAgoraAudio();
    _messages.add({'user': 'System', 'text': 'Welcome to ${widget.roomTitle}!'});
    _messages.add({'user': 'System', 'text': 'Global room connected. Tap seat to take mic.'});
  }

  Future<void> _initAgoraAudio() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: AppState.agoraAppId,
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

    final int uid = Random().nextInt(899999) + 100000;
    await _engine!.joinChannel(
      token: '', // App ID Only
      channelId: widget.roomId,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _toggleMic() {
    setState(() => _isMicOn = !_isMicOn);
    _engine?.muteLocalAudioStream(!_isMicOn);
  }

  void _onSeatTapped(int index) {
    setState(() {
      if (_seats[index] == 'LOCKED') {
        _seats[index] = null;
        _pushSystemMsg('Seat #${index + 1} has been unlocked.');
      } else if (_seats[index] == null) {
        if (_mySeatIndex != null) _seats[_mySeatIndex!] = null;
        _seats[index] = AppState.currentUser.name;
        _mySeatIndex = index;
        _pushSystemMsg('${AppState.currentUser.name} hopped onto seat #${index + 1}');
      } else if (_seats[index] == AppState.currentUser.name) {
        _seats[index] = null;
        _mySeatIndex = null;
        _pushSystemMsg('${AppState.currentUser.name} stepped down.');
      } else {
        _seats[index] = 'LOCKED';
        _pushSystemMsg('Seat #${index + 1} locked by host.');
      }
    });
  }

  void _pushSystemMsg(String msg) {
    _messages.add({'user': 'System', 'text': msg});
    _scrollToBottom();
  }

  void _sendChat() {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'user': AppState.currentUser.name, 'text': _msgCtrl.text.trim()});
    });
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161228),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎁 Send Luxury Gift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Balance: ${AppState.currentUser.coins} 🪙', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                itemCount: AppState.giftStore.length,

gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (c, idx) {
                  final gift = AppState.giftStore[idx];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _executeSendGift(gift);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF221B40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(gift['name'].toString().split(' ')[1], style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text('${gift['price']} 🪙', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _executeSendGift(Map<String, dynamic> gift) {
    final cost = gift['price'] as int;
    final reward = gift['diamonds'] as int;

    if (AppState.currentUser.coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Insufficient coins! Please refill in wallet.')));
      return;
    }

    setState(() {
      AppState.currentUser.coins -= cost;
      AppState.currentUser.diamonds += reward;
      _messages.add({'user': '🎁 GIFT', 'text': '${AppState.currentUser.name} gifted ${gift['name']} to Host!'});
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _animController.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Channel: ${widget.roomId}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isJoined ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isJoined ? '🟢 LIVE' : '⏳ CONNECTING',
              style: TextStyle(color: _isJoined ? Colors.greenAccent : Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Host Area with Speaking Ripple Animation
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [

Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isMicOn)
                          Container(
                            width: 80 + (_animController.value * 12),
                            height: 80 + (_animController.value * 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E676).withOpacity(0.25 * (1 - _animController.value)),
                            ),
                          ),
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFF00E676),
                          child: CircleAvatar(
                            radius: 31,
                            backgroundColor: const Color(0xFF261D4C),
                            child: const Text('👑', style: TextStyle(fontSize: 30)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(widget.hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            },
          ),

          // 8-Seat Stage Grid
          SizedBox(
            height: 180,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, idx) {
                final occupant = _seats[idx];
                final isLocked = occupant == 'LOCKED';
                final isTaken = occupant != null && !isLocked;

                return InkWell(
                  onTap: () => _onSeatTapped(idx),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isTaken
                            ? const Color(0xFF00E676)
                            : isLocked
                                ? Colors.red.withOpacity(0.3)
                                : const Color(0xFF1E1742),
                        child: Icon(
                          isTaken
                              ? Icons.mic
                              : isLocked
                                  ? Icons.lock
                                  : Icons.add,
                          color: isTaken ? Colors.black : Colors.white60,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTaken ? occupant! : (isLocked ? 'Locked' : 'Seat ${idx + 1}'),
                        style: TextStyle(
                          color: isTaken ? const Color(0xFF00E676) : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Live In-Room Chat Stream
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ListView.builder(
                controller: _scrollCtrl,

itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final m = _messages[i];
                  final isSys = m['user'] == 'System' || m['user'] == '🎁 GIFT';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSys ? Colors.purple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${m['user']}: ',
                            style: TextStyle(
                              color: isSys ? Colors.amberAccent : const Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(text: m['text'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Controls & Messaging
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF140F2A),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off, color: _isMicOn ? const Color(0xFF00E676) : Colors.red),
                  onPressed: _toggleMic,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Say something friendly...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFF221B40),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendChat(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00E676), size: 20),
                  onPressed: _sendChat,
                ),
                IconButton(
                  icon: const Icon(Icons.card_giftcard, color: Colors.amberAccent, size: 26),
                  onPressed: _openGiftSheet,
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
// 7. Agency Management Screen (Hosts, Target, USD Commission)
// ==========================================
class AgencyManagementScreen extends StatefulWidget {
  const AgencyManagementScreen({Key? key}) : super(key: key);

  @override
  State<AgencyManagementScreen> createState() => _AgencyManagementScreenState();
}

class _AgencyManagementScreenState extends State<AgencyManagementScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _idCtrl = TextEditingController();

  void _showAddHostDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C163A),
        title: const Text('Register Global Host'),
        content: Column(

mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Host Name')),
            TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: 'Host ID (e.g. 1042005)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            onPressed: () {
              if (_nameCtrl.text.isNotEmpty && _idCtrl.text.isNotEmpty) {
                setState(() {
                  AppState.agencyRoster.add({
                    'name': _nameCtrl.text,
                    'id': _idCtrl.text,
                    'hours': '0.0 hrs',
                    'target': '0%',
                    'diamonds': '0 💎',
                  });
                });
                _nameCtrl.clear();
                _idCtrl.clear();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agency Headquarters'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF311B92), Color(0xFF6200EA)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppState.agencyName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                      child: Text(AppState.agencyCode, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Commission', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('\$${AppState.totalEarningsUSD.toStringAsFixed(2)} USD', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout requested via International Wire / USDT.')));
                      },
                      child: const Text('Withdraw USD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(

mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Agency Roster (${AppState.agencyRoster.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.person_add, color: Color(0xFF00E676)), onPressed: _showAddHostDialog),
            ],
          ),
          const SizedBox(height: 10),

          ...AppState.agencyRoster.map((h) {
            return Card(
              color: const Color(0xFF1A1438),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2C225A),
                  child: Text(h['name'][0], style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                ),
                title: Text(h['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('ID: ${h['id']} • Broadcast: ${h['hours']} • Target: ${h['target']}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                trailing: Text(h['diamonds'], style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ==========================================
// 8. Global Wallet Screen (Cards, PayPal, Apple/Google Pay in USD)
// ==========================================
class GlobalWalletScreen extends StatelessWidget {
  final VoidCallback onUpdate;
  const GlobalWalletScreen({Key? key, required this.onUpdate}) : super(key: key);

  void _processPayment(BuildContext context, int coins, double priceUSD) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161228),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pay \$$priceUSD USD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Receive $coins Coins instantly', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 18),

              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.cyanAccent),
                title: const Text('Credit / Debit Card (Stripe)'),
                onTap: () => _finalizeSuccess(context, ctx, coins),
              ),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.blueAccent),
                title: const Text('PayPal'),
                onTap: () => _finalizeSuccess(context, ctx, coins),
              ),
              ListTile(
                leading: const Icon(Icons.apple, color: Colors.white),
                title: const Text('Apple Pay / Google Play'),
                onTap: () => _finalizeSuccess(context, ctx, coins),
              ),
            ],
          ),
        );
      },
    );
  }

  void _finalizeSuccess(BuildContext context, BuildContext sheetCtx, int coins) {
    Navigator.pop(sheetCtx);
    AppState.currentUser.coins += coins;
    onUpdate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00E676),
        content: Text('🎉 Payment approved! Added $coins coins to your account.', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override

Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global Wallet & Profile'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF00E676),
                  child: Text(AppState.currentUser.avatar, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 8),
                Text(AppState.currentUser.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Global ID: ${AppState.currentUser.id}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF1E1742), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      const Text('Coins Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${AppState.currentUser.coins} 🪙', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF1E1742), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      const Text('Diamonds Vault', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${AppState.currentUser.diamonds} 💎', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('International Coin Refills (USD)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ...AppState.globalPackages.map((pkg) {
            return Card(
              color: const Color(0xFF181432),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.amberAccent),
                title: Text('${pkg['coins']} Coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('\$${pkg['priceUSD']} USD • Instant Delivery', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                  child: Text('Pay \$${pkg['priceUSD']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () => _processPayment(context, pkg['coins'], pkg['priceUSD']),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
