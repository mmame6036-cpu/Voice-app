import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const HalaFullVoiceApp());
}

class HalaFullVoiceApp extends StatelessWidget {
  const HalaFullVoiceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hala Voice',
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
// 1. AppData
// ==========================================
class AppData {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static const String currentChannel = "room_1042";

  // User State
  static int userCoins = 85000;
  static int userDiamonds = 145000;
  static String currentUserName = "KEDIR (Host)";
  static String currentUserId = "1042001";

  // Agency Data
  static String agencyName = "Golden Star Agency";
  static String agencyCode = "AG-8821";
  static double totalCommission = 420.50;
  static List<Map<String, dynamic>> agencyHosts = [
    {'name': 'Sara Live', 'id': '1042002', 'hours': '34.5 hrs', 'target': '85%', 'earnings': '125,000 💎'},
    {'name': 'Alex Voice', 'id': '1042003', 'hours': '28.0 hrs', 'target': '60%', 'earnings': '78,000 💎'},
    {'name': 'Elena Star', 'id': '1042004', 'hours': '41.2 hrs', 'target': '100%', 'earnings': '210,000 💎'},
  ];

  // Rooms
  static List<Map<String, dynamic>> rooms = [
    {
      'id': 'room_1042',
      'title': '🎉 Welcome Party & Free Coins',
      'category': 'FRIENDS',
      'host': 'KEDIR',
      'usersCount': '4.58K',
    },
    {
      'id': 'room_1043',
      'title': '🐟 Fish & Game Champions Room',
      'category': 'GAME',
      'host': 'Sara Live',
      'usersCount': '3.21K',
    },
    {
      'id': 'room_1044',
      'title': '🎵 Night Music & Chatting',
      'category': 'MUSIC',
      'host': 'Alex Voice',
      'usersCount': '2.23K',
    },
  ];

  // Gifts
  static final List<Map<String, dynamic>> availableGifts = [
    {'name': 'Rose 🌹', 'price': 50, 'diamonds': 50},
    {'name': 'Coffee ☕', 'price': 200, 'diamonds': 200},
    {'name': 'Heart 💖', 'price': 500, 'diamonds': 500},
    {'name': 'Sports Car 🏎️️', 'price': 2500, 'diamonds': 2500},
    {'name': 'Royal Crown 👑', 'price': 10000, 'diamonds': 10000},
    {'name': 'Space Rocket 🚀', 'price': 25000, 'diamonds': 25000},
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
          MaterialPageRoute(builder: (_) => const MainNavigationHub()),
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
              'Hala Voice',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text('Show Me Happy the World', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. Main Navigation Hub
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
      ProfileWalletScreen(onRefresh: () => setState(() {})),
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
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Party'),
          BottomNavigationBarItem(icon: Icon(Icons.business_center_rounded), label: 'Agency'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Me'),
        ],
      ),
    );
  }
}

// ==========================================
// 4. Party Home Screen
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
            Text('Follow', style: TextStyle(fontSize: 16, color: Colors.white54, fontWeight: FontWeight.bold)),
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
                Text('${AppData.userCoins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF00B0FF)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('URGENT SECURITY & EVENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),

