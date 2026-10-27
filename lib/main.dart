import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const String agoraAppId = "21091aff01114a66b580ce15b0f1b642";
const String agoraToken = "";
const String channelName = "habesha_vip_room";

// የአባይ ፏፏቴ ምስል ሊንክ
const String abayFallsUrl =
    "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Blue_Nile_Falls_Ethiopia.jpg/1024px-Blue_Nile_Falls_Ethiopia.jpg";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoicePartyApp());
}

class VoicePartyApp extends StatelessWidget {
  const VoicePartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '3D Voice Party',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        primaryColor: const Color(0xFFFFD700),
      ),
      home: const LoginScreen(),
    );
  }
}

// ==================== 1. ገና አፑ ሲከፈት የሚመጣው የመግቢያ ገጽ (LOGIN SCREEN) ====================
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ጀርባው ሙሉ በሙሉ የአባይ ፏፏቴ
          Positioned.fill(
            child: Image.network(
              abayFallsUrl,
              fit: BoxFit.cover,
            ),
          ),
          // ጽሁፎቹ እንዲታዩ የሚያደርግ የጥላ ከለር
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                children: [
                  const Spacer(),
                  const Icon(Icons.graphic_eq, size: 70, color: Color(0xFFFFD700)),
                  const SizedBox(height: 12),
                  const Text(
                    "3D Voice Party",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    "Tis Abay Live Lounge",
                    style: TextStyle(fontSize: 14, color: Color(0xFFFFD700)),
                  ),
                  const Spacer(),

                  // 1. በ Google መግቢያ
                  _loginButton(
                    text: "Continue with Google",
                    icon: Icons.g_mobiledata,
                    bgColor: Colors.white,
                    textColor: Colors.black87,
                    iconColor: Colors.red,
                    onTap: () => _navigateToHome(context),
                  ),
                  const SizedBox(height: 14),

                  // 2. በስልክ መግቢያ
                  _loginButton(
                    text: "Continue with Phone",
                    icon: Icons.phone_android,
                    bgColor: const Color(0xFF23233E),
                    textColor: Colors.white,
                    iconColor: const Color(0xFFFFD700),
                    onTap: () => _navigateToHome(context),
                  ),
                  const SizedBox(height: 14),

                  // 3. በ Facebook መግቢያ
                  _loginButton(
                    text: "Continue with Facebook",
                    icon: Icons.facebook,
                    bgColor: const Color(0xFF1877F2),
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    onTap: () => _navigateToHome(context),
                  ),
                  const SizedBox(height: 20),

const Text(
                    "By continuing, you agree to our Terms & Privacy Policy.",
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginButton({
    required String text,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 4,
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 2. ዋናው ማውጫ (HOME, MESSAGE, ME) ====================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _coins = 1250;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        coins: _coins,
        onCoinUpdate: (newCoins) => setState(() => _coins = newCoins),
      ),
      const MessagesScreen(),
      MeProfileScreen(coins: _coins),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF16162A),
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }
}

// ==================== 3. የፊት ለፊቱ የሆም ገጽ (FOLLOW, PARTY, SEARCH, BOX) ====================
class HomeScreen extends StatefulWidget {
  final int coins;
  final Function(int) onCoinUpdate;

