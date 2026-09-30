import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const HalaStyleVoiceApp());
}

class HalaStyleVoiceApp extends StatelessWidget {
  const HalaStyleVoiceApp({Key? key}) : super(key: key);

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

// ----------------------------------------------------
// 1. መረጃዎች እና ግሎባል ዳታ (AppData)
// ----------------------------------------------------
class AppData {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static const String agoraToken = "007eJxTYNBXOc7wZlN/y5052+JTrm76vvWHkNrEeSmyD98wWZnnz2NQYEhLMUqxSDI1MLY0TjKxNE1JTDK2SE0yTU4zMjNPAgrO6NmT1RDIyND/SI2BEQpBfE6Govz83HhDAxMjBgYASXMhyw==";
  static const String currentChannel = "room_1042";

  static int userCoins = 50000;
  static int userDiamonds = 120000;

  static List<Map<String, dynamic>> rooms = [
    {
      'id': 'room_1042',
      'title': '🇪🇹 አዲስ Coin አገኘን እንዳያመልጣችሁ',
      'category': 'FRIENDS',
      'host': 'KEDIR',
      'tag': 'HOT',
      'usersCount': '4.58K',
      'bgGradient': [Color(0xFF1E3C72), Color(0xFF2A5298)],
    },
    {
      'id': 'room_1043',
      'title': '🐟 Fish እና ንብ አሸናፊዎች ሩም',
      'category': 'EMOTION',
      'host': 'Sara Live',
      'tag': 'GAME',
      'usersCount': '3.21K',
      'bgGradient': [Color(0xFF5A189A), Color(0xFF3C096C)],
    },
    {
      'id': 'room_1044',
      'title': '🎵 የሙዚቃ እና የጨዋታ ምሽት',
      'category': 'MUSIC',
      'host': 'Abebe Host',
      'tag': 'LIVE',
      'usersCount': '2.23K',
      'bgGradient': [Color(0xFF7209B7), Color(0xFF4361EE)],
    },
  ];
}

// ----------------------------------------------------
// 2. የስፕላሽ ስክሪን (Splash Screen)
// ----------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationHub()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Icon(Icons.record_voice_over, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hala Voice',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00C853)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Show Me Happy the World',
              style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 3. ዋናው ማውጫ (Main Navigation Hub)
// ----------------------------------------------------
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
      const Center(child: Text('Moment / ፖስቶች ገጽ', style: TextStyle(color: Colors.white))),
      const Center(child: Text('መልዕክቶች (Messages)', style: TextStyle(color: Colors.white))),
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

// ----------------------------------------------------
// 4. የHala ፓርቲ ገጽ (Hala Party Screen)
// ----------------------------------------------------
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
            Text('Follow', style: TextStyle(fontSize: 18, color: Colors.white54, fontWeight: FontWeight.bold)),
            SizedBox(width: 16),
            Text('Party', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // የአገራት ባንዲራዎች
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _countryChip('🌍 All', true),
                  _countryChip('🇪🇹 Ethiopia', false),
                  _countryChip('🇸🇦 Saudi', false),
                  _countryChip('🇵🇭 Philippines', false),
                  _countryChip('🇳🇬 Nigeria', false),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ባነሮች (Banner Cards)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF673AB7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                          Text('URGENT EVENT ALERT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Room Ranking & Rewards!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    const Icon(Icons.card_giftcard, size: 48, color: Colors.amberAccent),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // የክፍሎች ዝርዝር (Voice Rooms List)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('ንቁ የድምፅ ክፍሎች (Active Rooms)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppData.rooms.length,
              itemBuilder: (context, index) {
                final r = AppData.rooms[index];
                return _buildHalaRoomCard(context, r);
              },
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('ክፍል ፍጠር', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveHalaVoiceRoom(
                roomId: AppData.currentChannel,
                title: 'የእኔ የቀጥታ ድምፅ ክፍል',
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _countryChip(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF00E676) : const Color(0xFF1E1A38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildHalaRoomCard(BuildContext context, Map<String, dynamic> r) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveHalaVoiceRoom(
              roomId: r['id'],
              title: r['title'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF181432),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: (r['bgGradient'] as List<Color>)[0],
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 28),

),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF2C2454), borderRadius: BorderRadius.circular(6)),
                        child: Text(r['category'], style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text('Host: ${r['host']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF00E676), size: 18),
                const SizedBox(width: 4),
                Text(r['usersCount'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 5. የቀጥታ 8 ወንበር የድምፅ ክፍል (Hala Live Room)
// ----------------------------------------------------
class LiveHalaVoiceRoom extends StatefulWidget {
  final String roomId;
  final String title;

  const LiveHalaVoiceRoom({Key? key, required this.roomId, required this.title}) : super(key: key);

  @override
  State<LiveHalaVoiceRoom> createState() => _LiveHalaVoiceRoomState();
}

class _LiveHalaVoiceRoomState extends State<LiveHalaVoiceRoom> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMicOn = true;
  final Set<int> _remoteUsers = {};

  @override
  void initState() {
    super.initState();
    _startAgoraVoice();
  }

  Future<void> _startAgoraVoice() async {
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
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUsers.add(remoteUid));
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteUsers.remove(remoteUid));
        },
      ),
    );

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
    await _engine!.joinChannel(
      token: AppData.agoraToken,
      channelId: widget.roomId,
      uid: 0,
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

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,

elevation: 0,
        title: Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isJoined ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isJoined ? '🟢 LIVE' : '⏳ በመገናኘት ላይ...',
              style: TextStyle(color: _isJoined ? Colors.greenAccent : Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // የሆስት ዋና ቦታ
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF00E676),
                  child: const CircleAvatar(
                    radius: 33,
                    backgroundColor: Color(0xFF2A2050),
                    child: Icon(Icons.person, size: 38, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('ዋና አስተናጋጅ (Host)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              ],
            ),
          ),

          // 8 የማይክ ወንበሮች (8 Seat Grid)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, i) {
                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF211A45),
                          child: Icon(Icons.chair_alt, color: Colors.white.withOpacity(0.3), size: 24),
                        ),
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.lock_open, size: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${i + 1}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                );
              },
            ),
          ),

          // የታችኛው መቆጣጠሪያ እና የስጦታ ሳጥን
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF161228),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off, color: _isMicOn ? const Color(0xFF00E676) : Colors.red),
                  onPressed: _toggleMic,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎁 ጽጌረዳ ተላከ!')));
                  },
                  icon: const Icon(Icons.card_giftcard, color: Colors.amberAccent, size: 18),
                  label: const Text('ስጦታ ላክ'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF332766)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 6. የዋሌት እና ፕሮፋይል ገጽ (Me Screen)
// ----------------------------------------------------
class ProfileWalletScreen extends StatelessWidget {
  final VoidCallback onRefresh;
  const ProfileWalletScreen({Key? key, required this.onRefresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('የእኔ መለያ (Profile & Wallet)'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: const [
                CircleAvatar(radius: 40, backgroundColor: Color(0xFF00E676), child: Icon(Icons.person, size: 45, color: Colors.black)),
                SizedBox(height: 10),
                Text('KEDIR UMER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('ID: 1042001', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E1742), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('Coins', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('${AppData.userCoins} 🪙', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E1742), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('Diamonds', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('${AppData.userDiamonds} 💎', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