SizedBox(height: 4),
                      Text('Room Ranking & Live Rewards!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                const Icon(Icons.military_tech, size: 42, color: Colors.amberAccent),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Active Voice Rooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ...AppData.rooms.map((r) => _buildRoomTile(context, r)).toList(),
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
              builder: (_) => LiveHalaFullVoiceRoom(
                roomId: AppData.currentChannel,
                title: 'My Live Party',
                hostName: AppData.currentUserName,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomTile(BuildContext context, Map<String, dynamic> r) {
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
        subtitle: Text('Host: ${r['host']} • ${r['category']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
          child: const Text('Join', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveHalaFullVoiceRoom(
                  roomId: r['id'],
                  title: r['title'],
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
// 5. Live Voice Room (8 Seats + Chat + Gifts)
// ==========================================
class LiveHalaFullVoiceRoom extends StatefulWidget {
  final String roomId;
  final String title;
  final String hostName;

  const LiveHalaFullVoiceRoom({
    Key? key,
    required this.roomId,
    required this.title,
    required this.hostName,
  }) : super(key: key);

  @override
  State<LiveHalaFullVoiceRoom> createState() => _LiveHalaFullVoiceRoomState();
}

class _LiveHalaFullVoiceRoomState extends State<LiveHalaFullVoiceRoom> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMicOn = true;

  List<String?> _seats = List.filled(8, null);
  int? _myCurrentSeat;

  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAgora();
    _chatMessages.add({'user': 'System', 'msg': 'Welcome to ${widget.title}!'});
    _chatMessages.add({'user': 'System', 'msg': 'Send gifts or tap a seat to speak.'});
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

    final int myUid = Random().nextInt(900000) + 100000;

    await _engine!.joinChannel(
      token: '', // App ID Only
      channelId: widget.roomId,
      uid: myUid,
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

  void _handleSeatTap(int index) {
    setState(() {
      if (_seats[index] == 'LOCKED') {
        _seats[index] = null;
        _addChatMessage('System', 'Seat #${index + 1} unlocked');
      } else if (_seats[index] == null) {
        if (_myCurrentSeat != null) {
          _seats[_myCurrentSeat!] = null;
        }
        _seats[index] = AppData.currentUserName;
        _myCurrentSeat = index;
        _addChatMessage('System', '${AppData.currentUserName} joined Seat #${index + 1}');
      } else if (_seats[index] == AppData.currentUserName) {
        _seats[index] = null;
        _myCurrentSeat = null;
        _addChatMessage('System', '${AppData.currentUserName} left the seat');
      } else {
        _seats[index] = 'LOCKED';
        _addChatMessage('System', 'Seat #${index + 1} locked');
      }
    });
  }

  void _addChatMessage(String sender, String text) {
    setState(() {
      _chatMessages.add({'user': sender, 'msg': text});
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScroll.hasClients) {
        _chatScroll.jumpTo(_chatScroll.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    _addChatMessage(AppData.currentUserName, _msgController.text.trim());
    _msgController.clear();
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
                  const Text('🎁 Send Gift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Balance: ${AppData.userCoins} 🪙', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                itemCount: AppData.availableGifts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (c, idx) {
                  final gift = AppData.availableGifts[idx];
                  return InkWell(
                    onTap: () {

Navigator.pop(ctx);
                      _sendGift(gift);
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

  void _sendGift(Map<String, dynamic> gift) {
    if (AppData.userCoins < (gift['price'] as int)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Not enough coins! Please top up.')));
      return;
    }

    setState(() {
      AppData.userCoins -= (gift['price'] as int);
      AppData.userDiamonds += (gift['diamonds'] as int);
      _addChatMessage('🎁 Gift', '${AppData.currentUserName} sent ${gift['name']} to Host!');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00E676),
        content: Text('🎉 ${gift['name']} sent successfully!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _msgController.dispose();
    _chatScroll.dispose();
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
            Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Room ID: ${widget.roomId}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
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
              _isJoined ? '🟢 LIVE' : '⏳ Connecting...',
              style: TextStyle(color: _isJoined ? Colors.greenAccent : Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Host Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF00E676),
                      child: CircleAvatar(
                        radius: 29,
                        backgroundColor: const Color(0xFF261D4C),
                        child: const Icon(Icons.person, size: 34, color: Colors.white),

),
                    ),
                    const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.star, size: 12, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),

          // 8 Seat Grid
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
                final seatStatus = _seats[idx];
                final isLocked = seatStatus == 'LOCKED';
                final isOccupied = seatStatus != null && !isLocked;

                return InkWell(
                  onTap: () => _handleSeatTap(idx),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isOccupied
                            ? const Color(0xFF00E676)
                            : isLocked
                                ? Colors.red.withOpacity(0.3)
                                : const Color(0xFF1E1742),
                        child: Icon(
                          isOccupied
                              ? Icons.mic
                              : isLocked
                                  ? Icons.lock
                                  : Icons.add,
                          color: isOccupied ? Colors.black : Colors.white60,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOccupied ? seatStatus! : (isLocked ? 'Locked' : '${idx + 1}'),
                        style: TextStyle(
                          color: isOccupied ? const Color(0xFF00E676) : Colors.white54,
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

          // Chat Messages
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ListView.builder(
                controller: _chatScroll,
                itemCount: _chatMessages.length,
                itemBuilder: (ctx, i) {
                  final msg = _chatMessages[i];
                  final isSystem = msg['user'] == 'System' || msg['user'] == '🎁 Gift';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSystem ? Colors.purple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(

text: '${msg['user']}: ',
                            style: TextStyle(
                              color: isSystem ? Colors.amberAccent : const Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: msg['msg'],
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Bar
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
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFF221B40),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00E676), size: 20),
                  onPressed: _sendMessage,
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
// 6. Agency Management Screen
// ==========================================
class AgencyManagementScreen extends StatefulWidget {
  const AgencyManagementScreen({Key? key}) : super(key: key);

  @override
  State<AgencyManagementScreen> createState() => _AgencyManagementScreenState();
}

class _AgencyManagementScreenState extends State<AgencyManagementScreen> {
  final TextEditingController _hostIdCtrl = TextEditingController();
  final TextEditingController _hostNameCtrl = TextEditingController();

  void _addNewHost() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C163A),
        title: const Text('Add New Host'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _hostNameCtrl, decoration: const InputDecoration(labelText: 'Host Name')),
            TextField(controller: _hostIdCtrl, decoration: const InputDecoration(labelText: 'Host ID')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            onPressed: () {
              if (_hostNameCtrl.text.isNotEmpty && _hostIdCtrl.text.isNotEmpty) {
                setState(() {
                  AppData.agencyHosts.add({
                    'name': _hostNameCtrl.text,

'id': _hostIdCtrl.text,
                    'hours': '0.0 hrs',
                    'target': '0%',
                    'earnings': '0 💎',
                  });
                });
                _hostNameCtrl.clear();
                _hostIdCtrl.clear();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Register', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                    Text(AppData.agencyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                      child: Text(AppData.agencyCode, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Commission', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('\$${AppData.totalCommission}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!')));
                      },
                      child: const Text('Withdraw', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
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
              Text('Agency Hosts (${AppData.agencyHosts.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.person_add, color: Color(0xFF00E676)), onPressed: _addNewHost),
            ],
          ),
          const SizedBox(height: 10),

          ...AppData.agencyHosts.map((h) {
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
                subtitle: Text('ID: ${h['id']} • Time: ${h['hours']} • Target: ${h['target']}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                trailing: Text(h['earnings'], style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ==========================================
// 7. Profile & Wallet Screen (Me)
// ==========================================
class ProfileWalletScreen extends StatelessWidget {
  final VoidCallback onRefresh;
  const ProfileWalletScreen({Key? key, required this.onRefresh}) : super(key: key);

  void _buyCoins(BuildContext context, int coins, int priceBirr) {
    AppData.userCoins += coins;
    onRefresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00E676),
        content: Text('🎉 $coins coins successfully added!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Wallet'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(radius: 36, backgroundColor: Color(0xFF00E676), child: Icon(Icons.person, size: 40, color: Colors.black)),
                const SizedBox(height: 8),
                Text(AppData.currentUserName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('ID: ${AppData.currentUserId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                      const Text('My Coins', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${AppData.userCoins} 🪙', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
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
                      const Text('Diamonds', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${AppData.userDiamonds} 💎', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Top-Up Coin Packages', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _buildCoinPackage(context, '10,000 Coins', 10000, 100),
          _buildCoinPackage(context, '50,000 Coins (Popular)', 50000, 450),
          _buildCoinPackage(context, '150,000 Coins (VIP)', 150000, 1200),
        ],
      ),
    );
  }

Widget _buildCoinPackage(BuildContext context, String title, int coins, int birr) {
    return Card(
      color: const Color(0xFF181432),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.monetization_on, color: Colors.amberAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('\$$birr (Payment Gateway)', style: const TextStyle(fontSize: 11, color: Colors.white54)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
          child: const Text('Buy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          onPressed: () => _buyCoins(context, coins, birr),
        ),
      ),
    );
  }
}