  const HomeScreen({super.key, required this.coins, required this.onCoinUpdate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTopTab = 1; // 0 = Follow, 1 = Party

  final List<Map<String, dynamic>> _rooms = [
    {
      "title": "Abay Falls 3D Lounge 🌊",
      "host": "Kedir Umer",
      "members": 184,
      "color": const Color(0xFF261D45),
    },
    {
      "title": "Dessie VIP Chill 🎧",
      "host": "Amina",
      "members": 92,
      "color": const Color(0xFF1E2D45),
    },
    {
      "title": "Habesha Night Club 🌙",
      "host": "Yonas",
      "members": 320,
      "color": const Color(0xFF381E45),
    },
    {
      "title": "Bole Cafe Chit-Chat ☕",
      "host": "Selam",
      "members": 76,
      "color": const Color(0xFF1E3C38),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // አናት ላይ፦ በግራ (Follow, Party) | በቀኝ (Search, Square Box)

Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // በግራ በኩል፦ Follow እና Party መምረጫ
                GestureDetector(
                  onTap: () => setState(() => _selectedTopTab = 0),
                  child: Text(
                    "Follow",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedTopTab == 0 ? const Color(0xFFFFD700) : Colors.white60,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: () => setState(() => _selectedTopTab = 1),
                  child: Column(
                    children: [
                      Text(
                        "Party",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _selectedTopTab == 1 ? Colors.white : Colors.white60,
                        ),
                      ),
                      if (_selectedTopTab == 1)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 20,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                // በቀኝ በኩል፦ የሰርች ቦታ (Search)
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 26),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Search rooms or users...")),
                    );
                  },
                ),

                // በቀኝ በኩል፦ አራት መአዘን ቦክስ (Square Rank/Menu Box)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF23233E),
                    borderRadius: BorderRadius.circular(8), // አራት ማዕዘን ቅርጽ
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.grid_view_rounded, color: Color(0xFFFFD700), size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rank & Activity Box Opened")),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // የክፍሎች ዝርዝር (Party ወይም Follow ሲመረጥ የሚታይ)
          Expanded(
            child: _selectedTopTab == 0
                ? const Center(
                    child: Text("No followed hosts live right now.", style: TextStyle(color: Colors.white54)),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Banner
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(

image: NetworkImage(abayFallsUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Abay Festival 🎉", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 18)),
                              Text("Join top 3D voice rooms now!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Live Parties 🎧",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // ባለ 2 ረድፍ የክፍሎች ካርድ
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _rooms.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (context, index) {
                          final item = _rooms[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VoicePartyRoomScreen(
                                    roomTitle: item["title"],
                                    initialCoins: widget.coins,
                                    onCoinUpdate: widget.onCoinUpdate,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: item["color"],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,

borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 12),
                                            const SizedBox(width: 4),
                                            Text("${item['members']}", style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.spatial_audio, color: Color(0xFFFFD700), size: 16),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    item["title"],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Host: ${item['host']}",
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
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

// ==================== 4. የድምፅ ክፍሉ (VOICE PARTY ROOM) ====================
class VoicePartyRoomScreen extends StatefulWidget {
  final String roomTitle;
  final int initialCoins;
  final Function(int) onCoinUpdate;

  const VoicePartyRoomScreen({
    super.key,
    required this.roomTitle,
    required this.initialCoins,
    required this.onCoinUpdate,
  });

  @override
  State<VoicePartyRoomScreen> createState() => _VoicePartyRoomScreenState();
}

class _VoicePartyRoomScreenState extends State<VoicePartyRoomScreen> {
  late int _currentCoins;
  bool _isMicMuted = false;
  int? _mySeatIndex;
  final List<String?> _seats = List.filled(8, null);
  final List<String> _chatMessages = ["🎧 Tis Abay Live Room Active."];
  final TextEditingController _msgController = TextEditingController();

  RtcEngine? _engine;
  bool _isEngineReady = false;

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.initialCoins;
    _initVoiceEngine();
  }

  Future<void> _initVoiceEngine() async {
    await [Permission.microphone].request();

    if (agoraAppId.length > 5) {
      try {
        _engine = createAgoraRtcEngine();
        await _engine!.initialize(const RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
              setState(() {
                _chatMessages.add("Connected to Voice Channel.");
              });
            },
          ),
        );

        await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
        await _engine!.enableAudio();
        await _engine!.enableSpatialAudio(true);
        await _engine!.joinChannel(
          token: agoraToken,
          channelId: channelName,
          uid: 0,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleAudience,
            autoSubscribeAudio: true,
          ),
        );

        setState(() {
          _isEngineReady = true;
        });
      } catch (e) {
        debugPrint("Voice Engine Error: $e");
      }
    }
  }

Future<void> _handleSeatTap(int index) async {
    setState(() {
      if (_seats[index] == null) {
        if (_mySeatIndex != null) _seats[_mySeatIndex!] = null;
        _seats[index] = "Kedir (Me)";
        _mySeatIndex = index;
        _updateBroadcasterRole(true);
      } else if (_mySeatIndex == index) {
        _seats[index] = null;
        _mySeatIndex = null;
        _updateBroadcasterRole(false);
      }
    });
  }

  Future<void> _updateBroadcasterRole(bool isSpeaker) async {
    if (_engine != null && _isEngineReady) {
      if (isSpeaker) {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await _engine!.muteLocalAudioStream(_isMicMuted);
      } else {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
      }
    }
  }

  Future<void> _toggleMic() async {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    if (_engine != null && _isEngineReady && _mySeatIndex != null) {
      await _engine!.muteLocalAudioStream(_isMicMuted);
    }
  }

  void _sendGift(String giftName, int cost) {
    if (_currentCoins >= cost) {
      setState(() {
        _currentCoins -= cost;
        _chatMessages.add("🎁 Kedir sent a $giftName!");
      });
      widget.onCoinUpdate(_currentCoins);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins!")),
      );
    }
  }

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Send 3D Gift", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _giftItem("Rose", "🌹", 10),
                _giftItem("Crown", "👑", 100),
                _giftItem("Sports Car", "🏎️", 500),
                _giftItem("Spaceship", "🚀", 1000),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _giftItem(String name, String icon, int cost) {
    return GestureDetector(
      onTap: () => _sendGift(name, cost),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text("$cost 🪙", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.roomTitle, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),

),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(abayFallsUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0x77000000), BlendMode.darken),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final isTaken = _seats[index] != null;
                  return GestureDetector(
                    onTap: () => _handleSeatTap(index),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isTaken ? const Color(0xFFFFD700) : const Color(0x8A000000),
                          child: Icon(
                            isTaken ? Icons.mic : Icons.add,
                            color: isTaken ? Colors.black : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTaken ? _seats[index]! : "Seat ${index + 1}",
                          style: TextStyle(
                            color: isTaken ? const Color(0xFFFFD700) : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            Container(
              height: 140,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x8A000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _chatMessages[index],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.black,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic,
                        color: _isMicMuted ? Colors.red : Colors.greenAccent),
                    onPressed: _toggleMic,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),

),
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: "Say something...",
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() => _chatMessages.add("Kedir: $val"));
                            _msgController.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFD700)),
                    onPressed: _openGiftSheet,
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

// ==================== 5. የሜሴጅ ገጽ (MESSAGES) ====================
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Messages",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFFFD700),
                    child: Icon(Icons.notifications, color: Colors.black),
                  ),
                  title: Text("System Notice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("Welcome to 3D Voice Party App!", style: TextStyle(color: Colors.white54)),
                  trailing: Text("Just now", style: TextStyle(color: Colors.white38, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 6. የፕሮፋይል ገጽ (ME) ====================
class MeProfileScreen extends StatelessWidget {
  final int coins;
  const MeProfileScreen({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFFFD700),
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
            const SizedBox(height: 12),
            const Text("Kedir Umer", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("ID: 9845210", style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B38),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol("Coins", "$coins 🪙"),
                  _statCol("Level", "Lv. 15"),
                  _statCol("Followers", "340"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _statCol(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
